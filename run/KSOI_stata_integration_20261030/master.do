version 16.1
set more off
set type float
args stage
if "`stage'"=="" local stage postprocess
assert "`stage'"=="postprocess"
* Run jobs through the root run_all.zsh driver.
do conditional.do fresh
do regressions.do
display "STATA_INTEGRATION_STAGE3_COMPLETE"
