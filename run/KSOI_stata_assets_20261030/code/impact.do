version 16.1
clear all
set more off
set type double
tempfile assets baseline pairs allsummary
use results/audit/assets.dta, clear
keep firm_id year large_gap usable
isid firm_id year
save `assets'
import delimited data/processed/baseline_events.csv, clear varnames(1) encoding(UTF-8) case(preserve) asdouble
save `baseline'
keep event_id firm_id group origin_year
expand 2, gen(copy)
gen byte horizon=3*copy
gen int year=origin_year+horizon
merge m:1 firm_id year using `assets', keep(master match) assert(match using) nogen
keep event_id firm_id group origin_year horizon large_gap usable
reshape wide large_gap usable, i(event_id firm_id group origin_year) j(horizon)
rename (large_gap0 large_gap3) (large_gap_t0 large_gap_t3)
gen byte any_large_gap=large_gap_t0 | large_gap_t3
gen byte both_components_usable=usable0 & usable3
merge 1:1 event_id using `baseline', assert(match) nogen
keep event_id firm_id group origin_year large_gap_t0 large_gap_t3 any_large_gap both_components_usable F0 F3 TC CU
order event_id firm_id group origin_year large_gap_t0 large_gap_t3 any_large_gap both_components_usable F0 F3 TC CU
sort group event_id
assert _N==13418
save `pairs'
export delimited results/audit/event_exposure_local.csv, replace
local first=1
foreach dimension in group origin_year {
    foreach selection in all no_large_gap both_components_usable {
        use `pairs', clear
        if "`selection'"=="no_large_gap" keep if !any_large_gap
        if "`selection'"=="both_components_usable" keep if both_components_usable
        if "`dimension'"=="group" gen str24 stratum=group
        else gen str24 stratum=string(origin_year,"%4.0f")
        egen byte tag=tag(stratum firm_id)
        gen double log_TC=ln(TC)
        collapse (count) events=CU (sum) firms=tag large_gap_events=any_large_gap F0 F3 (mean) log_TC CU_mean_of_ratios=CU, by(stratum)
        gen double TC_geomean=exp(log_TC)
        gen double CU_ratio_of_means=F0/F3
        gen str12 dimension="`dimension'"
        gen str24 selection="`selection'"
        keep dimension stratum selection events firms large_gap_events TC_geomean CU_ratio_of_means CU_mean_of_ratios
        order dimension stratum selection events firms large_gap_events TC_geomean CU_ratio_of_means CU_mean_of_ratios
        if !`first' append using `allsummary'
        save `allsummary', replace
        local first=0
    }
}
sort dimension stratum selection
export delimited results/audit/fixed_score_selection_diagnostic.csv, replace
display "ASSET_IMPACT_COMPLETE"
