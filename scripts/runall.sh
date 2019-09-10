for i in {1..5}
do
  echo "### Running iteration $i ###"
#  ./scripts/t-rex/seed.sh
  ./scripts/tippecanoe/tippecanoe_mvt.sh
  ./scripts/gdal/ogr2ogr_mvt.sh
done
