version 16.1
clear all
set more off
global ROOT `"`c(pwd)'"'
capture log close _all
log using "$ROOT/logs/independent_validation.log", text replace
do "$ROOT/code/frontier.mata"
set rng mt64
set seed 20261030
mata:
z=(1,1,1\2,2,3\1,2,1.5\2,1,2)
f=ks_build(z)
assert(max(abs(ks_score(f,z):-1))<1e-12)
x=(3,1,1\1,3,1\3,3,1\1.5,1.5,1)
assert(max(abs(ks_score(f,x):-(2\1.5\3\2)))<1e-12)
assert(max(abs(ks_score(ks_build(z\z\(3,3,.5)),x):-ks_score(f,x)))<1e-12)
assert(max(abs(ks_score(ks_build(z:*(1e-6,1e6,1e3)),x:*(1e-6,1e6,1e3)):-ks_score(f,x)))<1e-12)
assert(ks_score(ks_build((1,1,2)),(3,2,1))==2)
assert(max(abs(ks_score(ks_build((1,2,2\2,1,2)),(1.5,1.5,1\3,3,1)):-2))<1e-12)
printf("Analytic/free-disposal/duplicates/dominance/unit-scale/degenerate tests: PASS\n")
end
capture mata: ks_score(f,(.5,.5,1))
assert _rc==3498
mata:
diagnostics=J(0,6,.)
void ks_check(real matrix z, real matrix x, real scalar label)
{
    external real matrix diagnostics
    real matrix lp
    real colvector score,error
    struct ks_front scalar f
    f=ks_build(z);score=ks_score(f,x);lp=ks_lp(z,x)
    assert(all(lp[,2]:==1));assert(!hasmissing(lp))
    error=abs(score-lp[,1]):/rowmax((J(rows(lp),1,1),abs(lp[,1])))
    diagnostics=diagnostics\(J(rows(x),1,label),score,lp[,1],error,lp[,3],lp[,4])
    printf("Independent LP cell %g: %g evaluations, max error %g\n",label,rows(x),max(error))
    assert(max(error)<1e-6)
}
real colvector ks_probes(real matrix z)
{
    real colvector idx,q
    real scalar k
    idx=round(rangen(1,rows(z),16))
    for(k=1;k<=3;k++) {
        q=order(z,k);idx=idx\q[1]\q[rows(z)]
    }
    return(uniqrows(idx))
}
for(k=1;k<=10;k++) {
    z=runiform(30,3):+.1
    x=z\(runiform(10,2):+1.1,J(10,1,.5))
    ks_check(z,x,-k)
}
end
import delimited "$ROOT/../KSOI_stata_migration_20261030/data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv", clear varnames(1) asdouble encoding(UTF-8) stringcols(1)
drop if missing(ln_capital,ln_employees,ln_value_added)
mata: z=exp(st_data(.,("ln_capital","ln_employees","ln_value_added")));ks_check(z,z[ks_probes(z),.],0)
import delimited "$ROOT/../KSOI_stata_migration_20261030/data/processed/enterprise_activity_bogetoft_t3_stack.csv", clear varnames(1) asdouble encoding(UTF-8) stringcols(1 2)
keep if family=="ai"
gen byte cell=cond(group=="ai_combined",1,cond(group=="ai_none",2,3))*2-(horizon==0)
mata:
z=st_data(.,("capital","employees","value_added"));cell=st_data(.,"cell")
for(k=1;k<=6;k++) {
    a=select(z,cell:==k)
    ks_check(a,a[ks_probes(a),.],k)
}
st_local("n",strofreal(rows(diagnostics)))
end
clear
set obs `n'
foreach v in cell plane_score lp_score relative_error scaled_lp_violation formulation {
    gen double `v'=.
}
mata: st_store(.,.,diagnostics)
export delimited using "$ROOT/validation/independent_lp.csv", replace
display "INDEPENDENT_VALIDATION_COMPLETE"
log close
