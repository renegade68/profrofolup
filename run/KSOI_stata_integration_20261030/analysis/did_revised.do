clear all
set more off
capture log close
log using "analysis/results/enterprise_activity_ai_entry_trend_balanced_did.log", text replace

import delimited using "data/processed/did_history.csv", ///
    varnames(1) encoding(utf8) clear
destring stack year event_time treated ln_dea ln_employees ln_capital ln_revenue ///
    ln_value_added ln_labor_productivity industry_mid_num evt_m3 evt_m2 evt_0 evt_1 evt_2, replace force
keep if inrange(stack,2019,2022)
drop if audit_past_ai==1
encode firm_id, gen(original_fid)
encode stack_firm_id, gen(stack_fid)
xtset stack_fid year
gen double capital_intensity=ln_capital-ln_employees
gen double d_dea=D.ln_dea
gen double d_employees=D.ln_employees
gen double d_revenue=D.ln_revenue

gen double propensity_trend=.
foreach g in 2019 2020 2021 2022 {
    quietly logit treated ln_dea ln_employees capital_intensity ln_revenue ln_value_added ///
        d_dea d_employees d_revenue i.industry_mid_num if stack==`g' & event_time==-1
    predict double phat if stack==`g' & event_time==-1, pr
    bysort stack_fid: egen double pstack=max(phat)
    replace propensity_trend=pstack if stack==`g'
    drop phat pstack
}
gen double overlap_trend=cond(treated==1,1-propensity_trend,propensity_trend)
gen byte common_support=0
foreach g in 2019 2020 2021 2022 {
    quietly summarize propensity_trend if stack==`g' & treated==1 & event_time==-1
    replace common_support=inrange(propensity_trend,r(min),r(max)) if stack==`g'
}

tempname balance
postfile `balance' int cohort str20 covariate str8 weighting double smd ///
    using "analysis/results/enterprise_activity_ai_entry_trend_balance.dta", replace
foreach g in 2019 2020 2021 2022 {
    foreach x in ln_dea ln_employees capital_intensity ln_revenue ln_value_added d_dea d_employees d_revenue {
        quietly summarize `x' if stack==`g' & event_time==-1 & treated==1
        local mt=r(mean)
        local vt=r(Var)
        quietly summarize `x' if stack==`g' & event_time==-1 & treated==0
        local mc=r(mean)
        local vc=r(Var)
        local raw=(`mt'-`mc')/sqrt((`vt'+`vc')/2)
        post `balance' (`g') ("`x'") ("raw") (`raw')
        quietly summarize `x' [aw=overlap_trend] if stack==`g' & event_time==-1 & treated==1
        local mt=r(mean)
        local vt=r(Var)
        quietly summarize `x' [aw=overlap_trend] if stack==`g' & event_time==-1 & treated==0
        local mc=r(mean)
        local vc=r(Var)
        local weighted=(`mt'-`mc')/sqrt((`vt'+`vc')/2)
        post `balance' (`g') ("`x'") ("overlap") (`weighted')
    }
}
postclose `balance'

tempname results
postfile `results' str20 specification str24 outcome str8 event double coefficient std_error p_value observations treated_firms ///
    using "analysis/results/enterprise_activity_ai_entry_trend_balanced_did.dta", replace
foreach y in ln_dea ln_employees ln_value_added ln_revenue ln_labor_productivity {
    quietly xtreg `y' evt_m3 evt_m2 evt_0 evt_1 evt_2 i.stack#i.year ///
        [pw=overlap_trend] if common_support==1, fe vce(cluster original_fid)
    gen byte sample_`y'=e(sample)
    egen byte tag=tag(original_fid) if e(sample) & treated==1
    quietly count if tag
    local Nt=r(N)
    drop tag
    foreach v in evt_m3 evt_m2 evt_0 evt_1 evt_2 {
        local b=_b[`v']
        local se=_se[`v']
        local p=2*ttail(e(df_r),abs(`b'/`se'))
        post `results' ("trend_overlap") ("`y'") ("`v'") (`b') (`se') (`p') (e(N)) (`Nt')
    }
}

preserve
keep if sample_ln_dea==1
save "analysis/results/did_estimation_rows.dta", replace
export delimited using "analysis/results/did_estimation_rows.csv", replace
restore

foreach omit in 2019 2020 2021 2022 {
    foreach y in ln_dea ln_employees ln_value_added ln_revenue ln_labor_productivity {
        quietly xtreg `y' evt_m3 evt_m2 evt_0 evt_1 evt_2 i.stack#i.year ///
            [pw=overlap_trend] if common_support==1 & stack!=`omit', fe vce(cluster original_fid)
        foreach v in evt_0 evt_1 evt_2 {
            local b=_b[`v']
            local se=_se[`v']
            local p=2*ttail(e(df_r),abs(`b'/`se'))
            post `results' ("omit_`omit'") ("`y'") ("`v'") (`b') (`se') (`p') (e(N)) (.)
        }
    }
}
postclose `results'
preserve
keep if event_time==-1
export delimited using "analysis/results/did_baseline.csv", replace
restore


preserve
use "analysis/results/enterprise_activity_ai_entry_trend_balance.dta", clear
export delimited using "analysis/results/enterprise_activity_ai_entry_trend_balance.csv", replace
restore
use "analysis/results/enterprise_activity_ai_entry_trend_balanced_did.dta", clear
export delimited using "analysis/results/enterprise_activity_ai_entry_trend_balanced_did.csv", replace
list, noobs abbreviate(24)
log close
