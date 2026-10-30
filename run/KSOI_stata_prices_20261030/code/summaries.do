version 16.1
clear all
set more off
set type double
tempfile base allsummary baseline
foreach folder in output_price capital_price {
    if "`folder'"=="output_price" {
        import delimited "results/output_price/full_reference_baseline_on_matched_events.csv", clear varnames(1) encoding(UTF-8) case(preserve) asdouble
        gen str24 variant="original_full_reference"
        save `baseline', replace
    }
    import delimited "results/`folder'/reestimated_events.csv", clear varnames(1) encoding(UTF-8) case(preserve) asdouble
    if "`folder'"=="output_price" append using `baseline'
    isid variant event_id
    assert abs(CU*FS/TC-1)<1e-8
    save `base', replace
    foreach weighting in event_equal firm_equal {
        use `base', clear
        bysort variant group firm_id: gen long repeats=_N
        by variant group firm_id: gen byte tag=_n==1
        bysort variant group: egen long firms=total(tag)
        by variant group: gen double w=1/_N
        if "`weighting'"=="firm_equal" replace w=1/(firms*repeats)
        foreach v in F0 F3 CU {
            gen double mean_`v'=w*`v'
        }
        foreach v in CU TC FS {
            gen double log_`v'=w*ln(`v')
        }
        gen double improvement_share=w*(TC>1+1e-8)
        collapse (count) events=F0 (max) firms (sum) mean_* log_* improvement_share, by(variant group)
        gen double CU_ratio_of_means=mean_F0/mean_F3
        rename mean_CU CU_mean_of_ratios
        foreach v in CU TC FS {
            gen double `v'_geomean=exp(log_`v')
        }
        gen str12 weighting="`weighting'"
        keep variant group weighting events firms CU_ratio_of_means CU_mean_of_ratios CU_geomean TC_geomean FS_geomean improvement_share
        if "`weighting'"=="firm_equal" append using `allsummary'
        save `allsummary', replace
    }
    sort variant group weighting
    order variant group weighting events firms CU_ratio_of_means CU_mean_of_ratios CU_geomean TC_geomean FS_geomean improvement_share
    local filename capital_frontier_summary
    if "`folder'"=="output_price" {
        local filename frontier_summary
    }
    if "`folder'"=="output_price" {
        * Original CSV header is 33 characters; Stata variables allow 32.
        tempfile summarycsv
        export delimited "`summarycsv'", replace
        filefilter "`summarycsv'" "results/`folder'/`filename'.csv", from("improvement_share") to("common_frontier_improvement_share") replace
    }
    else export delimited "results/`folder'/`filename'.csv", replace

    import delimited "results/`folder'/reestimated_events.csv", clear varnames(1) encoding(UTF-8) case(preserve) asdouble
    keep event_id group variant TC CU
    rename TC TC_
    rename CU CU_
    reshape wide TC_ CU_, i(event_id group) j(variant) string
    local before output_base
    local after output_price
    if "`folder'"=="capital_price" {
        local before capital_original
        local after capital_candidate
    }
    gen double dlog_TC=ln(TC_`after'/TC_`before')
    gen double dlog_CU=ln(CU_`after'/CU_`before')
    gen byte TC_direction_switch=(TC_`before'>1+1e-8)!=(TC_`after'>1+1e-8)
    if "`folder'"=="output_price" {
        gen byte CU_direction_switch=(CU_`before'>1+1e-8)!=(CU_`after'>1+1e-8)
        keep event_id group dlog_TC dlog_CU TC_direction_switch CU_direction_switch
        order event_id group dlog_TC dlog_CU TC_direction_switch CU_direction_switch
        export delimited "results/`folder'/price_event_changes.csv", replace
    }
    else {
        rename TC_direction_switch improvement_switch
        keep event_id group dlog_TC dlog_CU improvement_switch
        order event_id group dlog_TC dlog_CU improvement_switch
        export delimited "results/`folder'/capital_event_changes.csv", replace
    }
}
display "PRICE_SUMMARIES_COMPLETE"
