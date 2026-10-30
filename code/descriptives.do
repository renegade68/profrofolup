version 16.1
capture program drop strategy_names
program define strategy_names
    gen str64 strategy=""
    gen str40 strategy_ko=""
    gen byte display_order=.
    local i=0
    foreach s in none other_no_ai ai_only ai_digital_bundle ai_physical_bundle ai_cross_bundle {
        local ++i
        replace display_order=`i' if strategy_code=="`s'"
    }
    replace strategy="No technology" if display_order==1
    replace strategy="Other technology, no AI" if display_order==2
    replace strategy="AI only" if display_order==3
    replace strategy="AI + digital complements" if display_order==4
    replace strategy="AI + physical complements" if display_order==5
    replace strategy="AI + cross-domain complements" if display_order==6
    replace strategy_ko="미활용" if display_order==1
    replace strategy_ko="AI 없는 타 기술" if display_order==2
    replace strategy_ko="AI 단독" if display_order==3
    replace strategy_ko="AI+디지털" if display_order==4
    replace strategy_ko="AI+물리" if display_order==5
    replace strategy_ko="AI+교차결합" if display_order==6
    assert !missing(display_order)
    sort display_order
end
use "$S1/data/processed/strategy.dta", clear
gen byte no_technology=technology_count==0
gen byte one_technology=technology_count==1
gen byte two_or_more_technologies=technology_count>=2
gen byte ai_any=tech_ai==1
gen byte ai_only=tech_ai==1 & technology_count==1
gen byte ai_with_other=tech_ai==1 & technology_count>=2
collapse (count) complete_responses=technology_count (sum) no_technology one_technology two_or_more_technologies ai_any ai_only ai_with_other, by(year)
gen double ai_share_percent=round(100*ai_any/complete_responses,.01)
order year complete_responses no_technology one_technology two_or_more_technologies ai_any ai_share_percent ai_only ai_with_other
export delimited exports/tables/table01.csv, replace
export delimited exports/figures/figure01_data.csv, replace

tempfile architecture fe
use "$S1/data/processed/strategy.dta", clear
egen byte tag=tag(technology_strategy firm_id)
gen byte denominator=!missing(strategy_continues)
collapse (count) firm_years=year (sum) distinct_firms=tag dea_complete numerator=strategy_continues denominator, by(technology_strategy)
rename technology_strategy strategy
save `architecture'
import delimited "$S4/analysis/results/enterprise_activity_technology_strategy_dea_exclusion_audit.csv", clear varnames(1) asdouble encoding(UTF-8) case(preserve)
merge 1:1 strategy using `architecture', assert(match) nogen
rename strategy strategy_code
gen double dea_complete_percent=round(100*dea_complete/firm_years,.01)
gen double same_strategy_next_year_percent=round(100*numerator/denominator,.01)
gen double excluded_global_trim_percent=round(100*excluded_global_trim,.01)
gen double excluded_iy_pct=round(100*excluded_industry_year_trim,.01)
* Preserve the original Python table's ties-to-even rule at exact half-cents.
* In this sample AI-only exclusion is exactly 3.125%, displayed as 3.12%.
replace excluded_iy_pct=floor(10000*excluded_industry_year_trim)/100 if ///
    mod(10000*excluded_industry_year_trim,1)==.5 & mod(floor(10000*excluded_industry_year_trim),2)==0
strategy_names
keep strategy strategy_code firm_years distinct_firms dea_complete dea_complete_percent same_strategy_next_year_percent excluded_global_trim_percent excluded_iy_pct
order strategy strategy_code firm_years distinct_firms dea_complete dea_complete_percent same_strategy_next_year_percent excluded_global_trim_percent excluded_iy_pct
tempfile csv
export delimited "`csv'", replace
filefilter "`csv'" exports/tables/table02.csv, from("excluded_iy_pct") to("excluded_industry_year_trim_percent") replace

import delimited "$S3/analysis/results/enterprise_activity_technology_strategy_mean_performance.csv", clear varnames(1) asdouble encoding(UTF-8) case(preserve)
keep if specification=="FE value added"
keep strategy coefficient std_error p_value
rename strategy technology_strategy
save `fe'
import delimited "$S4/analysis/results/enterprise_activity_technology_strategy_global_dea_summary.csv", clear varnames(1) asdouble encoding(UTF-8) case(preserve)
merge 1:1 technology_strategy using `fe', keep(master match) nogen
rename technology_strategy strategy_code
strategy_names
gen long dea_observations=observations
gen double dea_mean_output_inefficiency=round(mean_inefficiency,.001)
gen double dea_median_output_inefficiency=round(median_inefficiency,.001)
gen double dea_p25=round(p25_inefficiency,.001)
gen double dea_p75=round(p75_inefficiency,.001)
gen str24 fe_log_value_added_coefficient=string(round(coefficient,.0001),"%9.4f")
replace fe_log_value_added_coefficient="reference" if strategy_code=="none"
gen double fe_standard_error=round(std_error,.0001)
gen double fe_p_value=round(p_value,.0001)
keep strategy strategy_code dea_observations dea_mean_output_inefficiency dea_median_output_inefficiency dea_p25 dea_p75 fe_log_value_added_coefficient fe_standard_error fe_p_value
order strategy strategy_code dea_observations dea_mean_output_inefficiency dea_median_output_inefficiency dea_p25 dea_p75 fe_log_value_added_coefficient fe_standard_error fe_p_value
export delimited exports/tables/table03.csv, replace
export delimited exports/figures/figure02_data.csv, replace
