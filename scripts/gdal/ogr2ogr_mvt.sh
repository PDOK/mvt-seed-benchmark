#!/bin/bash
. ./scripts/util.sh --source-only
ITERATION_STEP=${$1:-0}

rm -rf "data/result/gdal"
mkdir -p "data/result/gdal"
for FILENAME in data/simplified/*-simplified.gml
do
  BASENAME=$(basename $FILENAME)
  PLAN_ID=${BASENAME%-*}

  # Log step, PlanID, time spent, cpu, Memory usage in bytes
  LOG_FORMAT="${ITERATION_STEP},${PLAN_ID},%E,%P,%M,%K"

  RESULT_DIR="data/result/gdal/${PLAN_ID}"

  STEP="gdal: Generate MVTs GDAL"
  echo "$STEP"
  /usr/bin/time --format="$(date +%FT%T%Z),$STEP,$LOG_FORMAT" -o log/gdal_benchmark.log --append \
    docker-compose run --rm -u "$UID:$UID" gdal \
    ogr2ogr -f MVT \
    "/$RESULT_DIR" \
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

  log_filecount_and_dirsize "gdal" $PLAN_ID 0 15

  rm -rf "$RESULT_DIR"
done