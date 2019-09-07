#!/bin/bash
PLAN_ID="NL.IMRO.0437.BPDRHNoodoverloop-ON01"

## PlanID, Log step, time spent, real time, user time, system time, cpu, Memory usage in bytes, inputs, outputs, max, swaps, major, minor
# VERBOSE_LOG_FORMAT="${PLAN_ID},%E,%e,%U,%s,%P,%K,%I,%O,%D,%M,%W,%F,%R"

for FILENAME in $(ls data/simplified/*-simplified.gml)
  do
    BASENAME=$(basename $FILENAME)
    PLAN_ID=${BASENAME%-*}
    # PlanID, Log step, time spent, cpu, Memory usage in bytes
    LOG_FORMAT="${PLAN_ID},%E,%P,%K"

    STEP="Generate GeoJSON"
    echo "$STEP"
    /usr/bin/time --format="$STEP,$LOG_FORMAT" -o log/tippecanoe_benchmark.log --append \
      ogr2ogr \
        -f GeoJSON \
        -a_srs EPSG:28992 \
        -fieldTypeToString StringList,IntegerList,Date \
        "data/$PLAN_ID.json" \
        "data/simplified/$PLAN_ID-simplified.gml" \
        Planobject

    RESULT_DIR="data/result/${PLAN_ID}"

    mkdir $RESULT_DIR

    STEP="Run tippecanoe"
    echo "$STEP"
    /usr/bin/time --format="$STEP,$LOG_FORMAT" -o log/tippecanoe_benchmark.log --append \
      docker-compose run --rm tippecanoe $PLAN_ID $RESULT_DIR
done