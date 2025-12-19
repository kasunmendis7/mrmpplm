#!/bin/bash

results=$(find "." -path "./build/*" -prune -o \( -name "*.c" -o -name "*.h" -o -name "*.json" -o -name "configure" \) -type f -exec grep -m1 -l -i "Samindu" {} \;)

while IFS= read -r file;
do
	dir=$(dirname "$file")

	if [ ! -d "../qemu-8.1.2-patch/$dir" ];
	then
		mkdir -p "../qemu-8.1.2-patch/$dir"
	fi

	rsync -av --progress "$file" "../qemu-8.1.2-patch/$dir"

done <<< "$results"
