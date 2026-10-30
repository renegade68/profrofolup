version 16.1
tempfile ev firms panel annual wide summary allsummary
import delimited "$S2/results/event_decomposition.csv", clear varnames(1) asdouble encoding(UTF-8) case(preserve)
keep if group=="ai_combined"
bysort firm_id (origin_year): gen long combined_events=_N
by firm_id: gen str32 origin_years=string(origin_year,"%4.0f") if _n==1
by firm_id: replace origin_years=origin_years[_n-1]+";"+string(origin_year,"%4.0f") if _n>1
save `ev'
by firm_id: keep if _n==_N
keep firm_id combined_events origin_years
sort firm_id
gen str8 local_label="S"+string(_n,"%03.0f")
assert _N==211
save `firms'
use "$S1/data/processed/strategy.dta", clear
keep firm_id year tech_* industry_mid ln_value_added ln_capital ln_employees ln_labor_productivity
save `panel'
use `firms', clear
expand 8
bysort firm_id: gen int year=2016+_n
merge 1:1 firm_id year using `panel', keep(master match)
egen byte missing_tech=rowmiss(tech_*)
egen byte count_tech=rowtotal(tech_*)
gen str1 state=cond(tech_ai==1,cond(count_tech>1,"C","A"),cond(count_tech==0,"N","O"))
replace state="U" if missing_tech>0
replace state="M" if _merge==1
drop _merge
gen byte active=inlist(state,"A","C")
gen byte combined=state=="C"
gen int first=year if active
gen int firstc=year if combined
bysort firm_id (year): egen int first_observed_AI=min(first)
by firm_id: egen int first_combo=min(firstc)
by firm_id: egen int annual_AI_years=total(active)
by firm_id: egen int annual_combination_years=total(combined)
by firm_id: gen byte prior=year==first_observed_AI & year>2017 & inlist(state[_n-1],"N","O")
by firm_id: egen byte prior_year_observed_nonAI=max(prior)
gen byte left_censored_first_AI=first_observed_AI==2017
by firm_id: gen str8 path_2017_2024=state if _n==1
by firm_id: replace path_2017_2024=path_2017_2024[_n-1]+state if _n>1
by firm_id: gen str1 state_2024=state[_N]
by firm_id: egen byte incomplete=max(year>=first_observed_AI & inlist(state,"M","U"))
by firm_id: egen byte any_exit=max(year>=first_observed_AI & !active)
gen str32 long_path="AI_continues_through_2024"
replace long_path="exit_and_reentry_active_2024" if any_exit & inlist(state_2024,"A","C")
replace long_path="inactive_in_2024_after_AI" if any_exit & !inlist(state_2024,"A","C")
replace long_path="incomplete_after_first_AI" if incomplete
save `annual'
preserve
keep firm_id local_label combined_events year state industry_mid ln_value_added ln_capital ln_employees ln_labor_productivity
order firm_id local_label combined_events year state industry_mid ln_value_added ln_capital ln_employees ln_labor_productivity
export delimited exports/tables/pathway_annual.csv, replace
restore
by firm_id: keep if _n==_N
keep firm_id local_label combined_events origin_years path_2017_2024 first_observed_AI first_combo left_censored_first_AI prior_year_observed_nonAI long_path state_2024 annual_AI_years annual_combination_years
order firm_id local_label combined_events origin_years path_2017_2024 first_observed_AI first_combo left_censored_first_AI prior_year_observed_nonAI long_path state_2024 annual_AI_years annual_combination_years
save `firms', replace
tempfile csv
export delimited "`csv'", replace
filefilter "`csv'" exports/tables/pathway_firms.csv, from("first_combo") to("first_observed_contemporaneous_combination") replace
use `annual', clear
keep firm_id year state ln_value_added ln_capital ln_employees
save `panel', replace
use `ev', clear
drop origin_years
expand 4
bysort event_id: gen byte offset=_n-1
gen int year=origin_year+offset
merge m:1 firm_id year using `panel', keep(master match) assert(match using) nogen
drop year
reshape wide state ln_value_added ln_capital ln_employees, i(event_id) j(offset)
merge m:1 firm_id using `firms', assert(match) nogen
gen str4 path_t_to_t3=state0+state1+state2+state3
gen str32 post_path="AI_exit_no_observed_reentry"
replace post_path="AI_exit_then_reentry" if (!inlist(state1,"A","C") & (inlist(state2,"A","C")|inlist(state3,"A","C"))) | (!inlist(state2,"A","C") & inlist(state3,"A","C"))
replace post_path="AI_continuous_t_to_t3" if inlist(state0,"A","C") & inlist(state1,"A","C") & inlist(state2,"A","C") & inlist(state3,"A","C")
replace post_path="AI_absent_at_baseline_t" if !inlist(state0,"A","C")
replace post_path="incomplete_observation" if strpos(path_t_to_t3,"M") | strpos(path_t_to_t3,"U")
gen int first_AI_relative_to_t=first_observed_AI-origin_year
rename (state0 state3) (baseline_state endpoint_state)
gen double value_added_ratio=exp(ln_value_added3-ln_value_added0)
gen double capital_ratio=exp(ln_capital3-ln_capital0)
gen double employees_ratio=exp(ln_employees3-ln_employees0)
gen double labor_productivity_ratio=value_added_ratio/employees_ratio
gen double group_frontier_output_ratio=value_added_ratio/CU
gen double F_difference=F0-F3
keep firm_id local_label event_id combined_events origin_year path_t_to_t3 post_path first_observed_AI first_AI_relative_to_t baseline_state endpoint_state prior_year_observed_nonAI F0 F3 G0 G3 H0 H3 CU FS TC value_added_ratio capital_ratio employees_ratio labor_productivity_ratio group_frontier_output_ratio F_difference
order firm_id local_label event_id combined_events origin_year path_t_to_t3 post_path first_observed_AI first_AI_relative_to_t baseline_state endpoint_state prior_year_observed_nonAI F0 F3 G0 G3 H0 H3 CU FS TC value_added_ratio capital_ratio employees_ratio labor_productivity_ratio group_frontier_output_ratio F_difference
sort firm_id origin_year
assert _N==412
count if combined_events==1
assert r(N)==77
export delimited exports/tables/pathway_events.csv, replace
save `ev', replace
keep if combined_events==1
egen byte firmtag=tag(post_path firm_id)
gen double logCU=ln(CU)
gen byte above=CU>1+1e-9
collapse (count) events=CU (sum) firms=firmtag (mean) F0_mean=F0 F3_mean=F3 G0_mean=G0 G3_mean=G3 logCU CU_above1_share=above (median) CU_median=CU, by(post_path)
gen double CU_ratio_of_means=F0_mean/F3_mean
gen double FS_ratio_of_means=G0_mean/G3_mean
gen double CU_geomean=exp(logCU)
assert _N==4
drop G0_mean G3_mean logCU
export delimited exports/tables/table12.csv, replace
