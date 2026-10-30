version 16.1
clear all
set more off

* Usage: do analysis/build_bogetoft_matched_ai_stack.do ai_pure|ai_combined
* Deterministic 1:1 nearest-neighbor matching without replacement.
* Exact match: origin year. Distance: year-standardized log capital and labor.
args target
if !inlist("`target'", "ai_pure", "ai_combined") {
    display as error "target must be ai_pure or ai_combined"
    exit 198
}

capture mkdir "analysis/results/bogetoft_rebuild"
capture log close
log using "analysis/results/bogetoft_rebuild/match_`target'.log", text replace

import delimited using "data/processed/enterprise_activity_bogetoft_t3_stack.csv", ///
    varnames(1) encoding(utf8) clear
keep if family == "ai" & horizon == 0 & inlist(group, "`target'", "ai_none")
isid event_id
assert capital > 0 & employees > 0
gen double ln_capital = ln(capital)
gen double ln_employees = ln(employees)

foreach v in ln_capital ln_employees {
    bysort origin_year: egen double mean_`v' = mean(`v')
    bysort origin_year: egen double sd_`v' = sd(`v')
    assert sd_`v' > 0
    gen double z_`v' = (`v' - mean_`v') / sd_`v'
}

sort origin_year group event_id
gen str40 matched_control_event_id = ""
gen double match_distance = .

mata:
void _bogetoft_greedy_match(string scalar target)
{
    string colvector g, id, out
    real colvector yr, tidx, cidx, used, dout, candidates, dd
    real matrix z, cz
    real scalar i, pick

    g = st_sdata(., "group")
    id = st_sdata(., "event_id")
    yr = st_data(., "origin_year")
    z = st_data(., ("z_ln_capital", "z_ln_employees"))
    tidx = selectindex(g :== target)
    cidx = selectindex(g :== "ai_none")
    used = J(rows(cidx), 1, 0)
    out = J(rows(g), 1, "")
    dout = J(rows(g), 1, .)
    cz = z[cidx, .]

    for (i=1; i<=rows(tidx); i++) {
        candidates = selectindex((yr[cidx] :== yr[tidx[i]]) :& (used :== 0))
        if (rows(candidates) == 0) _error(3498, "No unused exact-year control")
        dd = rowsum((cz[candidates, .] :- z[tidx[i], .]):^2)
        pick = candidates[selectindex(dd :== min(dd))[1]]
        out[tidx[i]] = id[cidx[pick]]
        dout[tidx[i]] = sqrt(min(dd))
        used[pick] = 1
    }
    st_sstore(., "matched_control_event_id", out)
    st_store(., "match_distance", dout)
}
_bogetoft_greedy_match("`target'")
end

keep if group == "`target'"
assert matched_control_event_id != ""
isid matched_control_event_id
count
local pairs = r(N)
quietly summarize match_distance, detail
display as text "Matched pairs: " as result `pairs'
display as text "Distance median/p95/max: " as result ///
    %9.4f r(p50) " / " %9.4f r(p95) " / " %9.4f r(max)

keep event_id matched_control_event_id origin_year match_distance ///
    ln_capital ln_employees
rename event_id treated_event_id
export delimited using ///
    "analysis/results/bogetoft_rebuild/match_`target'_crosswalk.csv", replace
tempfile crosswalk mapping
save `crosswalk'

* Convert the crosswalk into a source-event mapping, then attach both endpoints.
preserve
keep treated_event_id matched_control_event_id origin_year match_distance
rename treated_event_id source_event_id
gen str12 role = "treatment"
save `mapping'
restore
keep treated_event_id matched_control_event_id origin_year match_distance
rename matched_control_event_id source_event_id
gen str12 role = "control"
append using `mapping'
isid source_event_id
save `mapping', replace

import delimited using "data/processed/enterprise_activity_bogetoft_t3_stack.csv", ///
    varnames(1) encoding(utf8) clear
keep if family == "ai"
rename event_id source_event_id
merge m:1 source_event_id using `mapping', keep(match) nogen
rename source_event_id event_id
rename group original_group
gen str16 comparison = "`target'"
isid event_id horizon
sort event_id horizon
by event_id: assert _N == 2
by event_id: assert horizon[1] == 0 & horizon[2] == 3
sort role event_id horizon
export delimited using ///
    "data/processed/enterprise_activity_bogetoft_matched_`target'_t3_stack.csv", replace

log close
* Return to integration driver; original batch exit removed.
