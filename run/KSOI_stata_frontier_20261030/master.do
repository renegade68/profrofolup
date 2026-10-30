version 16.1
clear all
set more off
set type double
args reps
if "`reps'"=="" local reps 10
global ROOT `"`c(pwd)'"'
capture log close _all
log using "$ROOT/logs/master_`reps'.log", text replace
do "$ROOT/code/frontier.mata"
do "$ROOT/code/decompose.mata"
tempfile ids endpoints
import delimited "$ROOT/validation/joint_shared_weights.csv", clear varnames(1) stringcols(1) asdouble encoding(UTF-8)
gen long fid=_n
mata: weights=st_data(.,tokens(invtokens("w":+strofreal(1..1000))))
keep firm_id fid
isid firm_id
save `ids'
import delimited "$ROOT/../KSOI_stata_migration_20261030/data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv", clear varnames(1) asdouble encoding(UTF-8) stringcols(1)
drop if missing(ln_capital,ln_employees,ln_value_added)
merge m:1 firm_id using `ids', assert(match) nogen
sort firm_id year
assert _N==48531
mata: ref=exp(st_data(.,("ln_capital","ln_employees","ln_value_added")));fid=st_data(.,"fid")
timer clear
timer on 1
mata: globalf=ks_build(ref); globalscores=ks_score(globalf,ref)
gen double mata_score=.
mata: st_store(.,"mata_score",globalscores)
preserve
keep firm_id year mata_score
export delimited using "$ROOT/results/global_scores.csv", replace
restore
import delimited "$ROOT/../KSOI_stata_migration_20261030/data/processed/enterprise_activity_bogetoft_t3_stack.csv", clear varnames(1) asdouble encoding(UTF-8) stringcols(1 2)
keep if family=="ai"
merge m:1 firm_id using `ids', keep(master match) assert(match using) nogen
gen byte group_id=cond(group=="ai_combined",1,cond(group=="ai_none",2,3))
sort group_id event_id horizon
save `endpoints'
mata: cc=ks_cells(st_data(.,("capital","employees","value_added")),st_data(.,"group_id"),st_data(.,"horizon"),st_data(.,"fid"),st_sdata(.,"event_id"))
mata: es=ks_event_scores(cc,globalf)
keep if horizon==0
sort group_id event_id
foreach v in F0 F3 H0 H3 G0 G3 CU FS TC {
    gen double `v'=.
}
mata: st_store(.,tokens("F0 F3 H0 H3 G0 G3 CU FS TC"),es[,3..11])
keep event_id firm_id origin_year group F0 F3 H0 H3 G0 G3 CU FS TC
order event_id firm_id origin_year group F0 F3 H0 H3 G0 G3 CU FS TC
export delimited using "$ROOT/results/event_decomposition.csv", replace
timer off 1
forvalues g=1/3 {
    import delimited "$ROOT/validation/equal_events_`g'.csv", clear varnames(1) stringcols(_all) encoding(UTF-8)
    mata: assert(all(st_sdata(.,"event_id"):==ks_events(cc,`g')))
    import delimited "$ROOT/validation/equal_shared_indices_`g'.csv", clear varnames(1) asdouble encoding(UTF-8)
    mata: eq`g'=st_data(.,.)
}
timer on 2
mata: jd=ks_joint(ref,fid,cc,weights,`reps')
timer off 2
clear
set obs `=`reps'*3'
foreach v in rep group_id CU FS {
    gen double `v'=.
}
mata: st_store(.,.,jd)
gen str12 group=cond(group_id==1,"ai_combined",cond(group_id==2,"ai_none","ai_pure"))
drop group_id
order rep group CU FS
export delimited using "$ROOT/results/joint_cluster_draws_`reps'.csv", replace
timer on 3
mata: ed=ks_equal(globalf,cc,eq1,eq2,eq3,`reps')
timer off 3
clear
set obs `=`reps'*3'
foreach v in rep group_id m CU FS {
    gen double `v'=.
}
mata: st_store(.,.,ed)
gen str12 group=cond(group_id==1,"ai_combined",cond(group_id==2,"ai_none","ai_pure"))
drop group_id
order rep group m CU FS
export delimited using "$ROOT/results/equal_size_sensitivity_draws_`reps'.csv", replace
clear
set obs 3
foreach v in group_id events firms CU FS reference_change CU_geomean FS_geomean TC_geomean {
    gen double `v'=.
}
mata: st_store(.,.,ks_points(cc,es))
gen str12 group=cond(group_id==1,"ai_combined",cond(group_id==2,"ai_none","ai_pure"))
drop group_id
order group events firms CU FS reference_change CU_geomean FS_geomean TC_geomean
export delimited using "$ROOT/results/point_estimates.csv", replace
foreach v in CU_sensitivity_low CU_sensitivity_high FS_sensitivity_low FS_sensitivity_high {
    gen double `v'=.
}
mata: st_store(.,tokens("CU_sensitivity_low CU_sensitivity_high FS_sensitivity_low FS_sensitivity_high"),ks_intervals(jd))
export delimited using "$ROOT/results/joint_decomposition_summary_`reps'.csv", replace
timer list
display "KSOI_STATA_FRONTIER_COMPLETE_`reps'"
log close
