version 16.1
clear all
set more off
local out "results/capital_price"
log using "`out'/export_capital.log", text replace
import delimited "`out'/export_prices.csv", clear varnames(1) encoding(utf8)
tempfile ex kp
save `ex'
import delimited "`out'/capital_prices.csv", clear varnames(1) encoding(utf8)
save `kp'
import delimited "data/processed/enterprise_activity_dynamic_panel_2017_2024.csv", clear varnames(1) encoding(utf8)
merge m:1 year using `kp', keep(master match) nogen
merge m:1 industry_mid_num year using `ex', keep(master match) nogen
encode firm_id, gen(fid)
xtset fid year
gen lag_industry=L.industry_mid_num
gen double capital0=ln_capital
gen double capital1=ln_capital+ln(capital_original/capital_candidate)
gen double exports0=ln(exp(ln_exports_plus1)-1) if ln_exports_plus1>0
gen double exports1=exports0+ln(output_original/export_price)
gen double growth0=D.exports0
gen double growth1=D.exports1
postfile P int end_year byte export_mode capital_mode controls str12 technology str12 outcome str8 exposure double coefficient se p N firms using "`out'/export_capital.dta", replace
foreach endyear in 2023 2024 {
 foreach tech in ai robot combined {
  local tr ai_or_robot_active
  if "`tech'"=="ai" local tr ai_active
  if "`tech'"=="robot" local tr robot_active
  capture drop eligible
  gen eligible=inrange(year,2017,`endyear') & !missing(exports0,exports1,growth0,growth1,`tr',L.`tr',L2.`tr',L.capital0,L.capital1,L.ln_employees,industry_mid_num,lag_industry)
  local expectedN=.
  foreach ct in 1 2 {
   local extra "i.industry_mid_num"
   if `ct'==2 local extra "i.year#i.industry_mid_num i.year#i.lag_industry"
   foreach km in 0 1 {
    foreach em in 0 1 {
     foreach dep in exports growth {
      quietly xtreg `dep'`em' `tr' L.`tr' L2.`tr' L.capital`km' L.ln_employees i.year `extra' if eligible, fe vce(cluster fid)
      if missing(`expectedN') local expectedN=e(N)
      assert e(N)==`expectedN'
      foreach lag in t t1 t2 {
       local v `tr'
       if "`lag'"=="t1" local v L.`tr'
       if "`lag'"=="t2" local v L2.`tr'
       post P (`endyear') (`em') (`km') (`ct') ("`tech'") ("`dep'") ("`lag'") (_b[`v']) (_se[`v']) (2*ttail(e(df_r),abs(_b[`v']/_se[`v']))) (e(N)) (e(N_g))
      }
     }
    }
   }
  }
 }
}
postclose P
use "`out'/export_capital.dta", clear
export delimited "`out'/export_capital.csv", replace
log close
* Return to driver.
