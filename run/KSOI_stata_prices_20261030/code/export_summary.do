version 16.1
clear all
set more off
set type double
import delimited "results/capital_price/export_capital.csv", clear varnames(1) encoding(UTF-8) case(preserve) asdouble
isid end_year export_mode capital_mode controls technology outcome exposure
assert _N==288
tempfile raw capital0 export0
save `raw'
preserve
keep if capital_mode==0
keep end_year export_mode controls technology outcome exposure coefficient N
rename coefficient base_cap_b
rename N base_cap_N
save `capital0'
restore
merge m:1 end_year export_mode controls technology outcome exposure using `capital0', assert(match) nogen
assert N==base_cap_N
gen double cap_difference=abs(coefficient-base_cap_b)
assert cap_difference<1e-10
quietly summarize cap_difference, meanonly
scalar max_cap_difference=r(max)
use `raw', clear
preserve
keep if export_mode==0
keep end_year capital_mode controls technology outcome exposure coefficient p N
rename coefficient before_b
rename p before_p
rename N before_N
save `export0'
restore
merge m:1 end_year capital_mode controls technology outcome exposure using `export0', assert(match) nogen
assert N==before_N
gen double exp_difference=abs(coefficient-before_b) if controls==2
assert exp_difference<1e-10 if controls==2
quietly summarize exp_difference, meanonly
scalar max_export_difference=r(max)
keep if export_mode==1 & capital_mode==0
rename coefficient after_b
rename p after_p
keep end_year controls technology outcome exposure N before_b after_b before_p after_p
order end_year controls technology outcome exposure N before_b after_b before_p after_p
sort end_year controls technology outcome exposure
assert _N==72
export delimited "results/capital_price/export_price_comparison.csv", replace
clear
set obs 1
gen double max_cap_difference=scalar(max_cap_difference)
gen double max_export_difference=scalar(max_export_difference)
export delimited "validation/regression_invariance.csv", replace
display "EXPORT_SUMMARY_COMPLETE"
