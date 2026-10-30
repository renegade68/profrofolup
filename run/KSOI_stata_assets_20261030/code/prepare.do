version 16.1
clear all
set more off
set type double
tempfile assets ref
use results/audit/assets.dta, clear
keep firm_id year relative_gap large_gap
gen byte diagnosed=1
gen byte gap_known=!missing(relative_gap)
drop relative_gap
save `assets'
import delimited data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv, clear varnames(1) encoding(UTF-8) case(preserve) asdouble
drop if missing(ln_capital,ln_employees,ln_value_added)
gen double capital=exp(ln_capital)
gen double employees=exp(ln_employees)
gen double output=exp(ln_value_added)
assert min(capital,employees,output)>0
merge 1:1 firm_id year using `assets', keep(master match) nogen
foreach v in diagnosed gap_known large_gap {
    replace `v'=0 if missing(`v')
}
keep firm_id year capital employees output diagnosed gap_known large_gap
order firm_id year capital employees output diagnosed gap_known large_gap
sort firm_id year
assert _N==48531
save `ref'
export delimited results/frontiers/reference.csv, replace
import delimited data/processed/baseline_events.csv, clear varnames(1) encoding(UTF-8) case(preserve) asdouble
keep event_id group origin_year firm_id
expand 2, gen(copy)
gen byte horizon=copy*3
gen int year=origin_year+horizon
drop copy
merge m:1 firm_id year using `ref', keep(master match) assert(match using) nogen
order event_id group origin_year horizon firm_id year capital employees output diagnosed gap_known large_gap
sort group event_id horizon
assert _N==26836
export delimited results/frontiers/events.csv, replace
display "ASSET_FRONTIER_INPUT_COMPLETE"
