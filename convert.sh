#!/bin/bash

path="`cd "$(dirname "$1")" ; pwd`/`basename "$1"`"
echo "Converting $path"

pushd video
rm *.png
rm *.bmp
mplayer -frames 1000 -ao null -ac null -vo png "$path"
for i in *.png; do
    if [ 0 -eq "$(expr ${i%.*} % 2)" ]; then
	convert -flop $i ${i%.*}.bmp
    fi
done
rm *.png
popd
