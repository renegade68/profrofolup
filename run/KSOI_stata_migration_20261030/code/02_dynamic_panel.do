version 16.1
tempfile defs cohort
import delimited "$MIG/data/external/bok_annual_deflators_2020_100.csv", clear varnames(1) asdouble encoding(UTF-8)
rename fiscal_year year
keep year output_manufacturing_ppi intermediate_goods_dspi capital_final_goods_dspi
isid year
save `defs'
use "$MIG/data/processed/selected.dta", clear
keep if inrange(year,2015,2024) & industry_large=="C" & firm_id!=""
isid firm_id year
merge m:1 year using `defs', keep(master match) nogen
gen double revenue_real=revenue*100/output_manufacturing_ppi
gen double capital_real=tangible_assets*100/capital_final_goods_dspi
gen double intermediate_real=cost_of_sales*100/intermediate_goods_dspi
gen double value_added_real=value_added_constructed*100/output_manufacturing_ppi
gen double labor_cost_real=labor_cost*100/output_manufacturing_ppi
gen double exports_real=cond(missing(direct_exports),0,direct_exports*100/output_manufacturing_ppi)
gen double employees=employees_total_constructed
gen double value_added_income_real=(pretax_profit+labor_cost+rent+depreciation+taxes)*100/output_manufacturing_ppi
foreach k in revenue capital intermediate value_added value_added_income {
    gen double ln_`k'=ln(`k'_real) if `k'_real>0 & `k'_real<.
}
gen double ln_employees=ln(employees) if employees>0 & employees<.
gen double ln_average_wage=ln(labor_cost_real/employees) if labor_cost_real>0 & labor_cost_real<. & employees>0 & employees<.
gen double ln_labor_productivity=ln(value_added_real/employees) if value_added_real>0 & value_added_real<. & employees>0 & employees<.
gen double ln_labor_productivity_income=ln(value_added_income_real/employees) if value_added_income_real>0 & value_added_income_real<. & employees>0 & employees<.
gen double ln_capital_productivity=ln(value_added_real/capital_real) if value_added_real>0 & value_added_real<. & capital_real>0 & capital_real<.
gen byte exporter=exports_real>0 if exports_real<.
gen double ln_exports_plus1=ln(1+exports_real)
gen double gross_margin=(revenue-cost_of_sales)/revenue if revenue>0 & revenue<. & cost_of_sales>=0 & cost_of_sales<.
gen int industry_mid_num=real(ustrregexra(industry_mid,"[^0-9]",""))
gen byte usable=!missing(ln_revenue,ln_capital,ln_intermediate,ln_employees)
bysort firm_id (year): egen int usable_years_2015_2024=total(usable)
gen byte stable8=usable_years_2015_2024>=8
foreach k in ai robot combined {
    local v `k'_active
    if "`k'"=="combined" local v ai_or_robot_active
    bysort firm_id (year): gen double prior=sum(cond(missing(`v'),0,`v'))-cond(missing(`v'),0,`v')
    by firm_id: gen byte consecutive=_n>1 & year[_n-1]==year-1 & !missing(`v'[_n-1],`v')
    gen str14 `k'_state="unclassified"
    by firm_id: replace `k'_state="nonuser" if consecutive & `v'[_n-1]==0 & `v'==0
    by firm_id: replace `k'_state="first_entry" if consecutive & `v'[_n-1]==0 & `v'==1 & prior==0
    by firm_id: replace `k'_state="reentry" if consecutive & `v'[_n-1]==0 & `v'==1 & prior!=0
    by firm_id: replace `k'_state="continuation" if consecutive & `v'[_n-1]==1 & `v'==1
    by firm_id: replace `k'_state="exit" if consecutive & `v'[_n-1]==1 & `v'==0
    foreach state in first_entry reentry continuation exit {
        gen byte `k'_`state'=(`k'_state=="`state'")
    }
    drop prior consecutive
    preserve
    keep if year>=2017 & !missing(`v')
    bysort firm_id (year): gen int prior_zero=sum(`v'==0)-(`v'==0)
    by firm_id: gen int post_n=_N-_n+1
    by firm_id: egen int nzero=total(`v'==0)
    gen int post_zero=nzero-prior_zero
    by firm_id: gen int candidate=year if _n>1 & `v'==1 & `v'[_n-1]==0 & prior_zero>=2 & post_n>=3 & post_zero==0
    by firm_id: egen int `k'_sustained_cohort=min(candidate)
    by firm_id: egen byte `k'_ever_user=max(`v'==1)
    gen byte `k'_never_user=1-`k'_ever_user
    by firm_id: keep if _n==1
    keep firm_id `k'_sustained_cohort `k'_never_user `k'_ever_user
    save `cohort', replace
    restore
    merge m:1 firm_id using `cohort', keep(master match) nogen
    gen int `k'_event_time=year-`k'_sustained_cohort
}
keep if inrange(year,2017,2024)
local base firm_id year region industry_mid industry_mid_num stable8 usable_years_2015_2024 ln_revenue ln_capital ln_intermediate ln_employees ln_value_added ln_value_added_income ln_average_wage ln_labor_productivity ln_labor_productivity_income ln_capital_productivity exporter ln_exports_plus1 gross_margin ai_active robot_active ai_or_robot_active ai_stage robot_stage ai_stage_canonical robot_stage_canonical
local states
foreach k in ai robot combined {
    local states `states' `k'_state `k'_first_entry `k'_reentry `k'_continuation `k'_exit
}
foreach k in ai robot combined {
    local states `states' `k'_sustained_cohort `k'_never_user `k'_ever_user `k'_event_time
}
keep `base' `states'
order `base' `states'
sort firm_id year
assert _N==49780
save "$MIG/data/processed/dynamic.dta", replace
export delimited using "$MIG/data/processed/enterprise_activity_dynamic_panel_2017_2024.csv", replace
tempfile statesummary cohortsummary
local first 1
foreach k in ai robot combined {
    preserve
    keep year `k'_state
    rename `k'_state state
    contract year state, freq(N)
    gen str8 technology="`k'"
    if !`first' append using `statesummary'
    save `statesummary', replace
    restore
    preserve
    keep firm_id `k'_sustained_cohort `k'_never_user `k'_ever_user
    bysort firm_id: keep if _n==1
    rename (`k'_sustained_cohort `k'_never_user `k'_ever_user) (cohort never ever)
    contract cohort never ever, freq(firms)
    gen str8 technology="`k'"
    if !`first' append using `cohortsummary'
    save `cohortsummary', replace
    restore
    local first 0
}
use `statesummary', clear
order technology year state N
sort technology year state
export delimited using "$MIG/results/enterprise_activity_dynamic_state_summary.csv", replace
use `cohortsummary', clear
order technology cohort never ever firms
sort technology cohort never ever
export delimited using "$MIG/results/enterprise_activity_sustained_cohort_summary.csv", replace
