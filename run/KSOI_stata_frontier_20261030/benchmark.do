version 16.1
clear all
set more off
global ROOT `"`c(pwd)'"'
capture log close _all
log using "$ROOT/logs/benchmark.log", text replace
do "$ROOT/code/frontier.mata"
import delimited "$ROOT/../KSOI_stata_migration_20261030/data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv", clear varnames(1) encoding(UTF-8) asdouble stringcols(1)
drop if missing(ln_capital,ln_employees,ln_value_added)
mata:
ref=exp(st_data(.,("ln_capital","ln_employees","ln_value_added")))
t=clock(c("current_time"),"hms")
f=ks_build(ref)
printf("FRONTIER: original=%g, pareto=%g, planes=%g, violation=%g\n",f.n_original,f.n_pareto,rows(f.planes),f.max_relative_violation)
s=ks_score(f,ref)
printf("POINTS: min=%g max=%g seconds=%g\n",min(s),max(s),(clock(c("current_time"),"hms")-t)/1000)
end
gen double mata_score=.
mata: st_store(.,"mata_score",s)
keep firm_id year mata_score
export delimited using "$ROOT/results/global_scores.csv", replace
display "BENCHMARK_COMPLETE"
log close
