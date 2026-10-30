#!/bin/zsh
set -e
cd "${0:A:h:h}"
print "START validated_long_ai_pure_h3_t0"
"${STATA_BIN:-/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp}" -b do jobs/validated_long_ai_pure_h3_t0.do
if rg -q '^r\([0-9]+\);' validated_long_ai_pure_h3_t0.log; then exit 1; fi
print "DONE validated_long_ai_pure_h3_t0"
print "START validated_long_ai_pure_h4_t4"
"${STATA_BIN:-/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp}" -b do jobs/validated_long_ai_pure_h4_t4.do
if rg -q '^r\([0-9]+\);' validated_long_ai_pure_h4_t4.log; then exit 1; fi
print "DONE validated_long_ai_pure_h4_t4"
print "START matched_ai_pure_treatment_h0"
"${STATA_BIN:-/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp}" -b do jobs/matched_ai_pure_treatment_h0.do
if rg -q '^r\([0-9]+\);' matched_ai_pure_treatment_h0.log; then exit 1; fi
print "DONE matched_ai_pure_treatment_h0"
print "START matched_ai_pure_control_h3"
"${STATA_BIN:-/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp}" -b do jobs/matched_ai_pure_control_h3.do
if rg -q '^r\([0-9]+\);' matched_ai_pure_control_h3.log; then exit 1; fi
print "DONE matched_ai_pure_control_h3"
print "START validated_long_ai_combined_h4_t0"
"${STATA_BIN:-/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp}" -b do jobs/validated_long_ai_combined_h4_t0.do
if rg -q '^r\([0-9]+\);' validated_long_ai_combined_h4_t0.log; then exit 1; fi
print "DONE validated_long_ai_combined_h4_t0"
print "START validated_long_ai_combined_h5_t5"
"${STATA_BIN:-/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp}" -b do jobs/validated_long_ai_combined_h5_t5.do
if rg -q '^r\([0-9]+\);' validated_long_ai_combined_h5_t5.log; then exit 1; fi
print "DONE validated_long_ai_combined_h5_t5"
print "START matched_ai_combined_control_h0"
"${STATA_BIN:-/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp}" -b do jobs/matched_ai_combined_control_h0.do
if rg -q '^r\([0-9]+\);' matched_ai_combined_control_h0.log; then exit 1; fi
print "DONE matched_ai_combined_control_h0"
print "START strategy_frontier_bootstrap_ai_only_h2"
/usr/bin/arch -x86_64 "${STATA_BIN:-/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp}" -b do jobs/strategy_frontier_bootstrap_ai_only_h2.do
if rg -q '^r\([0-9]+\);' strategy_frontier_bootstrap_ai_only_h2.log; then exit 1; fi
print "DONE strategy_frontier_bootstrap_ai_only_h2"
print "START strategy_frontier_bootstrap_ai_physical_bundle_h0"
/usr/bin/arch -x86_64 "${STATA_BIN:-/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp}" -b do jobs/strategy_frontier_bootstrap_ai_physical_bundle_h0.do
if rg -q '^r\([0-9]+\);' strategy_frontier_bootstrap_ai_physical_bundle_h0.log; then exit 1; fi
print "DONE strategy_frontier_bootstrap_ai_physical_bundle_h0"
print "START strategy_frontier_bootstrap_ai_cross_bundle_h2"
/usr/bin/arch -x86_64 "${STATA_BIN:-/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp}" -b do jobs/strategy_frontier_bootstrap_ai_cross_bundle_h2.do
if rg -q '^r\([0-9]+\);' strategy_frontier_bootstrap_ai_cross_bundle_h2.log; then exit 1; fi
print "DONE strategy_frontier_bootstrap_ai_cross_bundle_h2"
