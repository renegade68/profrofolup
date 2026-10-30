version 16.1
tempfile scores spells summary
import delimited "$MIG/analysis/results/enterprise_activity_technology_strategy_global_dea_scores_robustness.csv", clear varnames(1) asdouble stringcols(1) encoding(UTF-8)
keep firm_id year dea_global_trim
drop if missing(dea_global_trim)
isid firm_id year
save `scores'
use "$MIG/data/processed/dynamic.dta", clear
merge 1:1 firm_id year using `scores', keep(master match) nogen
egen long pid=group(firm_id)
xtset pid year
gen double baseline_score=L.dea_global_trim
gen double score0=dea_global_trim
gen byte last_observed_h=0 if !missing(score0)
forvalues h=1/6 {
    gen double score`h'=F`h'.dea_global_trim
    replace last_observed_h=`h' if last_observed_h==`h'-1 & !missing(score`h')
}
keep if ai_first_entry==1 & baseline_score>1 & baseline_score<. & !missing(score0)
assert _N==484
isid firm_id
rename year entry_year
gen str24 entry_strategy=""
* Original KM builder reads dynamic panel: it has no strategy field.
expand 3
bysort firm_id: gen double threshold=cond(_n==1,.25,cond(_n==2,.5,1))
gen double target_score=exp((1-threshold)*ln(baseline_score))
gen int duration=.
forvalues h=0/6 {
    replace duration=`h' if missing(duration) & `h'<=last_observed_h & score`h'<=target_score
}
gen byte event=!missing(duration)
replace duration=last_observed_h if missing(duration)
rename score0 entry_score
keep firm_id entry_year entry_strategy threshold baseline_score target_score duration event last_observed_h entry_score
order firm_id entry_year entry_strategy threshold baseline_score target_score duration event last_observed_h entry_score
sort firm_id entry_year threshold
save `spells'
save "$MIG/data/processed/km_spells.dta", replace
export delimited using "$MIG/results/enterprise_activity_ai_frontier_gap_duration_spells.csv", replace
gen double t=duration+1
stset t, failure(event==1)
sts generate survival=s, by(threshold)
postfile K double gap_closed_fraction int horizon_years eligible_events at_risk new_catchups double km_cumulative_probability using `summary', replace
foreach q in .25 .5 1 {
    count if threshold==`q'
    local n=r(N)
    forvalues h=0/6 {
        count if threshold==`q' & duration>=`h'
        local risk=r(N)
        count if threshold==`q' & duration==`h' & event==1
        local fail=r(N)
        summarize survival if threshold==`q' & duration<=`h', meanonly
        local prob=cond(r(N)==0,0,1-r(min))
        post K (`q') (`h') (`n') (`risk') (`fail') (`prob')
    }
}
postclose K
use `summary', clear
save "$MIG/data/processed/km_points.dta", replace
export delimited using "$MIG/results/km_points.csv", replace
foreach label in 25 50 100 {
    capture erase "$MIG/validation/shared_weights_`label'.csv"
}
local py : environment PYTHON_BIN
if `"`py'"'=="" local py python3
shell "`py'" "../../tools/prepare_km_draws.py"
confirm file "$MIG/validation/shared_weights_100.csv"
do "$MIG/code/06_km_bootstrap.do"
