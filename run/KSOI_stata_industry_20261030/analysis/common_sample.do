version 16.1
clear all
set more off
local out "analysis/results"
capture log close
log using "`out'/common_sample.log", text replace
import delimited "analysis/results/enterprise_activity_technology_strategy_dea_no_trim_scores.csv", clear varnames(1) encoding(utf8)
keep firm_id year dea_score
tempfile scores
save `scores'
import delimited "data/processed/enterprise_activity_dynamic_panel_2017_2024.csv", clear varnames(1) encoding(utf8)
merge 1:1 firm_id year using `scores', keep(master match) nogen
encode firm_id, gen(fid)
xtset fid year
gen double sales_growth=D.ln_revenue
gen double lp_change=D.ln_labor_productivity
gen double eff_level=-ln(dea_score)
gen double eff_change=D.eff_level
tempname res
postfile `res' int end_year byte industry_controls str12 technology str24 outcome str8 exposure double coefficient se p N firms using "`out'/common_sample.dta", replace
foreach endyear in 2023 2024 {
 foreach tech in ai robot combined {
  local tr ai_or_robot_active
  if "`tech'"=="ai" local tr ai_active
  if "`tech'"=="robot" local tr robot_active
  capture drop eligible
  gen byte eligible=inrange(year,2017,`endyear') & !missing(sales_growth,ln_labor_productivity,lp_change,eff_level,eff_change,`tr',L.`tr',L2.`tr',L.ln_capital,L.ln_employees,industry_mid_num)
  foreach ind in 0 1 {
   local extra ""
   if `ind'==1 local extra "i.industry_mid_num"
   local expectedN=.
   foreach dep in sales_growth ln_labor_productivity lp_change eff_level eff_change {
    quietly xtreg `dep' `tr' L.`tr' L2.`tr' L.ln_capital L.ln_employees i.year `extra' if eligible, fe vce(cluster fid)
    if missing(`expectedN') local expectedN=e(N)
    assert e(N)==`expectedN'
    foreach lag in t t1 t2 {
     local v `tr'
     if "`lag'"=="t1" local v L.`tr'
     if "`lag'"=="t2" local v L2.`tr'
     post `res' (`endyear') (`ind') ("`tech'") ("`dep'") ("`lag'") (_b[`v']) (_se[`v']) (2*ttail(e(df_r),abs(_b[`v']/_se[`v']))) (e(N)) (e(N_g))
    }
   }
  }
 }
}
postclose `res'
use "`out'/common_sample.dta", clear
export delimited "`out'/common_sample.csv", replace
log close
* Return to driver.
