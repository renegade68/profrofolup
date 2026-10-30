version 16.1
import delimited "analysis/results/did_baseline.csv", clear varnames(1) asdouble encoding(UTF-8)
assert !(sample_ln_dea==1 & audit_past_ai==1 & treated==0)
keep if sample_ln_dea==1
mata:
z=st_data(.,tokens("stack treated overlap_trend ln_dea ln_employees capital_intensity ln_revenue ln_value_added d_dea d_employees d_revenue"))
ans=J(32,3,.)
for(g=2019;g<=2022;g++) {
    for(k=1;k<=8;k++) {
        out=J(2,2,.)
        for(t=0;t<=1;t++) {
            a=select(z,(z[,1]:==g):&(z[,2]:==t))
            w=a[,3];v=a[,k+3];assert(!hasmissing(a));assert(rows(a)>1)
            m=quadcross(w,v)/sum(w)
            variance=(quadcross(w,(v:-m):^2)/sum(w))*rows(a)/(rows(a)-1)
            out[t+1,.]=(m,variance)
        }
        ans[(g-2019)*8+k,.]=(g,k,(out[2,1]-out[1,1])/sqrt((out[2,2]+out[1,2])/2))
    }
}
end
clear
set obs 32
gen int cohort=.
gen byte covarid=.
gen double smd=.
mata: st_store(.,.,ans)
gen str24 covariate=""
local i=0
foreach x in ln_dea ln_employees capital_intensity ln_revenue ln_value_added d_dea d_employees d_revenue {
    local ++i
    replace covariate="`x'" if covarid==`i'
}
drop covarid
order cohort covariate smd
export delimited using "analysis/results/did_actual_balance.csv", replace
