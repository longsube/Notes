#!/bin/bash

dir=$1

count=0
for f in "${dir}/"*
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
echo "Tong so chu trong foler:" $count
