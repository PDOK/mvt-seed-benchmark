#!/usr/bin/env bash

function rp-download(){
  plan_id="$1"
  curl -L "https://www.ruimtelijkeplannen.nl/documents/$plan_id/$plan_id.gml" -o "$plan_id.gml"
}

plan_id="$1"
if [ -z "$plan_id" ];then
  echo "usage: init.sh <plan_id>"
  exit 1
fi

if [ ! -f "data/$plan_id.gml" ];then
  echo "not existing: \"data/$plan_id.gml\"" 
  rp-download "$plan_id"
  mkdir -p data/
  mv "$plan_id.gml" data/
fi

container_id=$(uuidgen)
if [ ! -f "data/$plan_id-simplified.gml" ];then
  docker run --name "$container_id" -v $(pwd)/data:/data rp-converter convert-plan "/data/$plan_id.gml"
  docker cp "$container_id":/"$plan_id-simplified.gml" data/
  # Curve geometry types are supported for PostGIS layers only, see T-Rex docs
  ogr2ogr -f GML "data/$plan_id-simplified-linear.gml" -nlt CONVERT_TO_LINEAR "data/$plan_id-simplified.gml"
  docker rm "$container_id"
fi
