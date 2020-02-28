#!/bin/bash

dir1=$1
dir2=$2

count=0
for f in "${dir1}/"*
do
    if [ -d "${f}" ]
    then
        words=0
    elif [ -f "${f}" ]
    then
        words=$(wc -w "$f" | awk '{print $1}')
    fi

    count=$(($count+$words))
done

for f2 in "${dir2}/"*
do
    if [ -d "${f2}" ]
    then
        words=0
    elif [ -f "${f2}" ]
    then
        words=$(wc -w "$f2" | awk '{print $1}')
    fi

    count=$(($count+$words))
done

echo "Tong so chu trong foler:" $count
