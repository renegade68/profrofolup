version 16.1
clear all
set more off
set linesize 180
capture mkdir "analysis/results"
capture log close
log using "analysis/results/enterprise_activity_maeng_lee_replication.log", replace text

import delimited using "data/processed/enterprise_activity_dynamic_panel_2017_2024.csv", varnames(1) encoding(utf8) clear
encode firm_id, gen(fid)
destring year industry_mid_num ln_revenue ln_capital ln_employees ln_average_wage ln_labor_productivity ///
    ln_exports_plus1 ai_active robot_active ai_or_robot_active, replace force
keep if inrange(year, 2017, 2024) & !missing(ln_revenue, ln_employees)
xtset fid year
gen ln_exports = ln(exp(ln_exports_plus1) - 1) if ln_exports_plus1 > 0
gen sales_growth = D.ln_revenue
gen export_growth = D.ln_exports

save "analysis/results/replication_model_inputs.dta", replace

tempname results
postfile `results' int end_year str12 technology str24 outcome str12 vcetype str8 exposure double coefficient std_error p_value observations firms using "analysis/results/enterprise_activity_maeng_lee_replication.dta", replace

foreach endyear in 2023 2024 {
foreach tech in ai robot combined {
    local treatment ai_or_robot_active
    if "`tech'" == "ai" local treatment ai_active
    if "`tech'" == "robot" local treatment robot_active

    foreach vcetype in conventional clustered {
        local vceopt ""
        if "`vcetype'" == "clustered" local vceopt "vce(cluster fid)"

        foreach outcome in ln_revenue sales_growth ln_average_wage export_growth {
            quietly xtreg `outcome' `treatment' L.`treatment' L2.`treatment' L.ln_capital L.ln_employees i.year if year<=`endyear', fe `vceopt'
            foreach lag in t t1 t2 {
                local v `treatment'
                if "`lag'" == "t1" local v L.`treatment'
                if "`lag'" == "t2" local v L2.`treatment'
                post `results' (`endyear') ("`tech'") ("`outcome'") ("`vcetype'") ("`lag'") (_b[`v']) (_se[`v']) (2*ttail(e(df_r),abs(_b[`v']/_se[`v']))) (e(N)) (e(N_g))
            }
        }

        quietly xtreg ln_labor_productivity `treatment' L.`treatment' L2.`treatment' L.ln_capital i.year if year<=`endyear', fe `vceopt'
        foreach lag in t t1 t2 {
            local v `treatment'
            if "`lag'" == "t1" local v L.`treatment'
            if "`lag'" == "t2" local v L2.`treatment'
            post `results' (`endyear') ("`tech'") ("ln_labor_productivity") ("`vcetype'") ("`lag'") (_b[`v']) (_se[`v']) (2*ttail(e(df_r),abs(_b[`v']/_se[`v']))) (e(N)) (e(N_g))
        }
    }
}
}

postclose `results'
use "analysis/results/enterprise_activity_maeng_lee_replication.dta", clear
export delimited using "analysis/results/enterprise_activity_maeng_lee_replication.csv", replace

log close
* Return to driver.
