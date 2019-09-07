#!/bin/bash
echo "Creating MVT for $1 with "
ogr2ogr -f MVT test -a_srs EPSG:28992 /data/$1 -fieldTypeToString StringList,IntegerList,Date --config GML_SKIP_RESOLVE_ELEMS HUGE --config GML_SKIP_RESOLVE_ELEMS NONE --config GML_EXPOSE_FID NO --config GML_EXPOSE_GML_ID NO --config GDAL_NUM_THREADS 0 -dsco MINZOOM=1 -dsco MAXZOOM=11 -dsco TILING_SCHEME=EPSG:28992,-285401.92,903402.0,880803.84