#!/bin/bash

#For this script to work, you must install processing-java from Processing's tools menu

#NAME="Processing[^.]*\.app"
#for proc in $(ps -e | grep /$NAME | awk {'print $1'}); do
#    ps $proc
#    kill -1 $proc
#done

set

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
processing-java --sketch="${PWD}/Sketches/TranceporterIIProcessing" --output=${TMPDIR}tranceporterTempDir --run --force
IFS=$SAVEIFS
