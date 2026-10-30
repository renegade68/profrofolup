version 16.1
clear all
set more off
set type float
do code/frontier.mata
* Independent dual supporting planes, with no call to st0444/teradial.
import delimited "data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv", clear varnames(1) encoding(UTF-8)
drop if missing(ln_capital,ln_employees,ln_value_added)
gen double capital=exp(ln_capital)
gen double employees=exp(ln_employees)
gen double output=exp(ln_value_added)
bysort industry_mid_num year: egen double p1=pctile(output), p(1)
bysort industry_mid_num year: egen double p99=pctile(output), p(99)
keep if inrange(output,p1,p99)
keep firm_id year industry_mid_num capital employees output
tempfile panel checks
save `panel'
postfile CHECK int industry long retained long pareto long planes double max_scaled_error using `checks', replace
foreach ind in 10 11 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 {
    use `panel', clear
    keep if industry_mid_num==`ind'
    sort firm_id year
    mata: z=st_data(.,("capital","employees","output")); f=ks_build(z); independent=ks_score(f,z)
    gen double plane_score=.
    mata: st_store(.,"plane_score",independent); st_numscalar("pareto_n",f.n_pareto); st_numscalar("planes_n",rows(f.planes))
    tempfile evaluated
    save `evaluated', replace
    import delimited "analysis/results/industry_dea_`ind'_scores.csv", clear varnames(1) encoding(UTF-8) asdouble
    keep if dea_sample==1
    merge 1:1 firm_id year using `evaluated', assert(match) nogen
    gen double scaled_error=abs(plane_score-industry_dea_score)/max(1,abs(industry_dea_score))
    assert !missing(scaled_error) & scaled_error<1e-6
    quietly summarize scaled_error, meanonly
    post CHECK (`ind') (_N) (scalar(pareto_n)) (scalar(planes_n)) (r(max))
    keep firm_id year industry_mid_num industry_dea_score plane_score scaled_error
    export delimited "validation/independent_industry_`ind'.csv", replace
}
postclose CHECK
use `checks', clear
export delimited "validation/independent_industry_checks.csv", replace
display "INDEPENDENT_INDUSTRY_COMPLETE"
