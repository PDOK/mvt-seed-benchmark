#!/bin/bash
CURRENT_DIR="${0%/*}"
dataDir="$CURRENT_DIR/../data"
dataDirRaw="$dataDir/raw"
dataDirSimplified="$dataDir/simplified"
mkdir -p "$dataDirRaw"
mkdir -p "$dataDirSimplified"

function rp-download(){
  plan_id="$1"
  curl -L "https://www.ruimtelijkeplannen.nl/documents/$plan_id/$plan_id.gml" -o "$dataDirRaw/$plan_id.gml"
}

while read -r plan_id; do
  if [ ! -f "$dataDirRaw/$plan_id.gml" ];then
    echo "downloading: '$plan_id'"
    rp-download "$plan_id"
  fi

  if [ ! -f "$dataDirSimplified/$plan_id-simplified.gml" ];then
    container_id=$(uuidgen)
    docker run --name "$container_id" -v $(readlink -f $dataDirRaw):/data rp-converter convert-plan "/data/$plan_id.gml"
    docker cp "$container_id":/"$plan_id-simplified.gml" "$dataDirSimplified/"
    docker rm "$container_id" 2> /dev/null
  fi
done < "$CURRENT_DIR/plannen.txt"



