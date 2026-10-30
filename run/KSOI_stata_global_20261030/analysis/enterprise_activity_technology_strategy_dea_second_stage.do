clear all
set more off
capture log close
log using "analysis/results/enterprise_activity_technology_strategy_dea_second_stage.log", text replace

tempfile panel scores
import delimited using "data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv", ///
    varnames(1) encoding(utf8) clear
keep firm_id year industry_mid_num technology_strategy ln_capital ln_employees
destring year industry_mid_num ln_capital ln_employees, replace force
save `panel'

import delimited using "analysis/results/enterprise_activity_technology_strategy_dea_industry_year_trim_scores.csv", ///
    varnames(1) encoding(utf8) clear
rename dea_score dea_iy
destring year dea_sample dea_iy, replace force
keep firm_id year dea_sample dea_iy
save `scores'

use `panel', clear
merge 1:1 firm_id year using `scores', keep(match) nogen
encode firm_id, gen(fid)
encode technology_strategy, gen(strategy6)
xtset fid year
gen double capital_intensity = ln_capital-ln_employees
gen double dea_scaled = dea_iy/100

quietly summarize strategy6 if technology_strategy == "none", meanonly
local none = r(min)

tempname results
postfile `results' str18 model str18 horizon str32 strategy double coefficient std_error p_value ///
    observations firms using "analysis/results/enterprise_activity_technology_strategy_dea_second_stage.dta", replace

* Current conditional association. Lagged covariates avoid conditioning on contemporaneous mediators.
capture quietly truncreg dea_scaled ib`none'.strategy6 L.dea_scaled L.ln_employees ///
    L.capital_intensity i.year i.industry_mid_num if dea_iy>1.0000001, ///
    ll(.01) vce(cluster fid) difficult
if _rc==0 {
    local N=e(N)
    egen byte tag0=tag(fid) if e(sample)
    quietly count if tag0
    local Ng=r(N)
    drop tag0
    levelsof strategy6 if e(sample) & strategy6 != `none', local(levels)
    foreach j of local levels {
        local label : label strategy6 `j'
        local b=_b[`j'.strategy6]
        local se=_se[`j'.strategy6]
        local p=2*normal(-abs(`b'/`se'))
        post `results' ("truncreg") ("current") ("`label'") (100*`b') (100*`se') (`p') (`N') (`Ng')
    }
}

* Strategy at t predicting efficiency at t+h, conditional on efficiency and scale at t.
foreach h in 1 2 {
    capture quietly truncreg F`h'.dea_scaled ib`none'.strategy6 dea_scaled ln_employees ///
        capital_intensity i.year i.industry_mid_num if F`h'.dea_iy>1.0000001, ///
        ll(.01) vce(cluster fid) difficult
    if _rc==0 {
        local N=e(N)
        egen byte tag`h'=tag(fid) if e(sample)
        quietly count if tag`h'
        local Ng=r(N)
        drop tag`h'
        levelsof strategy6 if e(sample) & strategy6 != `none', local(levels)
        foreach j of local levels {
            local label : label strategy6 `j'
            local b=_b[`j'.strategy6]
            local se=_se[`j'.strategy6]
            local p=2*normal(-abs(`b'/`se'))
            post `results' ("truncreg") ("plus`h'") ("`label'") (100*`b') (100*`se') (`p') (`N') (`Ng')
        }
    }
}

* Tobit is retained only for direct comparability with Bogetoft et al. (2024).
foreach h in 0 1 2 {
    if `h'==0 quietly tobit dea_iy ib`none'.strategy6 L.dea_iy L.ln_employees ///
        L.capital_intensity i.year i.industry_mid_num, ll(1) vce(cluster fid)
    else quietly tobit F`h'.dea_iy ib`none'.strategy6 dea_iy ln_employees ///
        capital_intensity i.year i.industry_mid_num, ll(1) vce(cluster fid)
    local N=e(N)
    egen byte tagtobit=tag(fid) if e(sample)
    quietly count if tagtobit
    local Ng=r(N)
    drop tagtobit
    levelsof strategy6 if e(sample) & strategy6 != `none', local(levels)
    foreach j of local levels {
        local label : label strategy6 `j'
        local b=_b[`j'.strategy6]
        local se=_se[`j'.strategy6]
        local p=2*normal(-abs(`b'/`se'))
        post `results' ("Tobit comparison") ("plus`h'") ("`label'") (`b') (`se') (`p') (`N') (`Ng')
    }
}

* Log-score OLS retains frontier observations and provides a stable comparison.
gen double ln_dea=ln(dea_iy)
foreach h in 0 1 2 {
    if `h'==0 quietly regress ln_dea ib`none'.strategy6 L.ln_dea L.ln_employees ///
        L.capital_intensity i.year i.industry_mid_num, vce(cluster fid)
    else quietly regress F`h'.ln_dea ib`none'.strategy6 ln_dea ln_employees ///
        capital_intensity i.year i.industry_mid_num, vce(cluster fid)
    local N=e(N)
    egen byte tagols=tag(fid) if e(sample)
    quietly count if tagols
    local Ng=r(N)
    drop tagols
    levelsof strategy6 if e(sample) & strategy6 != `none', local(levels)
    foreach j of local levels {
        local label : label strategy6 `j'
        local b=_b[`j'.strategy6]
        local se=_se[`j'.strategy6]
        local p=2*ttail(e(df_r),abs(`b'/`se'))
        post `results' ("log-score OLS") ("plus`h'") ("`label'") (`b') (`se') (`p') (`N') (`Ng')
    }
}

postclose `results'
use "analysis/results/enterprise_activity_technology_strategy_dea_second_stage.dta", clear
export delimited using "analysis/results/enterprise_activity_technology_strategy_dea_second_stage.csv", replace
list, noobs abbreviate(24)
log close
