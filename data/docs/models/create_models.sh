#!/bin/bash

file_to_read=/path/to/file

for ((i=2023; i>=2000; i--)); do
	file_to_write=$((i-1))_models.csv
	sed -i "/$i,/d" $file_to_read
	cat $file_to_read > $file_to_write
done
