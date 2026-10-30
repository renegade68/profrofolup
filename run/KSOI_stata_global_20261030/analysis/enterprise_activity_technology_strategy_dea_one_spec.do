clear all
set more off
args specification
if "`specification'" == "" local specification "no_trim"
capture log close
log using "analysis/results/enterprise_activity_technology_strategy_dea_`specification'.log", text replace

import delimited using "data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv", ///
    varnames(1) encoding(utf8) clear
destring year industry_mid_num ln_value_added ln_capital ln_employees dea_complete, replace force
keep if dea_complete == 1
gen double value_added = exp(ln_value_added)
gen double capital = exp(ln_capital)
gen double employees = exp(ln_employees)

gen byte dea_sample = 1
if "`specification'" == "global_trim" {
    quietly summarize value_added, detail
    replace dea_sample = inrange(value_added,r(p1),r(p99))
}
if "`specification'" == "industry_year_trim" {
    bysort industry_mid_num year: egen double va_p1 = pctile(value_added), p(1)
    bysort industry_mid_num year: egen double va_p99 = pctile(value_added), p(99)
    replace dea_sample = inrange(value_added,va_p1,va_p99)
}

teradial value_added = capital employees if dea_sample, ///
    rts(vrs) base(output) tename(dea_score) noprint
keep firm_id year technology_strategy dea_sample dea_score
export delimited using "analysis/results/enterprise_activity_technology_strategy_dea_`specification'_scores.csv", replace
log close
