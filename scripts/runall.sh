#!/usr/bin/env bash

CURRENT_DIR="${0%/*}"
LOG_DIR=$CURRENT_DIR/../log
rm $LOG_DIR/*.log
DATA_DIR=$CURRENT_DIR/../data

. $CURRENT_DIR/t-rex/trex_mvt.sh --source-only
. $CURRENT_DIR/gdal/ogr2ogr_mvt.sh --source-only
. $CURRENT_DIR/tippecanoe/tippecanoe.sh --source-only
. $CURRENT_DIR/util.sh --source-only

for i in {1..10}
do
  UUID=$(uuidgen)
  RUN_IDS="$UUID,$i"
  echo "### Running iteration $i with uuid $UUID ###"
  $CURRENT_DIR/t-rex/trex_mvt.sh $RUN_IDS
  $CURRENT_DIR/tippecanoe/tippecanoe_mvt.sh $RUN_IDS
  $CURRENT_DIR/gdal/ogr2ogr_mvt.sh $RUN_IDS

  for FILENAME in $DATA_DIR/simplified/*-simplified.gml
  do
    generateTilesOgr "$FILENAME" 
    generateTilesTippecanoe "$FILENAME"
    generateTilesTrex "$FILENAME"

    FILENAME=$1
    ITERATION_STEP=${2}
    BASE_DIR=$3
    MIN_ZOOM=${4:-0}
    MAX_ZOOM=${5:-8}
  done
done

archive_dir="$LOG_DIR/$(date +%FT%T)"
mkdir -p "$archive_dir" 2> /dev/null
mv $LOG_DIR/*.log "$archive_dir"
