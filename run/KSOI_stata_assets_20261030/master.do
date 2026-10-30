version 16.1
clear all
set more off
set type double
global ROOT `"`c(pwd)'"'
do code/audit.do
do code/impact.do
do code/prepare.do
do code/reestimate.do
do code/summarize.do
do code/certificate.do
display "STATA_ASSET_STAGE7_COMPLETE"
