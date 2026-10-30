version 16.1
tempfile flags
use "$MIG/data/processed/selected.dta", clear
keep if inrange(year,2017,2024) & industry_large=="C" & firm_id!=""
merge 1:1 source_zip_id year source_row using "$MIG/data/processed/raw_technology.dta", keep(master match) assert(match using) nogen
local techs iot cloud bigdata mobile ai blockchain 3dp robot arvr
local vars
foreach k of local techs {
    gen byte tech_`k'=.
    replace tech_`k'=0 if raw_`k'_use==2 | raw_`k'_stage==1 | inlist(fourth_industry_use,1,2)
    replace tech_`k'=1 if raw_`k'_use==1 | (raw_`k'_stage>1 & raw_`k'_stage<.)
    local vars `vars' tech_`k'
}
egen byte nmissing=rowmiss(`vars')
drop if nmissing>0
isid firm_id year
keep firm_id year `vars'
save `flags'
use "$MIG/data/processed/dynamic.dta", clear
merge 1:1 firm_id year using `flags', assert(match) nogen
egen byte technology_count=rowtotal(`vars')
gen str80 technology_combination=""
foreach k of local techs {
    replace technology_combination=technology_combination+cond(technology_combination=="","","+")+"`k'" if tech_`k'==1
}
replace technology_combination="none" if technology_count==0
gen byte digital=tech_iot|tech_cloud|tech_bigdata|tech_mobile|tech_blockchain|tech_arvr
gen byte physical=tech_robot|tech_3dp
gen str24 technology_strategy="none"
replace technology_strategy="other_no_ai" if technology_count>0 & tech_ai==0
replace technology_strategy="ai_only" if tech_ai==1 & technology_count==1
replace technology_strategy="ai_digital_bundle" if tech_ai==1 & digital & !physical
replace technology_strategy="ai_physical_bundle" if tech_ai==1 & !digital & physical
replace technology_strategy="ai_cross_bundle" if tech_ai==1 & digital & physical
gen byte ai_with_any_complement=tech_ai & technology_count>=2
gen byte ai_with_digital_complement=tech_ai & digital
gen byte ai_with_physical_complement=tech_ai & physical
gen byte dea_complete=!missing(ln_value_added,ln_capital,ln_employees)
bysort firm_id (year): gen str24 strategy_lag=technology_strategy[_n-1] if _n>1 & year[_n-1]==year-1
by firm_id: gen byte strategy_continues=(strategy_lag==technology_strategy) if strategy_lag!=""
drop digital physical
assert _N==49780
save "$MIG/data/processed/strategy.dta", replace
export delimited using "$MIG/data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv", replace
preserve
contract year technology_strategy dea_complete, freq(firm_years)
rename technology_strategy strategy
sort year strategy dea_complete
export delimited using "$MIG/results/enterprise_activity_technology_strategy_sample_audit.csv", replace
restore
preserve
keep if strategy_lag!=""
contract strategy_lag technology_strategy, freq(transitions)
rename technology_strategy strategy_current
sort strategy_lag strategy_current
export delimited using "$MIG/results/enterprise_activity_technology_strategy_transitions.csv", replace
restore
