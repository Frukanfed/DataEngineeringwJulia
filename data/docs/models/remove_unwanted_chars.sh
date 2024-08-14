#!/bin/bash


for ((i=1999; i<=2023; i++)) do 
	file=$((i))_models.csv
	sed -i 's/Yurdaer Okur,,/Yurdaer Okur,/g' "$file"
done
