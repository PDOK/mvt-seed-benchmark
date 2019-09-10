#!/bin/bash
ITERATION_STEP=${1:-0}
CURRENT_DIR="${0%/*}"
. $CURRENT_DIR/../util.sh --source-only

DATA_DIR=$CURRENT_DIR/../../data
LOG_DIR=$CURRENT_DIR/../../log
set -e


rm -rf "${DATA_DIR:?}/result/gdal"
mkdir -p "${DATA_DIR:?}/result/gdal"


for FILENAME in $DATA_DIR/simplified/*-simplified.gml
do
  BASENAME=$(basename $FILENAME)
  PLAN_ID=${BASENAME%-*}

  if [ ! -f  $CURRENT_DIR/../plannen_whitelist.txt ] || grep -Fxq "$PLAN_ID" $CURRENT_DIR/../plannen_whitelist.txt; then
    # Log step, PlanID, time spent, cpu, Memory usage in bytes
    LOG_FORMAT="${ITERATION_STEP},${PLAN_ID},%E,%P,%M,%K"

    RESULT_DIR="result/gdal/${PLAN_ID}"

    STEP="gdal: Generate MVTs GDAL"
    echo "$STEP"
    /usr/bin/time --format="$(date +%FT%T%Z),$STEP,$LOG_FORMAT" -o $LOG_DIR/gdal_benchmark.log --append \
      docker-compose run --rm -u "$UID:$UID" gdal \
      ogr2ogr --debug ON -f MVT \
      "/data/$RESULT_DIR" \
      -a_srs EPSG:28992 \
      "/data/simplified/$PLAN_ID-simplified.gml" \
      -fieldTypeToString StringList,IntegerList,Date \
      --config GML_SKIP_RESOLVE_ELEMS HUGE \
      --config GML_SKIP_RESOLVE_ELEMS NONE \
      --config GML_EXPOSE_FID NO \
      --config GML_EXPOSE_GML_ID NO \
      --config GDAL_NUM_THREADS 0 \
      -dsco MINZOOM=0 \
      -dsco MAXZOOM=15 \
      -dsco TILING_SCHEME=EPSG:28992,-285401.92,903402.0,880803.84

    log_filecount_and_dirsize $CURRENT_DIR/../.. "gdal" $PLAN_ID 0 15
    rm -rf "${DATA_DIR:?}/$RESULT_DIR"
  fi
done