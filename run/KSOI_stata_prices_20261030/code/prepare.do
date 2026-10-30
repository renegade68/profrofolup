version 16.1
clear all
set more off
set type double
tempfile prices defs ref events original cap
import delimited "data/external/partial_industry_ppi.csv", clear varnames(1) encoding(UTF-8) case(preserve) asdouble
isid industry_mid_num year
keep industry_mid_num year ppi
save `prices'
import delimited "data/external/bok_annual_deflators_2020_100.csv", clear varnames(1) encoding(UTF-8) case(preserve) asdouble
rename fiscal_year year
isid year
keep year output_manufacturing_ppi capital_final_goods_dspi
save `defs'
import delimited "data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv", clear varnames(1) encoding(UTF-8) case(preserve) asdouble
drop if missing(ln_capital,ln_employees,ln_value_added)
merge m:1 industry_mid_num year using `prices', keep(match) nogen
merge m:1 year using `defs', keep(master match) assert(match using) nogen
gen double capital=exp(ln_capital)
gen double employees=exp(ln_employees)
gen double output_base=exp(ln_value_added)
gen double output_price=output_base*output_manufacturing_ppi/ppi
assert !missing(capital,employees,output_base,output_price)
assert min(capital,employees,output_base,output_price)>0
rename industry_mid_num industry
keep firm_id year industry capital employees output_base output_price
order firm_id year industry capital employees output_base output_price
sort firm_id year
isid firm_id year
assert _N==30801
save `ref'
export delimited "results/output_price/reference_panel.csv", replace
import delimited "data/processed/baseline_events.csv", clear varnames(1) encoding(UTF-8) case(preserve) asdouble
isid event_id
save `original'
keep event_id firm_id origin_year group
expand 2, generate(copy)
gen byte horizon=3*copy
gen int year=origin_year+horizon
drop copy
merge m:1 firm_id year using `ref', keep(master match)
bysort event_id: egen byte matched=min(_merge==3)
keep if matched
drop _merge matched
assert _N==17202
sort group event_id horizon
order event_id group origin_year horizon firm_id year industry capital employees output_base output_price
save `events'
export delimited "results/output_price/event_panel.csv", replace
keep if horizon==0
keep event_id
merge 1:1 event_id using `original', keep(match) nogen
order event_id firm_id origin_year group F0 F3 H0 H3 G0 G3 CU FS TC
sort group event_id
export delimited "results/output_price/full_reference_baseline_on_matched_events.csv", replace

import delimited "data/external/export_candidate.csv", clear varnames(1) encoding(UTF-8) case(preserve) asdouble stringcols(1)
keep if regexm(industry,"^[0-9]+$")
destring industry, replace
rename industry industry_mid_num
keep industry_mid_num year export_price
isid industry_mid_num year
order industry_mid_num year export_price
sort industry_mid_num year
export delimited "results/capital_price/export_prices.csv", replace
import delimited "data/external/capital_candidate.csv", clear varnames(1) encoding(UTF-8) case(preserve) asdouble
keep year implicit_investment_deflator
rename implicit_investment_deflator capital_candidate
merge 1:1 year using `defs', keep(master match) assert(match using) nogen
rename capital_final_goods_dspi capital_original
rename output_manufacturing_ppi output_original
order year capital_candidate capital_original output_original
sort year
save `cap'
export delimited "results/capital_price/capital_prices.csv", replace
foreach kind in reference event {
    if "`kind'"=="reference" use `ref', clear
    else use `events', clear
    merge m:1 year using `cap', keep(master match) assert(match using) nogen
    replace capital_candidate=capital*capital_original/capital_candidate
    assert !missing(capital_candidate) & capital_candidate>0
    drop capital_original output_original
    export delimited "results/capital_price/`kind'_panel.csv", replace
}
display "PRICE_INPUTS_COMPLETE"
