#!/usr/bin/env bash

CURRENT_DIR="${0%/*}"
LOG_DIR=$CURRENT_DIR/../log
rm $LOG_DIR/*.log

for i in {1..10}
do
  UUID=$(uuidgen)
  RUN_IDS="$UUID,$i"
  echo "### Running iteration $i with uuid $UUID ###"
  $CURRENT_DIR/t-rex/trex_mvt.sh $RUN_IDS
  $CURRENT_DIR/tippecanoe/tippecanoe_mvt.sh $RUN_IDS
  $CURRENT_DIR/gdal/ogr2ogr_mvt.sh $RUN_IDS
done

archive_dir=$LOG_DIR/$(date)
mkdir -p $archive_dir 2> /dev/null
mv $LOG_DIR/*.log "$archive_dir"
