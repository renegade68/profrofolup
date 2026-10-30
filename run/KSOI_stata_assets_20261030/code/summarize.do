version 16.1
clear all
set more off
set type double
use results/frontiers/scores.dta, clear
isid variant event_id
bysort event_id: assert _N==4
by event_id: egen byte common_finite=min(valid)
tempfile all scores
save `scores'
local first=1
foreach selection in all_finite common_finite common_no_flag common_known_no_flag {
    use `scores', clear
    gen byte invalid_all=!valid
    bysort variant group: egen long n_invalid=total(invalid_all)
    keep if valid
    if "`selection'"!="all_finite" keep if common_finite
    if inlist("`selection'","common_no_flag","common_known_no_flag") keep if both_no_flag
    if "`selection'"=="common_known_no_flag" keep if both_gap_known
    egen byte tag=tag(variant group firm_id)
    foreach v in CU FS TC {
        gen double log_`v'=ln(`v')
    }
    gen byte improved=TC>1+1e-8
    collapse (count) N=CU (sum) firms=tag F0 F3 (mean) log_* TC_improve_share=improved (max) invalid_all=n_invalid, by(variant group)
    foreach v in CU FS TC {
        gen double `v'_geo=exp(log_`v')
    }
    gen double CU_ratio_means=F0/F3
    gen str24 selection="`selection'"
    keep group selection variant N firms invalid_all CU_geo FS_geo TC_geo CU_ratio_means TC_improve_share
    order group selection variant N firms invalid_all CU_geo FS_geo TC_geo CU_ratio_means TC_improve_share
    if !`first' append using `all'
    save `all', replace
    local first=0
}
sort group selection variant
assert _N==48
export delimited results/frontiers/summary.csv, replace
display "ASSET_SUMMARY_COMPLETE"
