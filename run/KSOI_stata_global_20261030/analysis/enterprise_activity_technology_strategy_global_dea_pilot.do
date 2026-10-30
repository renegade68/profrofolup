clear all
set more off
capture log close
log using "analysis/results/enterprise_activity_technology_strategy_global_dea_pilot.log", text replace

import delimited using "data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv", ///
    varnames(1) encoding(utf8) clear
destring year ln_value_added ln_capital ln_employees dea_complete, replace force
encode firm_id, gen(fid)
encode technology_strategy, gen(strategy6)

keep if dea_complete == 1
gen double value_added = exp(ln_value_added)
gen double capital = exp(ln_capital)
gen double employees = exp(ln_employees)

* Transparent first-pass outlier rule; super-efficiency screening follows later.
quietly summarize value_added, detail
local p1 = r(p1)
local p99 = r(p99)
gen byte dea_sample = value_added >= `p1' & value_added <= `p99' & ///
    capital > 0 & employees > 0

teradial value_added = capital employees if dea_sample, ///
    rts(vrs) base(output) tename(dea_output_vrs) noprint

preserve
keep firm_id year technology_strategy dea_output_vrs dea_sample
export delimited using "analysis/results/enterprise_activity_technology_strategy_global_dea_scores.csv", replace
restore

collapse (count) observations=dea_output_vrs ///
    (mean) mean_inefficiency=dea_output_vrs ///
    (p50) median_inefficiency=dea_output_vrs ///
    (p25) p25_inefficiency=dea_output_vrs ///
    (p75) p75_inefficiency=dea_output_vrs, by(technology_strategy)
export delimited using "analysis/results/enterprise_activity_technology_strategy_global_dea_summary.csv", replace
list, noobs abbreviate(24)
log close
