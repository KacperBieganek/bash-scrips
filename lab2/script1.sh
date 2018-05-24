#!/bin/bash


if [[ $# -eq 2 ]]
then
	if [[ -d ${1} ]]
	then
		REALPATH=$(realpath ${1});
		OUTPUTDIR=$(realpath ${2});
		for FILE in $(find ${1});
		do
			if [[ -d $FILE ]]; then
				echo "$FILE is a directory"
			elif [[ -f $FILE ]]; then
				echo "$FILE is a regular file"
				ln -s "$REALPATH/$(basename $FILE)" "$OUTPUTDIR/$(basename $FILE)_ln"
			elif [[ -h $FILE ]]; then
				echo "$FILE is a symbolic link"
			fi
		done
	else
		echo "First parameter has to be an existing directory"
	fi
else
	echo "Illegal number of parameters"
fi


