#!/bin/bash
cd video
mplayer -ao null -ac null -vo png "$1"
for i in *.png; do convert $i ${i%.*}.bmp; done

