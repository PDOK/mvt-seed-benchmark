#!/bin/bash

function generateTilesOgr() {
  FILENAME=$1
  ITERATION_STEP=${2:-"$(uuidgen),0"}
  BASE_DIR=$3
  MIN_ZOOM=${4:-0}
  MAX_ZOOM=${5:-8}
  DATA_DIR=$BASE_DIR/../data
  LOG_DIR=$BASE_DIR/../log
  
  BASENAME="$(basename $FILENAME)"
  PLAN_ID=${BASENAME%-*}

  if [ ! -f  $CURRENT_DIR/plannen_whitelist.txt ] || grep -Fxq "$PLAN_ID" $CURRENT_DIR/plannen_whitelist.txt; then
    echo "FILENAME: $FILENAME"
    # Log step, PlanID, time spent, cpu, Memory usage in bytes
    LOG_FORMAT="${ITERATION_STEP},${PLAN_ID},%E,%P,%M,%K"

    RESULT_DIR="result/gdal/${PLAN_ID}"

    STEP="gdal: Generate MVTs GDAL"
    echo "$STEP"
    /usr/bin/time --format="$(date +%FT%T%Z),$STEP,$LOG_FORMAT" -o $LOG_DIR/gdal_benchmark.log --append \
      ogr2ogr --debug ON -f MVT \
      "$DATA_DIR/$RESULT_DIR" \
      -a_srs EPSG:28992 \
      "$DATA_DIR/simplified/$PLAN_ID-simplified.gml" \
      -fieldTypeToString StringList,IntegerList,Date \
      --config GML_SKIP_RESOLVE_ELEMS HUGE \
      --config GML_SKIP_RESOLVE_ELEMS NONE \
      --config GML_EXPOSE_FID NO \
      --config GML_EXPOSE_GML_ID NO \
      --config GDAL_NUM_THREADS 0 \
      -dsco MINZOOM=$MIN_ZOOM \
      -dsco MAXZOOM=$MAX_ZOOM \
      -dsco TILING_SCHEME=EPSG:28992,-285401.92,903402.0,880803.84

    log_filecount_and_dirsize $CURRENT_DIR/.. "gdal" $PLAN_ID $MIN_ZOOM $MAX_ZOOM $ITERATION_STEP
    rm -rf "${DATA_DIR:?}/$RESULT_DIR"
  fi
}

rm -rf "${DATA_DIR:?}/result/gdal"
mkdir -p "${DATA_DIR:?}/result/gdal"

# for FILENAME in $DATA_DIR/simplified/*-simplified.gml
# do
#   generateTiles "$FILENAME"
# done