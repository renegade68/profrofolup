version 16.1
clear all
set more off
set type double
global ROOT `"`c(pwd)'"'
tempfile selected allraw
use data/processed/selected.dta, clear
keep if industry_large=="C" & inrange(year,2019,2024) & firm_id!=""
keep year source_row firm_id tangible_assets
isid year source_row
isid firm_id year
save `selected'
forvalues y=2019/2024 {
    local zid=cond(`y'==2019,43412,82803)
    import delimited "$ROOT/../KSOI_stata_migration_20261030/data/raw/`zid'/`y'.csv", clear varnames(nonames) rowrange(2) stringcols(_all) encoding(windows-949) bindquote(strict)
    gen long source_row=_n+1
    do code/metadata/columns_`y'.do
    if `y'>2019 append using `allraw'
    save `allraw', replace
}
merge 1:1 year source_row using `selected', keep(using match)
assert _merge==3
assert total==tangible_assets
drop _merge tangible_assets
assert _N==37625
foreach v in total component_sum asset1 asset2 asset3 asset4 asset5 asset6 asset7 asset8 {
    assert `v'==floor(`v') & abs(`v')<2^53 if !missing(`v')
}
gen double residual=component_sum-total
gen byte valid=complete & !missing(total) & total>0
gen double relative_gap=abs(residual)/total if valid
gen double tolerance=max(1,abs(total)*1e-8)
gen str32 status="missing_or_nonpositive_total"
replace status="within_tolerance" if valid & abs(residual)<=tolerance
replace status="components_exceed_total" if valid & residual>tolerance
replace status="components_below_total" if valid & residual < -tolerance
egen double max_component=rowmax(asset*)
egen double min_component=rowmin(asset*)
replace status="all_components_zero" if valid & abs(residual)>tolerance & max_component==0 & min_component==0
gen byte large_gap=valid & abs(residual)*100>total
assert abs(residual)*100<2^53 if valid
gen byte usable=status=="within_tolerance" & !has_negative_component & !large_gap
sort year source_row
save results/audit/assets.dta, replace
preserve
keep year firm_id source_row total component_sum residual relative_gap complete status has_negative_component asset*
rename (asset1 asset2 asset3 asset4 asset5 asset6 asset7 asset8) (토지 건물 구축물 기계장치 선박차량운반구 기타 건설중인자산 선박항공기)
order year firm_id source_row total component_sum residual relative_gap complete status has_negative_component 토지 건물 구축물 기계장치 선박차량운반구 기타 건설중인자산 선박항공기
export delimited results/audit/asset_records_local.csv, replace
gsort -relative_gap year source_row
keep if !missing(relative_gap) & relative_gap>.01
keep in 1/50
export delimited results/audit/review_priority_local.csv, replace
restore
preserve
foreach s in missing_or_nonpositive_total within_tolerance all_components_zero components_exceed_total components_below_total {
    gen long `s'=status=="`s'"
}
collapse (count) N=source_row (sum) missing_or_nonpositive_total within_tolerance all_components_zero components_exceed_total components_below_total gap_over_1pct=large_gap negative_component_rows=has_negative_component, by(year)
export delimited results/audit/year_diagnostics.csv, replace
restore
preserve
keep year source_row asset*
reshape long asset, i(year source_row) j(asset_id)
keep if asset<0
rename asset value
gen str24 asset=""
local names "토지 건물 구축물 기계장치 선박차량운반구 기타 건설중인자산 선박항공기"
forvalues i=1/8 {
    local a : word `i' of `names'
    replace asset="`a'" if asset_id==`i'
}
collapse (count) N=source_row, by(year asset value)
order year asset value N
export delimited results/audit/negative_values.csv, replace
restore
egen long pid=group(firm_id)
xtset pid year
gen double previous_total=L.total
gen double next_total=F.total
gen byte bad=inlist(status,"all_components_zero","components_exceed_total","components_below_total")
tempfile hypotheses
postfile H int year str32 hypothesis long eligible long matches using `hypotheses', replace
forvalues y=2019/2024 {
    foreach name in sum_equals_previous_total sum_equals_next_total residual_equals_CIP negative_component all_components_zero {
        gen byte eligible=bad & year==`y'
        gen byte hit=0
        if "`name'"=="sum_equals_previous_total" | "`name'"=="sum_equals_next_total" {
            local t previous_total
            if "`name'"=="sum_equals_next_total" local t next_total
            replace eligible=eligible & !missing(`t')
            replace hit=eligible & abs(component_sum-`t')<=max(1,abs(`t')*1e-8)
        }
        else if "`name'"=="residual_equals_CIP" {
            replace eligible=eligible & !missing(asset7)
            replace hit=eligible & abs(residual-asset7)<=1
        }
        else if "`name'"=="negative_component" replace hit=eligible & has_negative_component
        else replace hit=eligible & status=="all_components_zero"
        quietly count if eligible
        local n=r(N)
        quietly count if hit
        post H (`y') ("`name'") (`n') (r(N))
        drop eligible hit
    }
}
postclose H
use `hypotheses', clear
export delimited results/audit/diagnostic_hypotheses.csv, replace
import delimited code/metadata/label_alignment.csv, clear varnames(1) encoding(UTF-8) case(preserve) stringcols(3 4 5)
assert _N==52 & csv_header==stata_label & exact_match=="True"
export delimited results/audit/label_alignment.csv, replace
display "RAW_ASSET_AUDIT_COMPLETE"
