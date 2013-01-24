#!/bin/bash

mplayer -demuxer rawvideo -rawvideo w=640:h=480:format=rgb24:fps=$1 -fps $1 out.rgb -vo x11
