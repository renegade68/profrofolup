version 16.1
clear all
set more off
set type double
* Match the corrected R summary: read the exported regression precision.
import delimited "analysis/results/enterprise_activity_maeng_lee_replication.csv", clear varnames(1) encoding(UTF-8) asdouble
isid end_year technology outcome vcetype exposure
assert _N==180
assert !missing(p_value) & inrange(p_value,0,1)
gen long original_order=_n
foreach scope in global family {
    local keys end_year
    local expected=90
    if "`scope'"=="family" {
        local keys end_year technology outcome vcetype
        local expected=3
    }
    egen long bhgroup=group(`keys')
    bysort bhgroup (p_value): assert _N==`expected'
    by bhgroup: gen double bhraw=min(1,p_value*_N/_n)
    by bhgroup: gen long reverse_order=-_n
    sort bhgroup reverse_order
    by bhgroup: gen double q_value_`scope'=bhraw if _n==1
    by bhgroup: replace q_value_`scope'=min(bhraw,q_value_`scope'[_n-1]) if _n>1
    assert q_value_`scope'>=p_value-1e-14 & q_value_`scope'<=1
    drop bhgroup bhraw reverse_order
}
sort original_order
drop original_order
export delimited "analysis/results/enterprise_activity_maeng_lee_replication_adjusted.csv", replace
tempfile wide
keep end_year technology outcome exposure vcetype coefficient std_error p_value observations
foreach v in coefficient std_error p_value observations {
    rename `v' `v'_
}
reshape wide coefficient_ std_error_ p_value_ observations_, i(end_year technology outcome exposure) j(vcetype) string
save `wide'
clear
* Constants are transcribed from the pinned corrected R summary in validation/.
input str12 technology str24 outcome str8 exposure double published_coefficient str8 published_significance
"combined" "sales_growth" "t2" .028 "p<.05"
"ai" "ln_revenue" "t2" .031 "p<.10"
"ai" "ln_labor_productivity" "t" .052 "p<.05"
"robot" "export_growth" "t1" .135 "p<.01"
"robot" "ln_labor_productivity" "t2" .039 "p<.10"
end
merge 1:m technology outcome exposure using `wide', keep(master match)
assert _merge==3
drop _merge
assert _N==10
isid end_year technology outcome exposure
order technology outcome exposure published_coefficient published_significance end_year
sort technology outcome exposure end_year
export delimited "analysis/results/enterprise_activity_maeng_lee_key_replication_comparison.csv", replace
display "APPENDIX_A1_SUMMARY_COMPLETE"
