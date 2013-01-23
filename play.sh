#!/bin/bash

mplayer -demuxer rawvideo -rawvideo w=640:h=480:format=rgb24:fps=15 out.rgb -vo x11
