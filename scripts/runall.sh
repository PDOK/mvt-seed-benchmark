#!/usr/bin/env bash
set -e

CURRENT_DIR="${0%/*}"
LOG_DIR=$CURRENT_DIR/log
rm $LOG_DIR/*.log || true
DATA_DIR=$CURRENT_DIR/../data

# shellcheck source=src/lib.sh
. $CURRENT_DIR/t-rex/trex_mvt.sh --source-only
# shellcheck source=src/lib.sh
. $CURRENT_DIR/gdal/ogr2ogr_mvt.sh --source-only
# shellcheck source=src/lib.sh
. $CURRENT_DIR/tippecanoe/tippecanoe_mvt.sh --source-only
# shellcheck source=src/lib.sh
. $CURRENT_DIR/util.sh --source-only
echo "$DATA_DIR $CURRENT_DIR"

for i in {1..1}
do
  UUID=$(uuidgen)
  ITERATION_STEP="$UUID,$i"
  echo "### Running iteration $i with uuid $UUID ###"
  echo "DATADIR in runall.sh: $DATA_DIR | CURRENT_DIR in runall.sh: $CURRENT_DIR"
  for FILENAME in $DATA_DIR/simplified/*.gpkg
  do
#    generateTilesTippecanoe "$FILENAME" "$ITERATION_STEP" "$CURRENT_DIR"
    generateTilesTrex "$FILENAME" "$ITERATION_STEP" "$CURRENT_DIR"
#    generateTilesOgr "$FILENAME" "$ITERATION_STEP" "$CURRENT_DIR"
  done
done

archive_dir="$LOG_DIR/$(date +%FT%T)"
mkdir -p "$archive_dir" 2> /dev/null
mv $LOG_DIR/*.log "$archive_dir"
