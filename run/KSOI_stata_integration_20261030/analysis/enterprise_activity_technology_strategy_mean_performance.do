clear all
set more off
capture log close
log using "analysis/results/enterprise_activity_technology_strategy_mean_performance.log", text replace

import delimited using "data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv", ///
    varnames(1) encoding(utf8) clear

destring year industry_mid_num ln_value_added ln_capital ln_employees ///
    ln_revenue ln_labor_productivity technology_count, replace force
encode firm_id, gen(fid)
encode technology_strategy, gen(strategy6)
xtset fid year

* Transparent labels and a fixed none baseline.
label list strategy6
summarize strategy6 if technology_strategy == "none", meanonly
local none = r(min)
quietly summarize strategy6 if technology_strategy == "ai_only", meanonly
local ai_only = r(min)
quietly summarize strategy6 if technology_strategy == "ai_digital_bundle", meanonly
local ai_digital = r(min)
quietly summarize strategy6 if technology_strategy == "ai_physical_bundle", meanonly
local ai_physical = r(min)
quietly summarize strategy6 if technology_strategy == "ai_cross_bundle", meanonly
local ai_cross = r(min)

tempname results
postfile `results' str28 specification str32 strategy double coefficient std_error p_value ///
    observations firms using "analysis/results/enterprise_activity_technology_strategy_mean_performance.dta", replace

* Production-function association: value added conditional on capital and labor.
quietly xtreg ln_value_added ib`none'.strategy6 ln_capital ln_employees ///
    i.year#i.industry_mid_num, fe vce(cluster fid)
local N = e(N)
local Ng = e(N_g)
levelsof strategy6 if e(sample) & strategy6 != `none', local(levels)
foreach j of local levels {
    local label : label strategy6 `j'
    local b = _b[`j'.strategy6]
    local se = _se[`j'.strategy6]
    local p = 2*ttail(e(df_r),abs(`b'/`se'))
    post `results' ("FE value added") ("`label'") (`b') (`se') (`p') (`N') (`Ng')
}
foreach pair in "`ai_digital' ai_digital_minus_only" "`ai_physical' ai_physical_minus_only" "`ai_cross' ai_cross_minus_only" {
    gettoken j label : pair
    quietly lincom `j'.strategy6 - `ai_only'.strategy6
    post `results' ("FE VA direct contrast") ("`label'") (r(estimate)) (r(se)) (r(p)) (`N') (`Ng')
}

* Labor-productivity association, reported as a secondary descriptive model.
quietly xtreg ln_labor_productivity ib`none'.strategy6 ln_capital ///
    i.year#i.industry_mid_num, fe vce(cluster fid)
local N = e(N)
local Ng = e(N_g)
levelsof strategy6 if e(sample) & strategy6 != `none', local(levels)
foreach j of local levels {
    local label : label strategy6 `j'
    local b = _b[`j'.strategy6]
    local se = _se[`j'.strategy6]
    local p = 2*ttail(e(df_r),abs(`b'/`se'))
    post `results' ("FE labor productivity") ("`label'") (`b') (`se') (`p') (`N') (`Ng')
}
foreach pair in "`ai_digital' ai_digital_minus_only" "`ai_physical' ai_physical_minus_only" "`ai_cross' ai_cross_minus_only" {
    gettoken j label : pair
    quietly lincom `j'.strategy6 - `ai_only'.strategy6
    post `results' ("FE LP direct contrast") ("`label'") (r(estimate)) (r(se)) (r(p)) (`N') (`Ng')
}

postclose `results'
use "analysis/results/enterprise_activity_technology_strategy_mean_performance.dta", clear
export delimited using "analysis/results/enterprise_activity_technology_strategy_mean_performance.csv", replace
list, noobs abbreviate(24)
log close
