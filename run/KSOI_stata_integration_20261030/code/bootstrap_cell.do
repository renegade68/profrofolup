version 16.1
* Called with data containing cluster and a0,a1[,b0,b1]. Saves results in r().
args key
tempfile aggregate
local values a0 a1
capture confirm variable b0
if !_rc local values a0 a1 b0 b1
foreach v of local values {
    assert !missing(`v') & `v'>0
}
local n=_N
collapse (sum) `values', by(cluster)
sort cluster
local clusters=_N
mata: x=st_data(.,tokens("`values'"));labels=st_sdata(.,"cluster");point=colsum(x)
save `aggregate'
export delimited using "$CI_OUT/aggregate_`key'.csv", replace
import delimited "validation/clusters_`key'.csv", clear varnames(1) stringcols(_all) encoding(UTF-8)
mata: assert(all(labels:==st_sdata(.,"cluster")))
import delimited "validation/weights_`key'.csv", clear varnames(1) asdouble encoding(UTF-8)
mata: w=st_data(.,.); assert(rows(w)==10000); draws=ci_ratios(x,w)
clear
set obs 10000
gen double ratio=.
if "`values'"=="a0 a1 b0 b1" {
    gen double control=.
    gen double difference=.
}
mata: st_store(.,.,draws)
gen int rep=_n
order rep
export delimited using "$CI_OUT/draws_`key'.csv", replace
mata: st_numscalar("ci_point",point[1]/point[2]);st_numscalar("ci_low",ci_quantile(draws[,1],.025));st_numscalar("ci_high",ci_quantile(draws[,1],.975))
if "`values'"=="a0 a1 b0 b1" {
    mata: st_numscalar("ci_control",point[3]/point[4]);st_numscalar("ci_control_low",ci_quantile(draws[,2],.025));st_numscalar("ci_control_high",ci_quantile(draws[,2],.975))
    mata: st_numscalar("ci_difference",point[3]/point[4]-point[1]/point[2]);st_numscalar("ci_difference_low",ci_quantile(draws[,3],.025));st_numscalar("ci_difference_high",ci_quantile(draws[,3],.975))
}
scalar ci_events=`n'
scalar ci_clusters=`clusters'
