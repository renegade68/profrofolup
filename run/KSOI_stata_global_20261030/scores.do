version 16.1
clear all
set more off
set type float
* The pinned st0444 plugin requires x86_64 Stata on this machine.
foreach job in no_trim global_trim industry_year_trim operating_crs income_vrs income_crs joint_trim pilot_global {
    do jobs/`job'.do
}
display "STATA_GLOBAL_SCORES_COMPLETE"
