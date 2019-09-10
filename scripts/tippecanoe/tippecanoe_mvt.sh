#!/bin/bash
ITERATION_STEP=${1:-0}
CURRENT_DIR="${0%/*}"
. $CURRENT_DIR/../util.sh --source-only

DATA_DIR=$CURRENT_DIR/../../data
LOG_DIR=$CURRENT_DIR/../../log
set -e

## PlanID, Log step, time spent, real time, user time, system time, cpu, Memory usage in bytes, inputs, outputs, max, swaps, major, minor
# VERBOSE_LOG_FORMAT="${PLAN_ID},%E,%e,%U,%s,%P,%K,%I,%O,%D,%M,%W,%F,%R"
rm -rf "$DATA_DIR/result/tippecanoe"
mkdir -p "$DATA_DIR/result/tippecanoe"

for FILENAME in $DATA_DIR/simplified/*-simplified.gml
do

  BASENAME=$(basename $FILENAME)
  PLAN_ID=${BASENAME%-simplified.gml}

  if [ ! -f  $CURRENT_DIR/../plannen_whitelist.txt ] || grep -Fxq "$PLAN_ID" $CURRENT_DIR/../plannen_whitelist.txt; then

    # Log step, PlanID, time spent, cpu, Memory usage in bytes, File inputs, File outputs
    LOG_FORMAT="${ITERATION_STEP},${PLAN_ID},%E,%P,%M,%I,%O"

    STEP="tippecanoe: Generate GeoJSON"
    echo "$STEP"
    /usr/bin/time --format="$(date +%FT%T%Z),$STEP,$LOG_FORMAT" -o $LOG_DIR/tippecanoe_benchmark.log --append \
    docker-compose run --rm -u "$UID:$UID" gdal \
      ogr2ogr \
        -f GeoJSON \
        -s_srs EPSG:28992 \
        -t_srs EPSG:4326 \
        -fieldTypeToString StringList,IntegerList,Date \
        "/data/$PLAN_ID.json" \
        "/data/simplified/$PLAN_ID-simplified.gml" \
        Planobject

    RESULT_DIR="result/tippecanoe/${PLAN_ID}"

    mkdir -p "$RESULT_DIR"

    STEP="tippecanoe: Run tippecanoe"
    echo "$STEP"
    /usr/bin/time --format="$(date +%FT%T%Z),$STEP,$LOG_FORMAT" -o $LOG_DIR/tippecanoe_benchmark.log --append \
      docker-compose run --rm -u "$UID:$UID" tippecanoe \
        tippecanoe \
          --name="$PLAN_ID" \
          --output-to-directory="/data/${RESULT_DIR}" \
          --minimum-zoom=5 \
          --maximum-zoom=20 \
          --drop-densest-as-needed \
          --detect-shared-borders \
          --buffer=5 \
          "/data/${PLAN_ID}.json"

    log_filecount_and_dirsize $CURRENT_DIR/../.. "tippecanoe" $PLAN_ID 5 20

    # using ${var:?} to prevent expanding to "/", considering the rm -rf
    rm "${DATA_DIR:?}/${PLAN_ID:?}.json"
    rm -rf "${DATA_DIR:?}/${RESULT_DIR:?}"
  fi
done