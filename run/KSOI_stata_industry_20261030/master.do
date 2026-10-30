version 16.1
clear all
set more off
set type double
do code/industry_summary.do
set type float
do analysis/common_sample.do
do analysis/industry_year_sensitivity.do
do analysis/appendix_a1.do
do code/appendix_summary.do
do code/independent_industry.do
display "STATA_INDUSTRY_STAGE5_COMPLETE"
