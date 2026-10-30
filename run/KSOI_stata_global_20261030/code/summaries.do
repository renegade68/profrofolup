version 16.1
clear all
set more off
set type double
tempfile merged one summary allsummary correlations
local prefix "analysis/results/enterprise_activity_technology_strategy_dea_"
foreach s in no_trim global_trim industry_year_trim {
    import delimited "`prefix'`s'_scores.csv", clear varnames(1) encoding(UTF-8) asdouble
    isid firm_id year
    rename dea_score dea_`s'
    rename dea_sample sample_`s'
    if "`s'"!="no_trim" {
        drop technology_strategy
        merge 1:1 firm_id year using `merged', assert(match) nogen
    }
    save `merged', replace
}
rename technology_strategy strategy
preserve
collapse (count) n_no_trim=dea_no_trim n_global_trim=dea_global_trim n_industry_year_trim=dea_industry_year_trim ///
    (mean) mean_no_trim=dea_no_trim mean_global_trim=dea_global_trim mean_industry_year_trim=dea_industry_year_trim ///
    (median) median_no_trim=dea_no_trim median_global_trim=dea_global_trim median_industry_year_trim=dea_industry_year_trim, by(strategy)
export delimited "analysis/results/enterprise_activity_technology_strategy_global_dea_robustness.csv", replace
keep strategy n_*
rename n_no_trim complete
gen double excluded_global_trim=1-n_global_trim/complete
gen double excluded_industry_year_trim=1-n_industry_year_trim/complete
keep strategy complete excluded_*
export delimited "analysis/results/enterprise_activity_technology_strategy_dea_exclusion_audit.csv", replace
restore
rename strategy technology_strategy
rename (sample_global_trim sample_industry_year_trim) (sample_global_1_99 sample_industry_year_1_99)
drop sample_no_trim
sort firm_id year
export delimited "analysis/results/enterprise_activity_technology_strategy_global_dea_scores_robustness.csv", replace

* The original summary uses average ranks for ties and pairwise common keys.
import delimited "`prefix'industry_year_trim_scores.csv", clear varnames(1) encoding(UTF-8) asdouble
keep firm_id year dea_score
drop if missing(dea_score)
rename dea_score base_score
save `merged', replace
postfile COR str32 specification long common_observations double pearson_level double spearman_rank using `correlations', replace
foreach s in operating_vrs operating_crs income_vrs income_crs operating_vrs_joint_trim {
    local source "`s'"
    if "`s'"=="operating_vrs" local source industry_year_trim
    import delimited "`prefix'`source'_scores.csv", clear varnames(1) encoding(UTF-8) asdouble
    isid firm_id year
    drop if missing(dea_score)
    preserve
    collapse (count) observations=dea_score (mean) mean_score=dea_score (median) median_score=dea_score, by(technology_strategy)
    rename technology_strategy strategy
    gen str32 specification="`s'"
    order specification strategy observations mean_score median_score
    if "`s'"!="operating_vrs" append using `allsummary'
    save `allsummary', replace
    restore
    merge 1:1 firm_id year using `merged', keep(match) nogen
    sort firm_id year
    quietly correlate base_score dea_score
    local pearson=r(rho)
    local n=r(N)
    egen double rankbase=rank(base_score)
    egen double rankscore=rank(dea_score)
    quietly correlate rankbase rankscore
    post COR ("`s'") (`n') (`pearson') (r(rho))
}
postclose COR
use `correlations', clear
export delimited "analysis/results/enterprise_activity_dea_measurement_correlations.csv", replace
use `allsummary', clear
sort specification strategy
export delimited "analysis/results/enterprise_activity_dea_measurement_strategy_summary.csv", replace
display "STATA_GLOBAL_SUMMARIES_COMPLETE"
