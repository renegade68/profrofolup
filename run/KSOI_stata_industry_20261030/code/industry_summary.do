version 16.1
clear all
set more off
set type double
tempfile industry global
foreach ind in 10 11 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 {
    import delimited "analysis/results/industry_dea_`ind'_scores.csv", clear varnames(1) encoding(UTF-8) asdouble
    assert industry_mid_num==`ind'
    assert missing(industry_dea_score)==(dea_sample==0)
    keep if !missing(industry_dea_score)
    if `ind'!=10 append using `industry'
    save `industry', replace
}
isid firm_id year
sort firm_id year
export delimited "analysis/results/industry_dea_combined_scores.csv", replace
preserve
collapse (count) observations=industry_dea_score (mean) mean_industry_score=industry_dea_score (median) median_industry_score=industry_dea_score, by(technology_strategy)
rename technology_strategy strategy
export delimited "analysis/results/enterprise_activity_industry_dea_strategy_summary.csv", replace
restore
import delimited "analysis/results/enterprise_activity_technology_strategy_dea_industry_year_trim_scores.csv", clear varnames(1) encoding(UTF-8) asdouble
keep firm_id year dea_score
drop if missing(dea_score)
isid firm_id year
merge 1:1 firm_id year using `industry', keep(match) nogen
sort firm_id year
quietly correlate dea_score industry_dea_score
local n=r(N)
local pearson=r(rho)
egen double global_rank=rank(dea_score)
egen double industry_rank=rank(industry_dea_score)
quietly correlate global_rank industry_rank
local spearman=r(rho)
clear
set obs 1
gen long common_observations=`n'
gen double pearson_level=`pearson'
gen double spearman_rank=`spearman'
export delimited "analysis/results/enterprise_activity_industry_dea_comparison.csv", replace
display "INDUSTRY_SUMMARY_COMPLETE"
