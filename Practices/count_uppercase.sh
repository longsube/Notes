#!/bin/bash

dir=$1

count=0
for f in "${dir}/"*
do
    if [ -d "${f}" ]
    then
        uppercase=0
    elif [ -f "${f}" ]
    then
        uppercase=$(cat "$f" | tr -dC '[:upper:]' | wc -m)
    fi

    count=$(($count+$uppercase))
done
echo "Tong so chu viet hoa trong foler:" $count
