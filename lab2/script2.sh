#!/bin/bash

if [[ $# -eq 2 ]]
then
	if [[ -d ${1} ]]
	then
		for FILE in $(find ${1} -xtype l);
		do
			echo "$FILE $(date)" >> ${2}_ln_removal.txt
			rm -rf  $FILE
		done
	else
		echo "First parameter must be a directory"
	fi
else
	echo "Illegal number of parameters"
fi
