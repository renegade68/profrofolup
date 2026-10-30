version 16.1
set scheme s2color
graph set window fontface "AppleGothic"
import delimited exports/figures/figure01_data.csv, clear varnames(1) asdouble encoding(UTF-8) case(preserve)
gen double alone=100*ai_only/complete_responses
gen double combined=100*ai_with_other/complete_responses
graph bar alone combined, over(year, label(labsize(small))) stack ///
    bar(1,color("75 85 99")) bar(2,color("43 111 142")) ///
    ytitle("제조업 기업-연도 중 비율(%)") ylabel(0(1)6,angle(0)) ///
    legend(order(1 "AI 단독" 2 "AI+보완기술") rows(1) position(6)) ///
    graphregion(color(white)) plotregion(color(white)) xsize(8.5) ysize(5) name(fig1,replace)
graph save exports/figures/figure01.gph, replace
graph export exports/figures/figure01.png, replace width(2400)
import delimited exports/figures/figure02_data.csv, clear varnames(1) asdouble encoding(UTF-8) case(preserve)
drop strategy
strategy_names
gen byte pos=7-display_order
label define strategypos 6 "미활용" 5 "AI 없는 타 기술" 4 "AI 단독" 3 "AI+디지털" 2 "AI+물리" 1 "AI+교차결합", replace
label values pos strategypos
twoway (rcap dea_p25 dea_p75 pos, horizontal lcolor(gs8)) ///
    (scatter pos dea_median_output_inefficiency, mcolor("43 111 142") msymbol(O)), ///
    ylabel(1(1)6, valuelabel angle(0) labsize(medsmall)) ///
    xtitle("산출지향 DEA 점수: 중앙값과 사분위범위") ytitle("") ///
    xscale(range(0 22)) xlabel(0(5)20) xline(1,lpattern(dot) lcolor(gs10)) legend(off) graphregion(color(white)) plotregion(color(white)) ///
    xsize(8.5) ysize(5) name(fig2,replace)
graph save exports/figures/figure02.gph, replace
graph export exports/figures/figure02.png, replace width(2400)
import delimited exports/figures/figure03_data.csv, clear varnames(1) asdouble encoding(UTF-8) case(preserve)
gen byte panel=.
local i=0
foreach v in ln_dea ln_employees ln_value_added ln_revenue ln_labor_productivity {
    local ++i
    replace panel=`i' if outcome_code=="`v'"
}
label define outcome 1 "DEA 산출 비효율" 2 "고용" 3 "부가가치" 4 "매출" 5 "노동생산성", replace
label values panel outcome
twoway (rcap ci_low ci_high event_time, lcolor("43 111 142")) ///
    (scatter coefficient event_time, mcolor("43 111 142") msymbol(O)), ///
    by(panel,cols(2) yrescale note("") legend(off) graphregion(color(white))) ///
    ylabel(,angle(0) labsize(small) format(%4.2f)) ///
    xlabel(-3 -2 0 1 2) xline(-.5,lpattern(dot) lcolor(gs10)) yline(0,lcolor(gs10)) ///
    xtitle("최초 관측 AI 활용 대비 연도") ytitle("로그포인트 추정치와 95% 구간") legend(off) ///
    graphregion(color(white)) plotregion(color(white)) xsize(8.5) ysize(7) name(fig3,replace)
graph save exports/figures/figure03.gph, replace
graph export exports/figures/figure03.png, replace width(2400)
import delimited exports/figures/figure04_data.csv, clear varnames(1) asdouble encoding(UTF-8) case(preserve)
drop strategy
strategy_names
gen byte pos=7-display_order
label define strategypos 4 "AI 단독" 3 "AI+디지털" 2 "AI+물리" 1 "AI+교차결합", replace
label values pos strategypos
twoway (rcap ci_low ci_high pos, horizontal lcolor("43 111 142")) ///
    (scatter pos bias_corrected_catchup_ratio, mcolor("43 111 142") msymbol(O)) ///
    (scatter pos raw_catchup_ratio, mcolor("75 85 99") msymbol(Oh)), ///
    ylabel(1(1)4, valuelabel angle(0) labsize(medsmall)) xline(1,lpattern(dash) lcolor(gs8)) ///
    xtitle("t에서 t+2까지의 추격비") ytitle("") ///
    legend(order(2 "편향보정치" 3 "원 점추정치") rows(1) position(6)) ///
    note("막대: 기업 재표집 조건부 95% 구간",size(small)) ///
    graphregion(color(white)) plotregion(color(white)) xsize(8.5) ysize(5) name(fig4,replace)
graph save exports/figures/figure04.gph, replace
graph export exports/figures/figure04.png, replace width(2400)
