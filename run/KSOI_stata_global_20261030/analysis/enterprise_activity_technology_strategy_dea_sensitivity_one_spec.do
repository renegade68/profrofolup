clear all
set more off
args label rts outcome
if "`label'"=="" local label "operating_vrs"
if "`rts'"=="" local rts "vrs"
if "`outcome'"=="" local outcome "ln_value_added"
capture log close
log using "analysis/results/enterprise_activity_technology_strategy_dea_`label'.log", text replace

import delimited using "data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv", ///
    varnames(1) encoding(utf8) clear
destring year industry_mid_num `outcome' ln_capital ln_employees, replace force
keep if !missing(`outcome',ln_capital,ln_employees)
gen double output=exp(`outcome')
gen double capital=exp(ln_capital)
gen double employees=exp(ln_employees)
bysort industry_mid_num year: egen double output_p1=pctile(output), p(1)
bysort industry_mid_num year: egen double output_p99=pctile(output), p(99)
gen byte dea_sample=inrange(output,output_p1,output_p99)

teradial output = capital employees if dea_sample, rts(`rts') base(output) ///
    tename(dea_score) noprint
keep firm_id year technology_strategy industry_mid_num dea_sample dea_score
export delimited using "analysis/results/enterprise_activity_technology_strategy_dea_`label'_scores.csv", replace
log close
