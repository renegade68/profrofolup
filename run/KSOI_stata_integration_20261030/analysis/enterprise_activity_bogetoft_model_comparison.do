version 16.1
clear all
set more off
capture log close
log using "analysis/results/enterprise_activity_bogetoft_model_comparison.log", text replace
import delimited using "data/processed/enterprise_activity_bogetoft_model_comparison.csv", varnames(1) encoding(utf8) clear
encode firm_id, gen(fid)
encode ai_state, gen(ai_state_n)
encode technology_intensity, gen(intensity)
destring year industry_mid_num dea_t dea_t1 dea_t3 ln_employees_t1 capital_intensity_t1 bog_active bog_pure bog_combined bog_ai_window bog_ai_pure bog_ai_combined current_ai, replace force
gen ln_dea_t=ln(dea_t)
gen ln_dea_t1=ln(dea_t1)
quietly summarize intensity if technology_intensity=="M4", meanonly
local m4=r(min)
quietly summarize ai_state_n if ai_state=="never_recent", meanonly
local never=r(min)

tempname out
postfile `out' str28 model str28 exposure double coefficient std_error p_value observations firms using "analysis/results/enterprise_activity_bogetoft_model_comparison.dta", replace

* Bogetoft Table 4 col. 1 analogue: pooled VRS score at t, adoption information t-2..t,
* efficiency and technology-intensity controls at t-3, year effects, Tobit at one.
* The Korean survey has no comparable share of workers with 16+ years of education.
quietly tobit dea_t bog_active dea_t3 ib`m4'.intensity i.year, ll(1) vce(cluster fid)
post `out' ("Bogetoft Tobit") ("Any technology, t-2:t") (_b[bog_active]) (_se[bog_active]) (2*normal(-abs(_b[bog_active]/_se[bog_active]))) (e(N)) (e(N_clust))

quietly tobit dea_t bog_pure bog_combined dea_t3 ib`m4'.intensity i.year, ll(1) vce(cluster fid)
foreach v in bog_pure bog_combined {
    post `out' ("Bogetoft Tobit") ("`v', t-2:t") (_b[`v']) (_se[`v']) (2*normal(-abs(_b[`v']/_se[`v']))) (e(N)) (e(N_clust))
}

quietly tobit dea_t bog_ai_window dea_t3 ib`m4'.intensity i.year, ll(1) vce(cluster fid)
post `out' ("Bogetoft Tobit") ("Any AI, t-2:t") (_b[bog_ai_window]) (_se[bog_ai_window]) (2*normal(-abs(_b[bog_ai_window]/_se[bog_ai_window]))) (e(N)) (e(N_clust))

quietly tobit dea_t bog_ai_pure bog_ai_combined dea_t3 ib`m4'.intensity i.year, ll(1) vce(cluster fid)
foreach v in bog_ai_pure bog_ai_combined {
    post `out' ("Bogetoft Tobit") ("`v', t-2:t") (_b[`v']) (_se[`v']) (2*normal(-abs(_b[`v']/_se[`v']))) (e(N)) (e(N_clust))
}

* Same-sample Korean-data adjustment: annual current use, t-1 position/scale,
* detailed industry and year controls, log score retaining frontier observations.
quietly regress ln_dea_t current_ai ln_dea_t1 ln_employees_t1 capital_intensity_t1 i.industry_mid_num i.year, vce(cluster fid)
post `out' ("Annual-state log OLS") ("Current AI") (_b[current_ai]) (_se[current_ai]) (2*ttail(e(df_r),abs(_b[current_ai]/_se[current_ai]))) (e(N)) (e(N_clust))

quietly regress ln_dea_t ib`never'.ai_state_n ln_dea_t1 ln_employees_t1 capital_intensity_t1 i.industry_mid_num i.year, vce(cluster fid)
levelsof ai_state_n if ai_state_n!=`never', local(levels)
foreach j of local levels {
    local lab : label ai_state_n `j'
    post `out' ("Nonabsorbing-state OLS") ("`lab'") (_b[`j'.ai_state_n]) (_se[`j'.ai_state_n]) (2*ttail(e(df_r),abs(_b[`j'.ai_state_n]/_se[`j'.ai_state_n]))) (e(N)) (e(N_clust))
}
postclose `out'
use "analysis/results/enterprise_activity_bogetoft_model_comparison.dta", clear
export delimited using "analysis/results/enterprise_activity_bogetoft_model_comparison.csv", replace
log close
* Return to integration driver; original batch exit removed.
