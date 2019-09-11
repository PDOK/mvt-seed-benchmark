#!/usr/bin/env bash

function getExtent(){
    plan_file=$1
    extent_string=$(ogrinfo -so "$plan_file" "activiteiten_export" | grep Extent)
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
    replace_string=$(sed 's:/:\\/:g'  <<<"$DATA_DIR" )
    sed "s/\$DATA_DIR/$replace_string/g;s/\$PLAN_ID/$PLAN_ID/g;"  "$CURRENT_DIR/t-rex/config.toml.template"  > "$CURRENT_DIR/t-rex/config.toml"
    echo "init step 2"
    echo "init step 3"
    EXTENT="3.2,50.75,7.22,53.7"
}

function onFinish(){
    jq --arg extent $EXTENT .bounds='"[\($extent)]"' "tiles/$PLAN_ID/$PLAN_ID/metadata.json" > "tiles/$PLAN_ID/$PLAN_ID/metadata.json.tmp"
    mv "tiles/$PLAN_ID/$PLAN_ID/metadata.json.tmp" "tiles/$PLAN_ID/$PLAN_ID/metadata.json"
}

function generateTilesTrex(){
    FILENAME=$1
    ITERATION_STEP=${2:-"$(uuidgen),0"}
    BASE_DIR=$3
    MIN_ZOOM=${4:-0}
    MAX_ZOOM=${5:-8}
    DATA_DIR=$BASE_DIR/../data
    LOG_DIR=$BASE_DIR/../log

    BASENAME=$(basename $FILENAME)
    PLAN_ID=${BASENAME%.gpkg}

    if [ ! -f  $CURRENT_DIR/plannen_whitelist.txt ] || grep -Fxq "$PLAN_ID" $CURRENT_DIR/plannen_whitelist.txt; then
        echo "FILENAME: $FILENAME"
        # Log step, PlanID, time spent, cpu, Memory usage in Kbytes, File inputs, File outputs
        LOG_FORMAT="${ITERATION_STEP},${PLAN_ID},%E,%P,%M,%I,%O"
#        STEP="t-rex: preprocess gml"
#        echo "$STEP"

#        /usr/bin/time --format="$(date +%FT%T%Z),$STEP,$LOG_FORMAT" -o $LOG_DIR/trex_benchmark.log --append \
#            ogr2ogr -f GML "$DATA_DIR/simplified/$PLAN_ID-simplified-linear.gml" -nlt CONVERT_TO_LINEAR "$DATA_DIR/simplified/$PLAN_ID-simplified.gml"

        STEP="t-rex: generate tiles"
        echo "$STEP"
        echo "$PLAN_ID"
        init "$PLAN_ID"
        echo "EXTENT: $EXTENT"
        /usr/bin/time --format="$(date +%FT%T%Z),$STEP,$LOG_FORMAT" -o $LOG_DIR/trex_benchmark.log --append \
            t_rex generate \
            --config $CURRENT_DIR/t-rex/config.toml \
            --extent "$EXTENT" \
            --maxzoom $MAX_ZOOM --minzoom $MIN_ZOOM \
            --tileset "$PLAN_ID" \
            --overwrite true

        log_filecount_and_dirsize $CURRENT_DIR/.. "t-rex" $PLAN_ID $MIN_ZOOM $MAX_ZOOM $ITERATION_STEP
#        rm "$DATA_DIR/simplified/$PLAN_ID-simplified-linear.gml"
        rm -rf "${DATA_DIR:?}/result/t-rex/${PLAN_ID:?}"
    fi
}
