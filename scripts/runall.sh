for i in {1..5}
do
  UUID=$(uuidgen)
  RUN_IDS="$UUID,$i"
  echo "### Running iteration $i with uuid $UUID ###"
#  ./scripts/t-rex/seed.sh $RUN_IDS
  ./scripts/tippecanoe/tippecanoe_mvt.sh $RUN_IDS
#  ./scripts/gdal/ogr2ogr_mvt.sh $RUN_IDS
done
