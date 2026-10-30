version 16.1
mata:
real matrix km_replicates(real matrix z, real matrix w)
{
    real matrix out
    real colvector surv, risk, fail
    real scalar h
    assert(cols(w)==rows(z)); assert(all(rowsum(w):==rows(z)))
    out=J(rows(w),7,.);surv=J(rows(w),1,1)
    for(h=0;h<=6;h++) {
        risk=w*(z[,1]:>=h)
        fail=w*((z[,1]:==h):&(z[,2]:==1))
        surv=surv:*(1:-editmissing(fail:/risk,0))
        out[,h+1]=1:-surv
    }
    return(out)
}
real scalar q_type7(real colvector x, real scalar p)
{
    real scalar z,lo,hi
    x=sort(x,1);z=(rows(x)-1)*p;lo=floor(z);hi=ceil(z)
    if(lo==hi) return(x[lo+1])
    return(x[lo+1]*(hi-z)+x[hi+1]*(z-lo))
}
real matrix ci7(real matrix draws, real scalar q)
{
    real scalar h
    real matrix ans
    ans=J(7,4,.)
    for(h=0;h<=6;h++) ans[h+1,.]=(q,h,q_type7(draws[,h+1],.025),q_type7(draws[,h+1],.975))
    return(ans)
}
real matrix native_weights(real scalar n, real scalar reps)
{
    real matrix w
    real colvector idx
    real scalar b,i
    w=J(reps,n,0)
    for(b=1;b<=reps;b++) {
        idx=runiformint(n,1,1,n)
        for(i=1;i<=n;i++) w[b,idx[i]]=w[b,idx[i]]+1
    }
    return(w)
}
end
set rng mt64
set seed 1985
mata: allci=J(0,4,.); allnative=J(0,4,.)
foreach label in 25 50 100 {
    local q=`label'/100
    use "$MIG/data/processed/km_spells.dta", clear
    keep if threshold==`q'
    sort firm_id
    isid firm_id
    mata: z=st_data(.,("duration","event")); expected=st_sdata(.,"firm_id")
    import delimited "$MIG/validation/shared_firms_`label'.csv", clear varnames(1) stringcols(_all)
    mata: assert(all(expected:==st_sdata(.,"firm_id")))
    import delimited "$MIG/validation/shared_weights_`label'.csv", clear varnames(1) asdouble
    mata: w=st_data(.,.); assert(rows(w)==1000); draws=km_replicates(z,w)
    mata: allci=allci\ci7(draws,`q')
    mata: native=km_replicates(z,native_weights(rows(z),1000)); allnative=allnative\ci7(native,`q')
    clear
    set obs 1000
    forvalues h=0/6 {
        gen double h`h'=.
    }
    mata: st_store(.,.,draws)
    gen int replication=_n
    gen double threshold=`q'
    export delimited using "$MIG/results/km_shared_replicates_`label'.csv", replace
}
clear
set obs 21
gen double gap_closed_fraction=.
gen int horizon_years=.
gen double bootstrap_ci_low=.
gen double bootstrap_ci_high=.
mata: st_store(.,.,allci)
merge 1:1 gap_closed_fraction horizon_years using "$MIG/data/processed/km_points.dta", assert(match) nogen
order gap_closed_fraction horizon_years eligible_events at_risk new_catchups km_cumulative_probability bootstrap_ci_low bootstrap_ci_high
sort gap_closed_fraction horizon_years
export delimited using "$MIG/results/enterprise_activity_ai_frontier_gap_duration_summary.csv", replace
clear
set obs 21
gen double gap_closed_fraction=.
gen int horizon_years=.
gen double bootstrap_ci_low=.
gen double bootstrap_ci_high=.
mata: st_store(.,.,allnative)
merge 1:1 gap_closed_fraction horizon_years using "$MIG/data/processed/km_points.dta", assert(match) nogen
order gap_closed_fraction horizon_years eligible_events at_risk new_catchups km_cumulative_probability bootstrap_ci_low bootstrap_ci_high
sort gap_closed_fraction horizon_years
export delimited using "$MIG/results/km_stata_rng_sensitivity.csv", replace
