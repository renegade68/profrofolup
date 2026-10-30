#!/bin/zsh
set -e
unsetopt BG_NICE
cd "${0:A:h}"
release_root=$PWD
run_root=$PWD/run
stata_bin=${STATA_BIN:-/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp}
export STATA_BIN="$stata_bin"
export PYTHON_BIN=${PYTHON_BIN:-python3}
export RSCRIPT_BIN=${RSCRIPT_BIN:-Rscript}
"$PYTHON_BIN" tools/prepare.py check
s1=$run_root/KSOI_stata_migration_20261030
s2=$run_root/KSOI_stata_frontier_20261030
s3=$run_root/KSOI_stata_integration_20261030
s4=$run_root/KSOI_stata_global_20261030
s5=$run_root/KSOI_stata_industry_20261030
s6=$run_root/KSOI_stata_prices_20261030
s7=$run_root/KSOI_stata_assets_20261030
run_stata() {
  local folder=$1 file=$2 marker=$3 arch_mode=$4
  shift 4
  local stem=${file:t:r}
  print "START $folder $file $*"
  if [[ $arch_mode == intel ]]; then
    (cd "$folder" && /usr/bin/arch -x86_64 "$stata_bin" -b do "$file" "$@")
  else
    (cd "$folder" && "$stata_bin" -b do "$file" "$@")
  fi
  if rg -q '^r\([0-9]+\);' "$folder/$stem.log"; then print "FAIL $file"; return 1; fi
  rg -q "$marker" "$folder/$stem.log"
  print "DONE $folder $file $*"
}
run_stata "$s1" master.do RAW_PANEL_COMPLETE native
for dest in "$s4" "$s5" "$s6" "$s7"; do
  cp "$s1"/data/processed/enterprise_activity_*panel_2017_2024.csv "$dest/data/processed/"
done
cp "$s1/data/processed/strategy.dta" "$s4/data/processed/"
cp "$s1/data/processed/dynamic.dta" "$s4/data/processed/"
cp "$s1/data/processed/selected.dta" "$s7/data/processed/"
# Independent global specifications share no output files.
global_worker() {
  for job in "$@"; do run_stata "$s4" "jobs/$job.do" 'end of do-file' intel; done
}
global_worker no_trim operating_crs joint_trim > run/global_worker1.log 2>&1 & p1=$!
global_worker global_trim income_vrs pilot_global > run/global_worker2.log 2>&1 & p2=$!
global_worker industry_year_trim income_crs > run/global_worker3.log 2>&1 & p3=$!
wait $p1; wait $p2; wait $p3
run_stata "$s4" master.do STATA_GLOBAL_STAGE4_COMPLETE native
cp "$s4"/data/processed/enterprise_activity_*stack*.csv "$s1/data/processed/"
cp "$s4"/data/processed/enterprise_activity_*stack*.csv "$s3/data/processed/"
cp "$s1/data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv" "$s3/data/processed/"
cp "$s4/analysis/results/enterprise_activity_technology_strategy_dea_industry_year_trim_scores.csv" "$s3/analysis/results/"
for spec in no_trim industry_year_trim; do cp "$s4/analysis/results/enterprise_activity_technology_strategy_dea_${spec}_scores.csv" "$s5/analysis/results/"; done
# Full 1000-draw frontier rebuild runs independently of bias/matching and industry models.
"$RSCRIPT_BIN" tools/prepare_frontier_draws.R
run_stata "$s2" master.do KSOI_STATA_FRONTIER_COMPLETE_1000 native 1000 > run/frontier.log 2>&1 & frontier_pid=$!
bias_chain() {
  for group in ai_pure ai_combined; do run_stata "$s3" "jobs/build_match_${group}.do" 'end of do-file' native; done
  (cd "$s3" && zsh jobs/worker_1.zsh > logs/worker_1.txt 2>&1) & b1=$!
  (cd "$s3" && zsh jobs/worker_2.zsh > logs/worker_2.txt 2>&1) & b2=$!
  (cd "$s3" && zsh jobs/worker_3.zsh > logs/worker_3.txt 2>&1) & b3=$!
  wait $b1; wait $b2; wait $b3
  "$PYTHON_BIN" tools/prepare_conditional_draws.py
  run_stata "$s3" master.do STATA_INTEGRATION_STAGE3_COMPLETE native postprocess
}
bias_chain > run/bias.log 2>&1 & bias_pid=$!
run_stata "$s5" scores.do STATA_INDUSTRY_SCORES_COMPLETE intel
run_stata "$s5" master.do STATA_INDUSTRY_STAGE5_COMPLETE native
wait $frontier_pid
cp "$s2/results/event_decomposition.csv" "$s6/data/processed/baseline_events.csv"
cp "$s2/results/event_decomposition.csv" "$s7/data/processed/baseline_events.csv"
run_stata "$s6" master.do STATA_PRICE_STAGE6_COMPLETE native
run_stata "$s7" master.do STATA_ASSET_STAGE7_COMPLETE native
wait $bias_pid
print 'ANALYSIS_ALL_COMPLETE'
cd "$release_root"
run_stata "$release_root" exports.do STATA_EXPORTS_COMPLETE native
print 'KSOI_FULL_RUN_COMPLETE'
