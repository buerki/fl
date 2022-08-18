#!/bin/bash -

for file in "$@"; do
	echo $file
	basename "$file"
	
done

echo "basename------2"
basename "$@"
echo "ls------"
ls $@
echo "------"
ls "$@"
echo "-------------------"

# put in-file names into variable
all_in=$@
echo "$all_in"
# check that input files exist
for file in "$@"; do
	if [ -s "$file" ]; then
		# recording infile names
		infiles+="$(basename "$file") "
	else
		echo "ERROR: could not open $file" >&2
		exit 1
	fi
done

echo $infiles