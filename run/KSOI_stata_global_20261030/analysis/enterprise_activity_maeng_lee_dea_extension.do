version 16.1
clear all
set more off
capture log close
log using "analysis/results/enterprise_activity_maeng_lee_dea_extension.log", text replace

tempfile panel scores
import delimited using "data/processed/enterprise_activity_dynamic_panel_2017_2024.csv", varnames(1) encoding(utf8) clear
keep firm_id year ln_capital ln_employees ai_active robot_active ai_or_robot_active
destring year ln_capital ln_employees ai_active robot_active ai_or_robot_active, replace force
save `panel'

import delimited using "analysis/results/enterprise_activity_technology_strategy_dea_industry_year_trim_scores.csv", varnames(1) encoding(utf8) clear
keep firm_id year dea_score
destring year dea_score, replace force
save `scores'

use `panel', clear
merge 1:1 firm_id year using `scores', keep(match) nogen
encode firm_id, gen(fid)
xtset fid year
gen dea_efficiency=-ln(dea_score)
gen dea_efficiency_change=D.dea_efficiency

tempname out
postfile `out' int end_year str12 technology str28 outcome str8 exposure double coefficient std_error p_value observations firms using "analysis/results/enterprise_activity_maeng_lee_dea_extension.dta", replace
foreach endyear in 2023 2024 {
  foreach tech in ai robot combined {
    local treatment ai_or_robot_active
    if "`tech'"=="ai" local treatment ai_active
    if "`tech'"=="robot" local treatment robot_active
    foreach outcome in dea_efficiency dea_efficiency_change {
      quietly xtreg `outcome' `treatment' L.`treatment' L2.`treatment' L.ln_capital L.ln_employees i.year if inrange(year,2017,`endyear'), fe vce(cluster fid)
      foreach lag in t t1 t2 {
        local v `treatment'
        if "`lag'"=="t1" local v L.`treatment'
        if "`lag'"=="t2" local v L2.`treatment'
        post `out' (`endyear') ("`tech'") ("`outcome'") ("`lag'") (_b[`v']) (_se[`v']) (2*ttail(e(df_r),abs(_b[`v']/_se[`v']))) (e(N)) (e(N_g))
      }
    }
  }
}
postclose `out'
use "analysis/results/enterprise_activity_maeng_lee_dea_extension.dta", clear
export delimited using "analysis/results/enterprise_activity_maeng_lee_dea_extension.csv", replace
log close
* Return to driver.
