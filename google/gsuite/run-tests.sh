#!/bin/bash

if [ $# -eq 0 ]
then
	echo
	
	printf "%s\n" \
	"Usage: $0 <argv>	Where argv is the file name(s) of the test(s)" \
	"               	e.g: $0 tests/decrypt.py tests/user-api.py" \
	| column -t -s "	"
	
	echo
	exit
fi

echo
newline=''

while test $# -gt 0; do
	if [ -n "$newline" ]
	then
		echo -e "$newline"
	else
		newline="\n"
	fi
	
	echo "--------------- Test: $1 ---------------"
	
	script=$1
	
	if [ -f "$script" ] 
	then
		module=${script%.py}
		python -m "$module"
	else
		echo "FAILED: test does not exist."
	fi
	shift
done

echo