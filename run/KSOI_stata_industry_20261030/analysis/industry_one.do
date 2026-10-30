clear all
set more off
args industry
capture log close
log using "analysis/results/industry_dea_`industry'.log", text replace
import delimited using "data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv", ///
    varnames(1) encoding(utf8) clear
destring year industry_mid_num ln_value_added ln_capital ln_employees, replace force
keep if industry_mid_num==`industry' & !missing(ln_value_added,ln_capital,ln_employees)
gen double output=exp(ln_value_added)
gen double capital=exp(ln_capital)
gen double employees=exp(ln_employees)
bysort year: egen double output_p1=pctile(output), p(1)
bysort year: egen double output_p99=pctile(output), p(99)
gen byte dea_sample=inrange(output,output_p1,output_p99)
count if dea_sample
if r(N)<100 exit 2001
teradial output = capital employees if dea_sample, rts(vrs) base(output) ///
    tename(industry_dea_score) noprint
keep firm_id year industry_mid_num technology_strategy dea_sample industry_dea_score
export delimited using "analysis/results/industry_dea_`industry'_scores.csv", replace
log close
