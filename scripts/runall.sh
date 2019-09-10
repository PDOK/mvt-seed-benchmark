for i in {1..5}
do
  echo "### Running iteration $i ###"
#  ./scripts/t-rex/seed.sh i
  ./scripts/tippecanoe/tippecanoe_mvt.sh i
  ./scripts/gdal/ogr2ogr_mvt.sh i
done
