#!/bin/bash

## PlanID, Log step, time spent, real time, user time, system time, cpu, Memory usage in bytes, inputs, outputs, max, swaps, major, minor
# VERBOSE_LOG_FORMAT="${PLAN_ID},%E,%e,%U,%s,%P,%K,%I,%O,%D,%M,%W,%F,%R"
rm -rf "data/result/tippecanoe"
mkdir -p "data/result/tippecanoe"

for FILENAME in data/simplified/*-simplified.gml
do
  BASENAME=$(basename $FILENAME)
  PLAN_ID=${BASENAME%-*}
  # Log step, PlanID, time spent, cpu, Memory usage in bytes
  LOG_FORMAT="${PLAN_ID},%E,%P,%M"

  STEP="Generate GeoJSON"
  echo "$STEP"
  /usr/bin/time --format="$(date +%FT%T%Z),$STEP,$LOG_FORMAT" -o log/tippecanoe_benchmark.log --append \
  docker-compose run --rm -u "$UID:$UID" gdal \
    ogr2ogr \
      -f GeoJSON \
      -s_srs EPSG:28992 \
      -t_srs EPSG:4326 \
      -fieldTypeToString StringList,IntegerList,Date \
      "/data/$PLAN_ID.json" \
      "/data/simplified/$PLAN_ID-simplified.gml" \
      Planobject

  RESULT_DIR="data/result/tippecanoe/${PLAN_ID}"

  mkdir -p "$RESULT_DIR"

  STEP="Run tippecanoe"
  echo "$STEP"
  /usr/bin/time --format="$(date +%FT%T%Z),$STEP,$LOG_FORMAT" -o log/tippecanoe_benchmark.log --append \
    docker-compose run --rm -u "$UID:$UID" tippecanoe \
      tippecanoe \
        --name="$PLAN_ID" \
        --output-to-directory="/${RESULT_DIR}" \
        --minimum-zoom=5 \
        --maximum-zoom=20 \
        --drop-densest-as-needed \
        --detect-shared-borders \
        --buffer=5 \
        "/data/${PLAN_ID}.json"

  rm "data/${PLAN_ID}.json"
  rm -rf "$RESULT_DIR"
done