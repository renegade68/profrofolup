version 16.1
clear all
set more off
set type double
do code/frontier.mata
do code/decompose.mata
tempfile allout allcap
foreach variant in output_base output_price capital_original capital_candidate {
    local folder output_price
    local kvar capital
    local yvar `variant'
    if inlist("`variant'","capital_original","capital_candidate") {
        local folder capital_price
        local yvar output_price
        if "`variant'"=="capital_candidate" local kvar capital_candidate
    }
    import delimited "results/`folder'/reference_panel.csv", clear varnames(1) encoding(UTF-8) case(preserve) asdouble
    mata: ref=st_data(.,("`kvar'","employees","`yvar'")); globalf=ks_build(ref)
    import delimited "results/`folder'/event_panel.csv", clear varnames(1) encoding(UTF-8) case(preserve) asdouble
    egen long fid=group(firm_id)
    gen byte group_id=cond(group=="ai_combined",1,cond(group=="ai_none",2,3))
    assert inlist(group,"ai_combined","ai_none","ai_pure")
    sort group_id event_id horizon
    mata: cc=ks_cells(st_data(.,("`kvar'","employees","`yvar'")),st_data(.,"group_id"),st_data(.,"horizon"),st_data(.,"fid"),st_sdata(.,"event_id")); es=ks_event_scores(cc,globalf)
    keep if horizon==0
    foreach v in F0 F3 H0 H3 G0 G3 CU FS TC {
        gen double `v'=.
    }
    mata: st_store(.,tokens("F0 F3 H0 H3 G0 G3 CU FS TC"),es[,3..11])
    assert min(F0,F3,H0,H3,G0,G3)>=1-1e-7
    assert !missing(F0,F3,H0,H3,G0,G3,CU,FS,TC)
    assert abs(CU*FS/TC-1)<1e-8
    gen str24 variant="`variant'"
    keep variant event_id firm_id origin_year group F0 F3 H0 H3 G0 G3 CU TC FS
    order variant event_id firm_id origin_year group F0 F3 H0 H3 G0 G3 CU TC FS
    if "`folder'"=="output_price" {
        if "`variant'"=="output_price" append using `allout'
        save `allout', replace
    }
    else {
        if "`variant'"=="capital_candidate" append using `allcap'
        save `allcap', replace
    }
    sort variant group event_id
    export delimited "results/`folder'/reestimated_events.csv", replace
}
display "PRICE_FRONTIERS_COMPLETE"
