version 16.1
clear all
set more off
set type double
global MIG `"`c(pwd)'"'
do code/01_raw_panel.do
do code/02_dynamic_panel.do
do code/03_strategy_panel.do
display "RAW_PANEL_COMPLETE"
