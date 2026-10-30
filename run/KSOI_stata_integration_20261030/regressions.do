version 16.1
clear all
set more off
set type float
do code/regression_inputs.do
do analysis/enterprise_activity_technology_strategy_mean_performance.do
do analysis/enterprise_activity_technology_strategy_dea_second_stage.do
do analysis/enterprise_activity_bogetoft_model_comparison.do
do analysis/did_revised.do
do code/actual_balance.do
display "REGRESSION_INTEGRATION_COMPLETE"
