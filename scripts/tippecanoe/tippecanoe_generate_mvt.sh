#!/bin/bash

## PlanID, Log step, time spent, real time, user time, system time, cpu, Memory usage in bytes, inputs, outputs, max, swaps, major, minor
# VERBOSE_LOG_FORMAT="${PLAN_ID},%E,%e,%U,%s,%P,%K,%I,%O,%D,%M,%W,%F,%R"

for FILENAME in $(ls data/simplified/*-simplified.gml)
  do
    BASENAME=$(basename $FILENAME)
    PLAN_ID=${BASENAME%-*}
    # Log step, PlanID, time spent, cpu, Memory usage in bytes
    LOG_FORMAT="${PLAN_ID},%E,%P,%K"

    STEP="Generate GeoJSON"
    echo "$STEP"
    /usr/bin/time --format="$STEP,$LOG_FORMAT" -o log/tippecanoe_benchmark.log --append \
    docker-compose run --rm -u "$UID:$UID" gdal \
      ogr2ogr \
        -f GeoJSON \
        -a_srs EPSG:28992 \
        -a_srs EPSG:4326 \
        -fieldTypeToString StringList,IntegerList,Date \
        "/data/$PLAN_ID.json" \
        "/data/simplified/$PLAN_ID-simplified.gml" \
        Planobject

    RESULT_DIR="data/result/tippecanoe/${PLAN_ID}"

    mkdir -p "$RESULT_DIR"

    STEP="Run tippecanoe"
    echo "$STEP"
    /usr/bin/time --format="$STEP,$LOG_FORMAT" -o log/tippecanoe_benchmark.log --append \
      docker-compose run --rm -u "$UID:$UID" tippecanoe \
        tippecanoe \
          --name="$PLAN_ID" \
          --output-to-directory="/${RESULT_DIR}" \
          --minimum-zoom=1 \
          --maximum-zoom=11 \
          --full-detail=11 \
          --low-detail=11 \
          --minimum-detail=7 \
          --drop-densest-as-needed \
          --detect-shared-borders \
          --buffer=5 \
          "/data/${PLAN_ID}.json"

    rm "/data/${PLAN_ID}.json"
done