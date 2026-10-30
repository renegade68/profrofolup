clear all
set more off
capture log close
log using "analysis/results/enterprise_activity_technology_strategy_dea_operating_vrs_joint_trim.log", text replace
import delimited using "data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv", ///
    varnames(1) encoding(utf8) clear
destring year industry_mid_num ln_value_added ln_capital ln_employees, replace force
keep if !missing(ln_value_added,ln_capital,ln_employees)
gen double output=exp(ln_value_added)
gen double capital=exp(ln_capital)
gen double employees=exp(ln_employees)
foreach v in output capital employees {
    bysort industry_mid_num year: egen double `v'_p1=pctile(`v'), p(1)
    bysort industry_mid_num year: egen double `v'_p99=pctile(`v'), p(99)
}
gen byte dea_sample=inrange(output,output_p1,output_p99) & ///
    inrange(capital,capital_p1,capital_p99) & inrange(employees,employees_p1,employees_p99)
teradial output = capital employees if dea_sample, rts(vrs) base(output) ///
    tename(dea_score) noprint
keep firm_id year technology_strategy industry_mid_num dea_sample dea_score
export delimited using "analysis/results/enterprise_activity_technology_strategy_dea_operating_vrs_joint_trim_scores.csv", replace
log close
