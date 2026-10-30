version 16.1
clear all
set more off
set type float
adopath ++ "analysis/vendor/st0444"
mata: mata mlib index
foreach ind in 10 11 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 {
    do analysis/industry_one.do `ind'
}
display "STATA_INDUSTRY_SCORES_COMPLETE"
