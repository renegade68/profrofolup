version 16.1
tempfile long km wide
import delimited "$S4/analysis/results/enterprise_activity_technology_strategy_dea_second_stage.csv", clear varnames(1) asdouble encoding(UTF-8) case(preserve)
keep if model=="log-score OLS"
assert _N==15
export delimited exports/tables/table04.csv, replace
import delimited "$S4/analysis/results/enterprise_activity_ai_entry_trend_balanced_did.csv", clear varnames(1) asdouble encoding(UTF-8) case(preserve)
keep if specification=="trend_overlap"
gen double ci_low=coefficient-1.96*std_error
gen double ci_high=coefficient+1.96*std_error
gen int event_time=real(substr(event,5,.))
replace event_time=-real(substr(event,6,.)) if substr(event,5,1)=="m"
rename outcome outcome_code
gen str32 outcome=""
replace outcome="DEA output inefficiency" if outcome_code=="ln_dea"
replace outcome="Employment" if outcome_code=="ln_employees"
replace outcome="Value added" if outcome_code=="ln_value_added"
replace outcome="Revenue" if outcome_code=="ln_revenue"
replace outcome="Labor productivity" if outcome_code=="ln_labor_productivity"
assert outcome!=""
preserve
rename event event_code
keep outcome outcome_code event_code event_time coefficient ci_low ci_high
order outcome outcome_code event_code event_time coefficient ci_low ci_high
export delimited exports/figures/figure03_data.csv, replace
restore
keep if event_time>=0
assert _N==15
export delimited exports/tables/table05.csv, replace
import delimited "$S3/analysis/results/short_firm_cluster.csv", clear varnames(1) asdouble encoding(UTF-8) case(preserve)
rename strategy strategy_code
strategy_names
rename events matched_events
rename raw raw_catchup_ratio
rename point bias_corrected_catchup_ratio
gen str3 ci_includes_no_change=cond(ci_low<=1 & ci_high>=1,"Yes","No")
gen str40 evidence_class=cond(matched_events<30,"Exploratory; small sample","Uncertain")
keep strategy strategy_code matched_events raw_catchup_ratio bias_corrected_catchup_ratio ci_low ci_high ci_includes_no_change evidence_class
order strategy strategy_code matched_events raw_catchup_ratio bias_corrected_catchup_ratio ci_low ci_high ci_includes_no_change evidence_class
export delimited exports/tables/table06.csv, replace
export delimited exports/figures/figure04_data.csv, replace
import delimited "$S4/results/enterprise_activity_ai_frontier_gap_duration_summary.csv", clear varnames(1) asdouble encoding(UTF-8) case(preserve)
keep if horizon_years<=3
export delimited exports/tables/table07.csv, replace
import delimited "$S4/analysis/results/enterprise_activity_bogetoft_model_comparison.csv", clear varnames(1) asdouble encoding(UTF-8) case(preserve)
keep if inlist(exposure,"Any AI, t-2:t","bog_ai_pure, t-2:t","bog_ai_combined, t-2:t","Current AI","first_entry","continuation","reentry","exit_or_past")
assert _N==8
export delimited exports/tables/table08.csv, replace
import delimited "$S3/analysis/results/matched_component_cluster.csv", clear varnames(1) asdouble encoding(UTF-8) case(preserve)
export delimited exports/tables/table09.csv, replace
import delimited "$S3/analysis/results/long_firm_cluster.csv", clear varnames(1) asdouble encoding(UTF-8) case(preserve)
keep if horizon>=4
keep horizon group events point ci_low ci_high
rename (events point ci_low ci_high) (events_ point_ low_ high_)
reshape wide events_ point_ low_ high_, i(horizon) j(group) string
save `long'
import delimited "$S4/results/enterprise_activity_ai_frontier_gap_duration_summary.csv", clear varnames(1) asdouble encoding(UTF-8) case(preserve)
keep if horizon_years>=4 & gap_closed_fraction<1
gen byte threshold=100*gap_closed_fraction
keep horizon_years threshold km_cumulative_probability bootstrap_ci_low bootstrap_ci_high
rename (horizon_years km_cumulative_probability bootstrap_ci_low bootstrap_ci_high) (horizon km_ km_low_ km_high_)
reshape wide km_ km_low_ km_high_, i(horizon) j(threshold)
merge 1:1 horizon using `long', assert(master match) nogen
assert _N==3
sort horizon
export delimited exports/tables/table10.csv, replace
import delimited "$S2/results/joint_decomposition_summary_1000.csv", clear varnames(1) asdouble encoding(UTF-8) case(preserve)
export delimited exports/tables/table11.csv, replace
import delimited "$S5/analysis/results/enterprise_activity_maeng_lee_key_replication_comparison.csv", clear varnames(1) asdouble encoding(UTF-8) case(preserve)
export delimited exports/tables/appendix_A1.csv, replace
import delimited "$S4/analysis/results/enterprise_activity_maeng_lee_dea_extension.csv", clear varnames(1) asdouble encoding(UTF-8) case(preserve)
keep if (technology=="ai" & inlist(outcome,"dea_efficiency","dea_efficiency_change")) | (technology=="combined" & exposure=="t2")
assert _N==16
export delimited exports/tables/appendix_A2.csv, replace
