#!/bin/bash

log_filecount_and_dirsize() {
  BENCHMARK_TYPE=$1
  PLAN_ID=$2
  MIN_ZOOM=$3
  MAX_ZOOM=$4
  LOG_ROW=""
  LOGFILE_NAME="log/""$BENCHMARK_TYPE""_counts.log"

  for ((ZOOM_LEVEL=MIN_ZOOM; ZOOM_LEVEL<MAX_ZOOM; ZOOM_LEVEL++))
  do
    COUNT_DIR="data/result/$BENCHMARK_TYPE/$PLAN_ID/$ZOOM_LEVEL"

    LOG_ROW+=",$(du -s "$COUNT_DIR" | cut -f1),$(find "$COUNT_DIR" -type f | wc -l)"
  done

  echo "$(date +%FT%T%Z)$LOG_ROW" >> $LOGFILE_NAME
}
