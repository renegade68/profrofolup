clear all
set more off
capture log close
log using "analysis/results/enterprise_activity_ai_users_only_dea_comparison.log", text replace

tempfile panel scores
import delimited using "data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv", ///
    varnames(1) encoding(utf8) clear
keep firm_id year industry_mid_num technology_strategy ln_capital ln_employees tech_ai
destring year industry_mid_num ln_capital ln_employees tech_ai, replace force
save `panel'

import delimited using "analysis/results/enterprise_activity_technology_strategy_dea_industry_year_trim_scores.csv", ///
    varnames(1) encoding(utf8) clear
rename dea_score dea_iy
destring year dea_iy, replace force
keep firm_id year dea_iy
save `scores'

use `panel', clear
merge 1:1 firm_id year using `scores', keep(match) nogen
encode firm_id, gen(fid)
encode technology_strategy, gen(strategy4)
xtset fid year
gen double capital_intensity=ln_capital-ln_employees
gen double ln_dea=ln(dea_iy)

quietly summarize strategy4 if technology_strategy=="ai_only", meanonly
local ai_only=r(min)

tempname results
postfile `results' str20 model str10 horizon str32 strategy double coefficient std_error p_value ///
    observations firms using "analysis/results/enterprise_activity_ai_users_only_dea_comparison.dta", replace

* Primary: log-score OLS among AI users, AI-only as the reference.
foreach h in 0 1 2 {
    if `h'==0 quietly regress ln_dea ib`ai_only'.strategy4 L.ln_dea L.ln_employees ///
        L.capital_intensity i.year i.industry_mid_num if tech_ai==1, vce(cluster fid)
    else quietly regress F`h'.ln_dea ib`ai_only'.strategy4 ln_dea ln_employees ///
        capital_intensity i.year i.industry_mid_num if tech_ai==1, vce(cluster fid)
    local N=e(N)
    egen byte tag=tag(fid) if e(sample)
    quietly count if tag
    local Ng=r(N)
    drop tag
    levelsof strategy4 if e(sample) & strategy4!=`ai_only', local(levels)
    foreach j of local levels {
        local label : label strategy4 `j'
        local b=_b[`j'.strategy4]
        local se=_se[`j'.strategy4]
        local p=2*ttail(e(df_r),abs(`b'/`se'))
        post `results' ("log-score OLS") ("plus`h'") ("`label'") (`b') (`se') (`p') (`N') (`Ng')
    }
}

* Original-paper comparison only; raw score is strongly right-skewed.
foreach h in 0 1 2 {
    if `h'==0 quietly tobit dea_iy ib`ai_only'.strategy4 L.dea_iy L.ln_employees ///
        L.capital_intensity i.year i.industry_mid_num if tech_ai==1, ll(1) vce(cluster fid)
    else quietly tobit F`h'.dea_iy ib`ai_only'.strategy4 dea_iy ln_employees ///
        capital_intensity i.year i.industry_mid_num if tech_ai==1, ll(1) vce(cluster fid)
    local N=e(N)
    egen byte tag=tag(fid) if e(sample)
    quietly count if tag
    local Ng=r(N)
    drop tag
    levelsof strategy4 if e(sample) & strategy4!=`ai_only', local(levels)
    foreach j of local levels {
        local label : label strategy4 `j'
        local b=_b[`j'.strategy4]
        local se=_se[`j'.strategy4]
        local p=2*normal(-abs(`b'/`se'))
        post `results' ("Tobit comparison") ("plus`h'") ("`label'") (`b') (`se') (`p') (`N') (`Ng')
    }
}

postclose `results'
use "analysis/results/enterprise_activity_ai_users_only_dea_comparison.dta", clear
export delimited using "analysis/results/enterprise_activity_ai_users_only_dea_comparison.csv", replace
list, noobs abbreviate(24)
log close
