#!/bin/bash

log_filecount_and_dirsize() {
  BASE_DIR=$1
  BENCHMARK_TYPE=$2
  PLAN_ID=$3
  MIN_ZOOM=$4
  MAX_ZOOM=$5
  RUN_IDS=$5
  LOG_ROW=""
  LOGFILE_NAME="$BASE_DIR/log/${BENCHMARK_TYPE}_counts.log"

  for ((ZOOM_LEVEL=MIN_ZOOM; ZOOM_LEVEL<MAX_ZOOM; ZOOM_LEVEL++))
  do
    COUNT_DIR="$BASE_DIR/data/result/$BENCHMARK_TYPE/$PLAN_ID/$ZOOM_LEVEL"
    LOG_ROW+=",$(du -s "$COUNT_DIR" | cut -f1),$(find "$COUNT_DIR" -type f | wc -l)"
  done

  echo "$RUN_IDS,$PLAN_ID,$(date +%FT%T%Z)$LOG_ROW" >> $LOGFILE_NAME
}
