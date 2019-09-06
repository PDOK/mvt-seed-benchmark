#!/usr/bin/env bash
PLAN_ID=$1

./init.sh "$PLAN_ID"

rm stats.txt 2> /dev/null
rm -r tiles 2> /dev/null
rm config.toml 2> /dev/null

sed "s/\$PLANID/$PLAN_ID/g"  config.toml.template > config.toml

function getExtent(){
    plan_file=$1
    extent_string=$(ogrinfo -so "$plan_file" Plangebied | grep Extent)
    regex="Extent:\s\(([0-9\.]+),\s([0-9\.]+)\)\s-\s\(([0-9\.]+),\s([0-9\.]+)\)"
    if [[ $extent_string =~ $regex ]]; then
        EXTENT="${BASH_REMATCH[1]},${BASH_REMATCH[2]},${BASH_REMATCH[3]},${BASH_REMATCH[4]}"
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
--extent "6.3862778,53.1610737,6.3903579,53.1625013" \
--maxzoom 9 --minzoom 0 \
--tileset "$PLAN_ID" &

pid=$!
# If this script is killed, kill the `docker run'.
trap "kill $pid 2> /dev/null" EXIT
# While copy is running...
while kill -0 $pid 2> /dev/null; do
    # Do stuff
    docker stats --no-stream | sed -n 2p >> stats.txt
    sleep 1
done && docker cp "$container_id:/var/cache/mvtcache" tiles/

# Disable the trap on a normal exit.
trap - EXIT
