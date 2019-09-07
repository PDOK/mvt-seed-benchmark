#!/bin/bash

PLAN_ID=$1
RESULT_DIR=$2

tippecanoe \
  --name=$PLAN_ID \
  --output-to-directory="/${RESULT_DIR}" \
  --projection=EPSG:3857 \
  --minimum-zoom=1 \
  --maximum-zoom=11 \
  --full-detail=11 \
  --low-detail=11 \
  --minimum-detail=7 \
  --drop-densest-as-needed \
  --detect-shared-borders \
  --buffer=5 \
  "/data/${PLAN_ID}.json"

chown -R $UID "/${RESULT_DIR}"

rm "/data/${PLAN_ID}.json"
