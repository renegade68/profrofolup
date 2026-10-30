version 16.1
clear all
set more off
set type double
capture log close _all
do code/prepare.do
do code/reestimate.do
do code/summaries.do
set type float
do code/export_capital.do
do code/export_summary.do
display "STATA_PRICE_STAGE6_COMPLETE"
