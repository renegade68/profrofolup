version 16.1
clear all
set more off
set type double
global MIG `"`c(pwd)'"'
do code/summaries.do
do code/event_stacks.do
do code/km.do
set type float
do code/regression_inputs.do
do analysis/enterprise_activity_technology_strategy_dea_second_stage.do
do analysis/enterprise_activity_ai_users_only_dea_comparison.do
do analysis/enterprise_activity_bogetoft_model_comparison.do
do analysis/enterprise_activity_maeng_lee_dea_extension.do
do analysis/did_revised.do
do code/actual_balance.do
display "STATA_GLOBAL_STAGE4_COMPLETE"
