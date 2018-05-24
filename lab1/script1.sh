#!/bin/bash


if [[ $# -eq 1 ]]
then
	for FILE in $(find ${1} -not -empty  -name "*.hpp" -writable);
	do
		mv "$FILE" "$FILE.bak"
	done
else
	echo "Illegal number of parameters"
fi

