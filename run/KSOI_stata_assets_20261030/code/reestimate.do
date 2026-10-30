version 16.1
clear all
set more off
set type double
do code/frontier.mata
do code/feasibility.mata
tempfile ref endpoints allscores allstatus counts
import delimited results/frontiers/reference.csv, clear varnames(1) encoding(UTF-8) case(preserve) asdouble
save `ref'
import delimited results/frontiers/events.csv, clear varnames(1) encoding(UTF-8) case(preserve) asdouble
save `endpoints'
postfile COUNT str24 variant str2 reference str12 group long N long reduced long gap_unknown using `counts', replace
local first=1
foreach variant in baseline_all filtered_all baseline_2019plus filtered_2019plus {
    local filtered=substr("`variant'",1,8)=="filtered"
    local recent=strpos("`variant'","2019plus")>0
    use `ref', clear
    if `filtered' keep if large_gap==0
    if `recent' keep if year>=2019
    mata: globalf=ks_build(st_data(.,("capital","employees","output"))); st_numscalar("reduced",globalf.n_pareto)
    quietly count if gap_known==0
    post COUNT ("`variant'") ("H") ("all") (_N) (scalar(reduced)) (r(N))
    foreach g in ai_combined ai_none ai_pure {
        use `endpoints', clear
        keep if group=="`g'"
        sort horizon event_id
        mata: z=st_data(.,("capital","employees","output"));h=st_data(.,"horizon");flag=st_data(.,"large_gap");known=st_data(.,"gap_known");e=st_sdata(.,"event_id")
        mata: ia=selectindex(h:==0);ib=selectindex(h:==3);assert(all(e[ia]:==e[ib]));a=z[ia,.];b=z[ib,.]
        mata: ar=select(a,(`filtered'==0):|(flag[ia]:==0));br=select(b,(`filtered'==0):|(flag[ib]:==0));fa=ks_build(ar);fb=ks_build(br)
        mata: f0=asset_score(fa,a);f3=asset_score(fb,b);h0=asset_score(globalf,a);h3=asset_score(globalf,b)
        mata: st_numscalar("na",rows(ar));st_numscalar("nb",rows(br));st_numscalar("ra",fa.n_pareto);st_numscalar("rb",fb.n_pareto)
        mata: st_numscalar("ua",sum((known[ia]:==0):&((`filtered'==0):|(flag[ia]:==0))));st_numscalar("ub",sum((known[ib]:==0):&((`filtered'==0):|(flag[ib]:==0))))
        post COUNT ("`variant'") ("F0") ("`g'") (scalar(na)) (scalar(ra)) (scalar(ua))
        post COUNT ("`variant'") ("F3") ("`g'") (scalar(nb)) (scalar(rb)) (scalar(ub))
        mata: scores=(f0[,1],f3[,1],h0[,1],h3[,1]);feas=(f0[,2],f3[,2],h0[,2],h3[,2]);no_flag=(flag[ia]:==0):&(flag[ib]:==0);known_both=(known[ia]:==1):&(known[ib]:==1)
        keep if horizon==0
        foreach v in F0 F3 H0 H3 {
            gen double `v'=.
            gen byte `v'_feasible=.
        }
        gen byte both_no_flag=.
        gen byte both_gap_known=.
        mata: st_store(.,tokens("F0 F3 H0 H3"),scores);st_store(.,tokens("F0_feasible F3_feasible H0_feasible H3_feasible"),feas);st_store(.,"both_no_flag",no_flag);st_store(.,"both_gap_known",known_both)
        gen str24 variant="`variant'"
        gen byte valid=F0_feasible & F3_feasible & H0_feasible & H3_feasible
        preserve
        keep variant event_id F0_feasible F3_feasible H0_feasible H3_feasible valid
        if !`first' append using `allstatus'
        save `allstatus', replace
        restore
        gen double G0=H0/F0
        gen double G3=H3/F3
        gen double CU=F0/F3
        gen double TC=H0/H3
        gen double FS=G0/G3
        assert abs(CU*FS/TC-1)<1e-8 if valid
        assert !missing(F0,F3,H0,H3,G0,G3,CU,TC,FS) if valid
        assert min(G0,G3)>1-1e-7 if valid
        keep variant event_id group origin_year firm_id both_no_flag both_gap_known F0 F3 H0 H3 G0 G3 CU TC FS valid
        order variant event_id group origin_year firm_id both_no_flag both_gap_known F0 F3 H0 H3 G0 G3 CU TC FS valid
        if !`first' append using `allscores'
        save `allscores', replace
        local first=0
    }
}
postclose COUNT
use `allscores', clear
sort variant group event_id
save results/frontiers/scores.dta, replace
export delimited results/frontiers/scores.csv, replace
keep if !valid
export delimited results/frontiers/nonfinite_events_local.csv, replace
use `allstatus', clear
sort variant event_id
export delimited results/frontiers/feasibility.csv, replace
use `counts', clear
export delimited results/frontiers/reference_counts.csv, replace
display "ASSET_FRONTIERS_COMPLETE"
