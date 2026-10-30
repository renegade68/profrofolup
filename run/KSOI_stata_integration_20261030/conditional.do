version 16.1
clear all
set more off
args mode
global CI_SRC "analysis/results"
global CI_OUT "analysis/results"
assert "`mode'"=="fresh"
capture log close _all
log using "logs/conditional_`mode'.log", text replace
do code/conditional.mata
tempfile second shorts longs matched crosswalk idmap cfmap
postfile S str24 strategy int events int firms double raw double point double ci_low double ci_high long reps long seed using `shorts', replace
local j=0
foreach g in ai_only ai_digital_bundle ai_physical_bundle ai_cross_bundle {
    foreach h in 2 0 {
        import delimited "$CI_SRC/strategy_frontier_bootstrap_`g'_h`h'_scores.csv", clear varnames(1) asdouble encoding(UTF-8) stringcols(1 2)
        drop if missing(global_score,within_score,within_score_bc,within_ci_low,within_ci_high)
        keep event_id firm_id within_score within_score_bc
        rename (within_score within_score_bc) (raw`h' bc`h')
        isid event_id
        if `h'==2 save `second', replace
    }
    merge 1:1 event_id using `second', keep(match) nogen
    quietly summarize raw0, meanonly
    local r0=r(sum)
    quietly summarize raw2, meanonly
    local raw=`r0'/r(sum)
    rename (firm_id bc0 bc2) (cluster a0 a1)
    do code/bootstrap_cell.do short_`g'
    post S ("`g'") (ci_events) (ci_clusters) (`raw') (ci_point) (ci_low) (ci_high) (10000) (20261007+`j')
    local ++j
}
postclose S
postfile L str16 group int horizon int events int firms double point double ci_low double ci_high long reps long seed using `longs', replace
foreach g in ai_pure ai_combined {
    foreach h in 3 4 5 {
        foreach t in `h' 0 {
            import delimited "$CI_SRC/bogetoft_rebuild/validated_long_`g'_h`h'_t`t'_scores.csv", clear varnames(1) asdouble encoding(UTF-8) stringcols(1 2)
            keep event_id firm_id farrell_bc
            rename farrell_bc bc`t'
            isid event_id
            if `t'==`h' save `second', replace
        }
        merge 1:1 event_id using `second', assert(match) nogen
        rename (firm_id bc0 bc`h') (cluster a0 a1)
        do code/bootstrap_cell.do long_`g'_`h'
        post L ("`g'") (`h') (ci_events) (ci_clusters) (ci_point) (ci_low) (ci_high) (10000) (20261006+`h')
    }
}
postclose L
postfile M str16 group int pairs int treated_firms int control_firms int components long reps long seed double treatment double treatment_low double treatment_high double control double control_low double control_high double difference double difference_low double difference_high using `matched', replace
foreach g in ai_pure ai_combined {
    import delimited "$CI_SRC/bogetoft_rebuild/match_`g'_crosswalk.csv", clear varnames(1) asdouble stringcols(1 2) encoding(UTF-8)
    gen long source_order=_n
    gen str80 tf=ustrregexra(treated_event_id,"[|][^|]+$","")
    gen str80 cf=ustrregexra(matched_control_event_id,"[|][^|]+$","")
    egen byte tt=tag(tf)
    count if tt
    local nt=r(N)
    egen byte ct=tag(cf)
    count if ct
    local nc=r(N)
    save `crosswalk', replace
    keep tf
    rename tf firm_id
    save `idmap', replace
    use `crosswalk', clear
    keep cf
    rename cf firm_id
    append using `idmap'
    duplicates drop
    sort firm_id
    gen long id=_n
    mata: firmnames=st_sdata(.,"firm_id")
    rename (firm_id id) (cf cfid)
    save `cfmap', replace
    rename (cf cfid) (tf tfid)
    save `idmap', replace
    use `crosswalk', clear
    merge m:1 tf using `idmap', keep(master match) assert(match using) nogen
    merge m:1 cf using `cfmap', keep(master match) assert(match using) nogen
    sort source_order
    gen str80 component=""
    mata: roots=ci_components(st_data(.,"tfid"),st_data(.,"cfid"),rows(firmnames));st_sstore(.,"component",firmnames[roots])
    preserve
    keep treated_event_id matched_control_event_id tf cf component
    export delimited using "$CI_OUT/components_`g'.csv", replace
    restore
    save `crosswalk', replace
    foreach role in treatment control {
        local key treated_event_id
        local prefix t
        if "`role'"=="control" {
            local key matched_control_event_id
            local prefix c
        }
        foreach h in 0 3 {
            import delimited "$CI_SRC/bogetoft_rebuild/matched_`g'_`role'_h`h'_scores.csv", clear varnames(1) asdouble encoding(UTF-8) stringcols(1 2)
            keep event_id farrell_bc
            rename (event_id farrell_bc) (`key' `prefix'`h')
            isid `key'
            save `second', replace
            use `crosswalk', clear
            merge 1:1 `key' using `second', assert(match) nogen
            save `crosswalk', replace
        }
    }
    rename (component t0 t3 c0 c3) (cluster a0 a1 b0 b1)
    do code/bootstrap_cell.do matched_`g'
    post M ("`g'") (ci_events) (`nt') (`nc') (ci_clusters) (10000) (20261006) (ci_point) (ci_low) (ci_high) (ci_control) (ci_control_low) (ci_control_high) (ci_difference) (ci_difference_low) (ci_difference_high)
}
postclose M
foreach name in short long matched {
    if "`name'"=="short" use `shorts', clear
    if "`name'"=="long" use `longs', clear
    if "`name'"=="matched" use `matched', clear
    local suffix firm
    if "`name'"=="matched" local suffix component
    export delimited using "$CI_OUT/`name'_`suffix'_cluster.csv", replace
}
display "CONDITIONAL_COMPLETE"
log close
