version 16.1
clear all
set more off
set type double
use results/frontiers/scores.dta, clear
keep if !valid
assert _N==2
keep event_id group
duplicates drop
assert _N==1
local eventid=event_id[1]
local group=group[1]
import delimited results/frontiers/events.csv, clear varnames(1) encoding(UTF-8) case(preserve) asdouble
quietly summarize capital if event_id=="`eventid'" & horizon==0, meanonly
assert r(N)==1
scalar targetK=r(mean)
quietly summarize employees if event_id=="`eventid'" & horizon==0, meanonly
scalar targetL=r(mean)
keep if group=="`group'" & horizon==0 & large_gap==0
sort event_id
mata:
/* Two independent certificates: full-reference LP, and exhaustive one-/two-
   point mixtures with a supporting line checked against every reference. */
real rowvector asset_certificate(real matrix z, real scalar kt, real scalar lt)
{
    class LinearProgram scalar q
    real rowvector sc,lambda
    real matrix zz
    real scalar n,i,j,w,k,best,bi,bj,bw,beta,alpha,slack,v,lp,primal
    n=rows(z);sc=colmax(z);zz=z:/sc
    q=LinearProgram();q.setMaxOrMin("min")
    q.setCoefficients(zz[,1]');q.setInequality(zz[,2]',lt/sc[2])
    q.setEquality(J(1,n,1),1);q.setBounds(J(1,n,0),J(1,n,.));q.setTol(1e-12);q.setMaxiter(1000)
    v=q.optimize();printf("Certificate primal LP converged=%g objective=%g\n",q.converged(),v)
    assert(q.converged());lp=v*sc[1];lambda=q.parameters()
    primal=max((0,abs(sum(lambda)-1),lambda*zz[,2]-lt/sc[2],-min(lambda)))
    printf("Certificate primal violation=%g\n",primal)
    assert(primal<1e-8)
    best=.;bi=.;bj=.;bw=.
    for(i=1;i<=n;i++) {
        if(z[i,2]<=lt & z[i,1]<best) {
            best=z[i,1];bi=i;bj=i;bw=1
        }
        for(j=i+1;j<=n;j++) {
            if(z[i,2]==z[j,2]) continue
            w=(lt-z[j,2])/(z[i,2]-z[j,2])
            if(w<0 | w>1) continue
            k=w*z[i,1]+(1-w)*z[j,1]
            if(k<best) {
                best=k;bi=i;bj=j;bw=w
            }
        }
    }
    assert(best<.)
    /* A zero-weight endpoint is a one-point optimum, not a supporting edge.
       Select a nonpositive dual slope valid against all reference points. */
    if(bw==0) {
        bi=bj;bw=1
    }
    if(bw==1) bj=bi
    printf("Mixture indices=%g,%g weight=%g points=(%g,%g),(%g,%g)\n",bi,bj,bw,z[bi,1],z[bi,2],z[bj,1],z[bj,2])
    beta=0
    if(bi!=bj) beta=(z[bi,1]-z[bj,1])/(z[bi,2]-z[bj,2])
    else if(z[bi,2]==lt) {
        for(j=1;j<=n;j++) {
            if(z[j,2]>lt) beta=min((beta,(z[j,1]-z[bi,1])/(z[j,2]-lt)))
        }
    }
    alpha=z[bi,1]-beta*z[bi,2]
    slack=min(z[,1]:-alpha:-beta*z[,2])
    printf("Certificate enumeration min=%g LP=%g slope=%g slack=%g gap=%g\n",best,lp,beta,slack,best-kt)
    assert(beta<=0 & slack > -1e-6)
    assert(abs(best-(alpha+beta*lt))<1e-6)
    assert(abs(best-lp)/max((1,best))<1e-8)
    assert(best>kt+1e-6)
    st_numscalar("cert_i",bi);st_numscalar("cert_j",bj);st_numscalar("cert_w",bw)
    return((kt,lt,lp,0,best,alpha,beta,slack,primal))
}
ct=asset_certificate((2,2\1,1\.5,3),.1,1)
assert(abs(ct[3]-1)<1e-8)
ct=asset_certificate((1,2\2,1),.1,1.5)
assert(abs(ct[3]-1.5)<1e-8)
cert=asset_certificate(st_data(.,("capital","employees")),st_numscalar("targetK"),st_numscalar("targetL"))
end
gen double mixture_weight=0
replace mixture_weight=scalar(cert_w) if _n==scalar(cert_i)
replace mixture_weight=mixture_weight+1-scalar(cert_w) if _n==scalar(cert_j)
keep if mixture_weight>0
keep event_id capital employees mixture_weight
export delimited validation/certificate_mixture.csv, replace
clear
set obs 1
foreach v in target_capital target_labor minimum_capital_at_target_labor solver_status mixture_minimum dual_intercept dual_labor_slope min_dual_slack max_scaled_primal_violation {
    gen double `v'=.
}
mata: st_store(.,.,cert)
gen str100 event_id="`eventid'"
order event_id
export delimited validation/certificate_details.csv, replace
keep event_id target_capital target_labor minimum_capital_at_target_labor solver_status
export delimited results/frontiers/infeasibility_certificate_local.csv, replace
display "ASSET_CERTIFICATE_COMPLETE"
