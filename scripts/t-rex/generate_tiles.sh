#!/usr/bin/env bash
ITERATION_STEP=${1:-0}

set -e

CURRENT_DIR="${0%/*}"
DATA_FOLDER_NAME="data"
SOURCE_DATA_FOLDER="$CURRENT_DIR/../../$DATA_FOLDER_NAME"

function getExtent(){
    plan_file=$1
    extent_string=$(ogrinfo -so "$plan_file" Plangebied | grep Extent)
    regex="Extent:\s\(([0-9\.]+),\s([0-9\.]+)\)\s-\s\(([0-9\.]+),\s([0-9\.]+)\)"
    if [[ $extent_string =~ $regex ]]; then
        echo "extent_string: $extent_string"
        LOWER=$(echo -e "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}" |  gdaltransform -output_xy  -s_srs EPSG:28992 -t_srs EPSG:4326)
        UPPER=$(echo -e "${BASH_REMATCH[3]} ${BASH_REMATCH[4]}" |  gdaltransform -output_xy  -s_srs EPSG:28992 -t_srs EPSG:4326)
        EXTENT="$(echo $LOWER | awk '{print $1","$2}'),$(echo $UPPER | awk '{print $1","$2}')"
    else
        echo "could not determine bbox"
        exit 1
    fi
}

function init(){
    sed "s/\$PLANID/$PLAN_ID/g" $CURRENT_DIR/config.toml.template > $CURRENT_DIR/config.toml
    getExtent "$SOURCE_DATA_FOLDER/simplified/$PLAN_ID-simplified.gml"
}

function onFinish(){
    jq --arg extent $EXTENT .bounds='"[\($extent)]"' "tiles/$PLAN_ID/$PLAN_ID/metadata.json" > "tiles/$PLAN_ID/$PLAN_ID/metadata.json.tmp"
    mv "tiles/$PLAN_ID/$PLAN_ID/metadata.json.tmp" "tiles/$PLAN_ID/$PLAN_ID/metadata.json"
}

function generateTiles(){
    FILENAME=$1
    BASENAME=$(basename $FILENAME)
    PLAN_ID=${BASENAME%-simplified.gml}
    echo "BASENAME: $BASENAME"
    echo "FILENAME: $FILENAME"
    echo "PLAN_ID: $PLAN_ID"
    # Log step, PlanID, time spent, cpu, Memory usage in bytes, File inputs, File outputs
    LOG_FORMAT="${ITERATION_STEP},${PLAN_ID},%E,%P,%M,%I,%O"
    STEP="t-rex: preprocess gml"
    echo "$STEP"
    /usr/bin/time --format="$(date +%FT%T%Z),$STEP,$LOG_FORMAT" -o $CURRENT_DIR/../../log/trex_benchmark.log --append \
        docker-compose run --rm -u "$UID:$UID"  gdal \
        ogr2ogr -f GML "/data/simplified/$PLAN_ID-simplified-linear.gml" -nlt CONVERT_TO_LINEAR "/data/simplified/$PLAN_ID-simplified.gml"
    
    STEP="t-rex: generate tiles"
    echo "$STEP"
    echo "$PLAN_ID"
    init "$PLAN_ID"
    echo "EXTENT: $EXTENT"
    /usr/bin/time --format="$(date +%FT%T%Z),$STEP,$LOG_FORMAT" -o $CURRENT_DIR/../../log/trex_benchmark.log --append \
    docker-compose run --rm -u $UID:$UID \
        trex generate \
        --config /scripts/t-rex/config.toml \
        --extent "$EXTENT" \
        --maxzoom 8 --minzoom 0 \
        --tileset "$PLAN_ID"
    rm "$SOURCE_DATA_FOLDER/simplified/$PLAN_ID-simplified-linear.gml"
}

for FILENAME in $SOURCE_DATA_FOLDER/simplified/*-simplified.gml
do
    echo $FILENAME
    generateTiles "$FILENAME"
done

