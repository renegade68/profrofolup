version 16.1
tempfile selected bridge
local first 1
foreach zid in 75764 86378 43412 82803 {
    capture mkdir "$MIG/data/raw/`zid'"
    cd "$MIG/data/raw/`zid'"
    * Same CSV bytes, ASCII member names: legacy source ZIP names fail r(692).
    unzipfile "$MIG/data/raw/normalized_`zid'.zip", replace
    local firstyear = cond(`zid'==75764,2006,cond(`zid'==86378,2010,cond(`zid'==43412,2015,2020)))
    local lastyear = cond(`zid'==75764,2009,cond(`zid'==86378,2014,cond(`zid'==43412,2019,2024)))
    forvalues yr=`firstyear'/`lastyear' {
        local files : dir "." files "`yr'*.csv"
        local count : word count `files'
        assert `count'==1
        local f : word 1 of `files'
        import delimited using `"`f'"', clear varnames(nonames) rowrange(2) stringcols(_all) encoding(windows-949) bindquote(strict)
        quietly do "$MIG/code/metadata/columns_`yr'.do"
        if !`first' append using `selected'
        save `selected', replace
        local first 0
    }
}
cd "$MIG"
use `selected', clear
sort year source_row
assert _N==236851
isid source_zip_id year source_row
preserve
keep if panel_key!="" & br_panel_key!=""
keep panel_key br_panel_key
duplicates drop
bysort panel_key: gen int nlinks=_N
count if nlinks!=1
assert r(N)==0
keep if nlinks==1
drop nlinks
rename br_panel_key mapped_br_key
assert _N==13268
save `bridge'
restore
merge m:1 panel_key using `bridge', keep(master match) nogen
gen str82 firm_id = ""
replace firm_id="B:"+br_panel_key if br_panel_key!=""
replace firm_id="B:"+mapped_br_key if firm_id=="" & mapped_br_key!=""
replace firm_id="P:"+panel_key if firm_id=="" & panel_key!=""
drop mapped_br_key
egen double employees_total_constructed = rowtotal(employees_regular employees_temporary employees_other), missing
gen double operating_profit_constructed = revenue-cost_of_sales-selling_admin
gen double value_added_constructed = operating_profit_constructed+labor_cost+rent+depreciation+taxes
foreach k in ai robot {
    gen byte `k'_active = .
    replace `k'_active = 0 if `k'_use==2 | `k'_stage==1 | inlist(fourth_industry_use,1,2)
    replace `k'_active = 1 if `k'_use==1 | (`k'_stage>1 & `k'_stage<.)
    gen str24 `k'_stage_canonical = ""
    replace `k'_stage_canonical = "none" if `k'_active==0
    local names1 "product_development marketing production_process organization"
    local names2 "none product_development marketing production_process organization sales"
    local names3 "none product_development production_process sales marketing organization"
    forvalues regime=1/3 {
        local n : word count `names`regime''
        forvalues j=1/`n' {
            local s : word `j' of `names`regime''
            replace `k'_stage_canonical = "`s'" if `k'_active==1 & int(`k'_stage)==`j' & cond(`regime'==1,year<=2018,cond(`regime'==2,inrange(year,2019,2020),year>=2021))
        }
    }
}
gen byte ai_or_robot_active=.
replace ai_or_robot_active=0 if ai_active==0 & robot_active==0
replace ai_or_robot_active=1 if ai_active==1 | robot_active==1
sort year source_row
preserve
keep source_zip_id year source_row raw_*_use raw_*_stage
foreach k in iot cloud bigdata mobile ai blockchain 3dp robot arvr {
    * Overall response comes from the selected raw panel on merge below.
}
save "$MIG/data/processed/raw_technology.dta", replace
restore
drop raw_*
order year source_zip_id source_row panel_key br_panel_key region industry_large industry_mid employees_regular employees_temporary employees_other tangible_assets revenue cost_of_sales selling_admin materials labor_cost rent depreciation taxes pretax_profit direct_exports fourth_industry_use ai_use robot_use ai_stage robot_stage ai_development robot_development firm_id employees_total_constructed operating_profit_constructed value_added_constructed ai_active robot_active ai_or_robot_active ai_stage_canonical robot_stage_canonical
save "$MIG/data/processed/selected.dta", replace
export delimited using "$MIG/data/processed/enterprise_activity_selected_panel_2006_2024.csv", replace
