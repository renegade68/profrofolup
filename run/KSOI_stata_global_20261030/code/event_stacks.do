version 16.1
tempfile panel longall scores cohorts didall diag
use "$MIG/data/processed/strategy.dta", clear
egen long pid=group(firm_id)
xtset pid year
gen byte history=!missing(L.pid,L2.pid)
gen byte used_count=0
foreach k in iot cloud bigdata mobile ai blockchain 3dp robot arvr {
    gen byte used_`k'=(tech_`k'==1 | L.tech_`k'==1 | L2.tech_`k'==1)
    replace history=0 if missing(tech_`k',L.tech_`k',L2.tech_`k')
    replace used_count=used_count+used_`k'
}
gen str12 broad=cond(used_count==0,"no",cond(used_count==1,"pure","combined"))
gen str12 ai=cond(used_ai==0,"ai_none",cond(used_count==1,"ai_pure","ai_combined"))
save `panel'
forvalues h=3/5 {
    use `panel', clear
    gen double va0=exp(ln_value_added)
    gen double cap0=exp(ln_capital)
    gen double emp0=exp(ln_employees)
    gen double va`h'=exp(F`h'.ln_value_added)
    gen double cap`h'=exp(F`h'.ln_capital)
    gen double emp`h'=exp(F`h'.ln_employees)
    keep if history & !missing(va0,cap0,emp0,va`h',cap`h',emp`h')
    rename year origin_year
    gen str100 event_id=firm_id+"|"+string(origin_year,"%4.0f")
    keep event_id firm_id origin_year broad ai va0 cap0 emp0 va`h' cap`h' emp`h'
    reshape long va cap emp, i(event_id) j(timepoint)
    rename (va cap emp) (value_added capital employees)
    if `h'==3 {
        preserve
        expand 2, gen(copy)
        gen str8 family=cond(copy==0,"broad","ai")
        gen str12 group=cond(copy==0,broad,ai)
        rename timepoint horizon
        keep event_id firm_id origin_year family group horizon value_added capital employees
        order event_id firm_id origin_year family group horizon value_added capital employees
        sort firm_id origin_year family horizon
        assert _N==53672
        export delimited using "$MIG/data/processed/enterprise_activity_bogetoft_t3_stack.csv", replace
        restore
    }
    replace event_id=event_id+"|h`h'"
    rename ai group
    drop broad
    gen int target_horizon=`h'
    order event_id firm_id origin_year group target_horizon timepoint value_added capital employees
    if `h'>3 append using `longall'
    save `longall', replace
}
use `longall', clear
sort target_horizon firm_id origin_year timepoint
export delimited using "$MIG/data/processed/enterprise_activity_bogetoft_long_horizon_stack.csv", replace

* The short stack and DID use the fresh stage4 selection scores.
import delimited "$MIG/analysis/results/enterprise_activity_technology_strategy_dea_industry_year_trim_scores.csv", clear varnames(1) stringcols(1) asdouble encoding(UTF-8)
keep firm_id year dea_score
drop if missing(dea_score)
isid firm_id year
save `scores'
use "$MIG/data/processed/strategy.dta", clear
merge 1:1 firm_id year using `scores', keep(master match) nogen
egen long pid=group(firm_id)
xtset pid year
save `panel', replace
gen double va0=exp(ln_value_added)
gen double cap0=exp(ln_capital)
gen double emp0=exp(ln_employees)
gen double score0=dea_score
gen double va2=exp(F2.ln_value_added)
gen double cap2=exp(F2.ln_capital)
gen double emp2=exp(F2.ln_employees)
gen double score2=F2.dea_score
* String strategies cannot use time-series operators; merge their future values.
tempfile future
preserve
keep firm_id year technology_strategy
replace year=year-1
rename technology_strategy strategy1
save `future'
restore
merge 1:1 firm_id year using `future', keep(master match) nogen
preserve
keep firm_id year technology_strategy
replace year=year-2
rename technology_strategy strategy2
save `future', replace
restore
merge 1:1 firm_id year using `future', keep(master match) nogen
gen byte strategy_sustained_t_to_t2=(strategy1==technology_strategy & strategy2==technology_strategy)
keep if year<=2022 & !missing(score0,score2)
rename technology_strategy baseline_strategy
rename year origin_year
gen str100 event_id=firm_id+"|"+string(origin_year,"%4.0f")
keep event_id firm_id origin_year baseline_strategy strategy_sustained_t_to_t2 va0 cap0 emp0 va2 cap2 emp2 score0 score2
reshape long va cap emp score, i(event_id) j(horizon)
drop if missing(va,cap,emp)
rename (va cap emp score) (value_added capital employees global_score)
order event_id firm_id origin_year horizon baseline_strategy strategy_sustained_t_to_t2 value_added capital employees global_score
sort firm_id origin_year horizon
export delimited using "$MIG/data/processed/enterprise_activity_strategy_frontier_stack_t2.csv", replace
use `panel', clear

* First-observed AI entry with prior use checks, as in the corrected Python builder.
bysort firm_id (year): gen int prior_ai=sum(tech_ai==1)-(tech_ai==1)
by firm_id: gen int candidate=year if inrange(year,2018,2023) & tech_ai==1 & year[_n-1]==year-1 & tech_ai[_n-1]==0 & prior_ai==0
by firm_id: egen int first_entry=min(candidate)
save `panel', replace
postfile DD int cohort treated_firms control_firms long rows using `diag', replace
forvalues g=2018/2022 {
    use `panel', clear
    bysort firm_id: egen byte prevzero=max(year==`g'-1 & tech_ai==0)
    by firm_id: egen byte anypost=max(inrange(year,`g',`g'+2) & tech_ai==1)
    gen byte treated=first_entry==`g'
    gen byte control=!treated & prevzero & !anypost
    egen byte tag=tag(firm_id)
    count if tag & treated
    local nt=r(N)
    count if tag & control
    local nc=r(N)
    preserve
    keep if year==`g'
    keep firm_id technology_strategy
    rename technology_strategy entry_strategy
    save `cohorts', replace
    restore
    merge m:1 firm_id using `cohorts', keep(master match) nogen
    replace entry_strategy="control" if !treated
    keep if (treated | control) & inrange(year,max(2017,`g'-3),`g'+2) & !missing(dea_score)
    gen int stack=`g'
    gen str100 stack_firm_id=string(stack,"%4.0f")+"|"+firm_id
    gen int event_time=year-`g'
    gen double ln_dea=ln(dea_score)
    gen byte evt_m3=treated & event_time==-3
    gen byte evt_m2=treated & event_time==-2
    forvalues h=0/2 {
        gen byte evt_`h'=treated & event_time==`h'
    }
    keep stack firm_id stack_firm_id year event_time treated ln_dea dea_score industry_mid_num ln_employees ln_value_added ln_revenue ln_capital ln_labor_productivity entry_strategy evt_m3 evt_m2 evt_0 evt_1 evt_2
    order stack firm_id stack_firm_id year event_time treated ln_dea dea_score industry_mid_num ln_employees ln_value_added ln_revenue ln_capital ln_labor_productivity entry_strategy evt_m3 evt_m2 evt_0 evt_1 evt_2
    post DD (`g') (`nt') (`nc') (_N)
    if `g'>2018 append using `didall'
    save `didall', replace
}
postclose DD
use `didall', clear
sort stack firm_id year
export delimited using "$MIG/data/processed/enterprise_activity_ai_entry_stacked_did.csv", replace
use `diag', clear
export delimited using "$MIG/results/enterprise_activity_ai_entry_stacked_did_sample.csv", replace
