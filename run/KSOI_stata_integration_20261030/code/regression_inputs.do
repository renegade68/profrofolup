version 16.1
clear all
set more off
tempfile panel scores first
import delimited "data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv", clear varnames(1) encoding(UTF-8) asdouble stringcols(1)
isid firm_id year
save `panel'
preserve
keep if tech_ai==1
collapse (min) first_ai=year, by(firm_id)
save `first'
restore
import delimited "data/processed/enterprise_activity_ai_entry_stacked_did.csv", clear varnames(1) encoding(UTF-8) asdouble stringcols(2 3)
merge m:1 firm_id using `first', keep(master match) nogen
gen byte audit_past_ai=first_ai<stack-1 & treated==0
drop first_ai
sort stack firm_id year
export delimited using "data/processed/did_history.csv", replace
import delimited "analysis/results/enterprise_activity_technology_strategy_dea_industry_year_trim_scores.csv", clear varnames(1) encoding(UTF-8) asdouble stringcols(1)
keep firm_id year dea_score
drop if missing(dea_score)
isid firm_id year
save `scores'
use `panel', clear
merge 1:1 firm_id year using `scores', keep(master match) nogen
egen long pid=group(firm_id)
xtset pid year
gen byte complete_history=!missing(L.pid,L2.pid,L3.pid,dea_score,L.dea_score,L3.dea_score)
gen byte used_count=0
foreach k in iot cloud bigdata mobile ai blockchain 3dp robot arvr {
    gen byte used_`k'=tech_`k'==1 | L.tech_`k'==1 | L2.tech_`k'==1
    replace used_count=used_count+used_`k'
    replace complete_history=0 if missing(tech_`k',L.tech_`k',L2.tech_`k')
}
gen double dea_t=dea_score
gen double dea_t1=L.dea_score
gen double dea_t3=L3.dea_score
gen double ln_employees_t1=L.ln_employees
gen double capital_intensity_t1=L.ln_capital-L.ln_employees
gen byte bog_active=used_count>0
gen byte bog_pure=used_count==1
gen byte bog_combined=used_count>=2
gen byte bog_ai_window=used_ai
gen byte bog_ai_pure=used_ai & used_count==1
gen byte bog_ai_combined=used_ai & used_count>=2
gen byte current_ai=tech_ai
drop ai_state
gen str16 ai_state="never_recent"
replace ai_state="first_entry" if tech_ai==1 & L.tech_ai==0 & L2.tech_ai==0
replace ai_state="continuation" if tech_ai==1 & L.tech_ai==1
replace ai_state="reentry" if tech_ai==1 & L.tech_ai==0 & L2.tech_ai==1
replace ai_state="exit_or_past" if tech_ai==0 & (L.tech_ai==1 | L2.tech_ai==1)
gen str2 technology_intensity="M4"
replace technology_intensity="M1" if inlist(industry_mid_num,21,26)
replace technology_intensity="M2" if industry_mid_num==20 | inrange(industry_mid_num,27,30)
replace technology_intensity="M3" if industry_mid_num==19 | inrange(industry_mid_num,22,25)
keep if complete_history
keep firm_id year industry_mid_num technology_intensity dea_t dea_t1 dea_t3 ln_employees_t1 capital_intensity_t1 bog_active bog_pure bog_combined bog_ai_window bog_ai_pure bog_ai_combined current_ai ai_state
order firm_id year industry_mid_num technology_intensity dea_t dea_t1 dea_t3 ln_employees_t1 capital_intensity_t1 bog_active bog_pure bog_combined bog_ai_window bog_ai_pure bog_ai_combined current_ai ai_state
sort firm_id year
export delimited using "data/processed/enterprise_activity_bogetoft_model_comparison.csv", replace
