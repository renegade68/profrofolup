version 16.1
clear all
set more off
set type double
global S1 "run/KSOI_stata_migration_20261030"
global S2 "run/KSOI_stata_frontier_20261030"
global S3 "run/KSOI_stata_integration_20261030"
global S4 "run/KSOI_stata_global_20261030"
global S5 "run/KSOI_stata_industry_20261030"
do code/descriptives.do
do code/pathways.do
do code/table_exports.do
do code/figures.do
display "STATA_EXPORTS_COMPLETE"
