clear all
set more off
args strategy horizon reps
if "`reps'"=="" local reps 200
capture log close
log using "analysis/results/strategy_frontier_bootstrap_`strategy'_h`horizon'.log", text replace
import delimited using "data/processed/enterprise_activity_strategy_frontier_stack_t2.csv", ///
    varnames(1) encoding(utf8) clear
keep if baseline_strategy=="`strategy'" & horizon==`horizon'
count
if r(N)<30 exit 2001
set seed 20260801
teradialbc value_added = capital employees, rts(vrs) base(output) subsampling ///
    kappa(.5) reps(`reps') tename(within_score) tebc(within_score_bc) ///
    telower(within_ci_low) teupper(within_ci_high) noprint nodots
keep event_id firm_id origin_year horizon baseline_strategy global_score ///
    within_score within_score_bc within_ci_low within_ci_high
export delimited using "analysis/results/strategy_frontier_bootstrap_`strategy'_h`horizon'_scores.csv", replace
log close
