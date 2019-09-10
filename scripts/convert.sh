#!/bin/bash
mkdir data/simplified
for filepath in data/raw/*.gml
  do
    filename=$(basename $filepath)
    docker run -v /home/roel/dev/mvt-seed-benchmark/data/:/data --name converter pdok:rp-converter convert-plan "/data/$filename"
    docker cp "converter:/${filename::-4}-simplified.gml" ./data/simplified
    docker rm converter
done
