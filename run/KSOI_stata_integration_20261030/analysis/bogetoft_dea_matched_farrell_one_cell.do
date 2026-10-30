version 16.1
clear all
set more off

* Usage: do analysis/bogetoft_dea_matched_farrell_one_cell.do comparison role horizon reps
args comparison role horizon reps
if !inlist("`comparison'", "ai_pure", "ai_combined") | ///
   !inlist("`role'", "treatment", "control") | "`horizon'" == "" {
    display as error "Required: ai_pure|ai_combined treatment|control 0|3 [reps]"
    exit 198
}
if "`reps'" == "" local reps 1000

local project "`c(pwd)'"
adopath ++ "`project'/analysis/vendor/deas"
quietly run "analysis/bogetoft_dea_bootstrap.ado"
capture mkdir "analysis/results/bogetoft_rebuild"
capture log close
local stem "matched_`comparison'_`role'_h`horizon'"
log using "analysis/results/bogetoft_rebuild/`stem'.log", text replace

import delimited using ///
    "data/processed/enterprise_activity_bogetoft_matched_`comparison'_t3_stack.csv", ///
    varnames(1) encoding(utf8) clear
keep if role == "`role'" & horizon == real("`horizon'")
isid event_id
assert value_added > 0 & capital > 0 & employees > 0
count
local cell_n = r(N)
if `cell_n' < 30 exit 2001

sort event_id
bogetoft_dea_bootstrap capital employees = value_added, dmu(event_id) ///
    rts(vrs) orientation(output) reps(`reps') seed(20260824) generate(farrell)

assert farrell >= 1 - 1e-7
count if missing(farrell, farrell_bc, farrell_se, farrell_lo, farrell_hi)
local missing_inference = r(N)
count if farrell_bc < 1 - 1e-7
local invalid_bc = r(N)
count if farrell_lo < 1 - 1e-7 | farrell_hi < farrell_lo
local invalid_ci = r(N)

gen double te_raw = 1 / farrell
gen double te_bc = 1 / farrell_bc if farrell_bc >= 1 - 1e-7
gen str28 estimator = "farrell_smooth_bootstrap"
gen int bootstrap_reps = `reps'
gen int cell_n = `cell_n'
gen int missing_inference_cell = `missing_inference'
gen int invalid_bc_cell = `invalid_bc'
gen int invalid_ci_cell = `invalid_ci'

order event_id firm_id origin_year comparison role original_group horizon ///
    estimator bootstrap_reps cell_n match_distance value_added capital employees ///
    farrell farrell_bc farrell_se farrell_lo farrell_hi te_raw te_bc
export delimited using "analysis/results/bogetoft_rebuild/`stem'_scores.csv", replace

display as text "Cell size: " as result `cell_n'
display as text "Missing / invalid BC / invalid CI: " ///
    as result `missing_inference' " / " `invalid_bc' " / " `invalid_ci'
log close
* Return to integration driver; original batch exit removed.
