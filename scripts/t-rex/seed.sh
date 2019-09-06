#!/usr/bin/env bash
PLAN_ID=$1

./init.sh "$PLAN_ID"

rm "tiles/$PLAN_ID/stats.txt" 2> /dev/null
rm config.toml 2> /dev/null
mkdir -p "tiles/$PLAN_ID" 2> /dev/null

sed "s/\$PLANID/$PLAN_ID/g"  config.toml.template > config.toml

function getExtent(){
    plan_file=$1
    extent_string=$(ogrinfo -so "$plan_file" Plangebied | grep Extent)
    regex="Extent:\s\(([0-9\.]+),\s([0-9\.]+)\)\s-\s\(([0-9\.]+),\s([0-9\.]+)\)"
    if [[ $extent_string =~ $regex ]]; then
        echo "extent_string: $extent_string"
        LOWER=$(echo -e "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}" |  gdaltransform -output_xy  -s_srs EPSG:28992 -t_srs EPSG:4326)
        UPPER=$(echo -e "${BASH_REMATCH[3]} ${BASH_REMATCH[4]}" |  gdaltransform -output_xy  -s_srs EPSG:28992 -t_srs EPSG:4326)
        echo "LOWER: $LOWER"
        echo "UPPER: $UPPER"
        EXTENT="$(echo $LOWER | awk '{print $1","$2}'),$(echo $UPPER | awk '{print $1","$2}')"
    else
        echo "could not determine bbox"
        exit 1
    fi
}

getExtent "data/$PLAN_ID-simplified.gml"
echo "EXTENT: $EXTENT"

container_id=$(uuidgen)
docker run \
--name "$container_id" \
-v "$(pwd)":/conf \
-u root \
sourcepole/t-rex generate \
--config /conf/config.toml \
--extent "$EXTENT" \
--maxzoom 9 --minzoom 0 \
--tileset "$PLAN_ID" &


pid=$!
# If this script is killed, kill the `docker run'.
trap "kill $pid 2> /dev/null" EXIT
# While copy is running...
while kill -0 $pid 2> /dev/null; do
    # get docker stats for docker container
    docker stats --no-stream | grep "$container_id" | ts '[%Y-%m-%d %H:%M:%S]' >> "tiles/$PLAN_ID/stats.txt"
    sleep 0.1
done && docker cp "$container_id:/var/cache/mvtcache/$PLAN_ID" "tiles/$PLAN_ID" && \
 jq --arg extent $EXTENT .bounds='"[\($extent)]"' "tiles/$PLAN_ID/$PLAN_ID/metadata.json" > "tiles/$PLAN_ID/$PLAN_ID/metadata.json.tmp" && \
 mv "tiles/$PLAN_ID/$PLAN_ID/metadata.json.tmp" "tiles/$PLAN_ID/$PLAN_ID/metadata.json" && \
 ps -o etime= -p "$pid"

# Disable the trap on a normal exit.
trap - EXIT
