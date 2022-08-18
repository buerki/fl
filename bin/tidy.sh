#!/bin/bash -
##############################################################################
# tidy.sh
version='0.9.6'
copyright="(c) 2013-14 Andreas Buerki; 2015, 2020 Cardiff University"
####
# DESCRRIPTION:
# files to be processed must be given as arguments
# 
# This script 
# • separates frequency numbers from n-grams with a tab 
# • inserts a tab after the first number (frequency)
# • deletes the total n-gram count number at the beginning of each list
# • sorts the list and appends .tidy to the list name
# • leaves the untidied list in place
#
# SYNOPSIS: tidy.sh [-v] LIST[s]
#
##############################################################################
# History
# date			change
# 05 Aug 2010	improved documentation, added -v option, now operates on arguments
# 07 Dec 2011	adjusted processing to fit with new output of huge-combine.pl
# 02 Jan 2011   adjusted processing to depend on whether there is a double space
#				sequence (which is the output format of huge-combine.sh if doc
#				count is included)
# 03 Jan 2012	added -V option and added add_to_name function
# 20 Nov 2013	made separator flexible, added -a, -d and -s options
# 22 Dec 2013	added detection of Hangeul data for proper alphabetical sorting
# 23 Dec 2013	refined numerical sort to sort secondarily by n-grams
# 12 Aug 2015	adjusted help function to show options and removed a bug that
#               prevented monogram lists for being tidied.
#  9 April 2020 changed output file naming to end in .txt
###

################################## FUNCTION DEFINITIONS #####################
help()
{
echo "
Usage:    $(basename $0) [OPTIONS] FILE+
Example:  $(basename $0) bigrams.lst
Options:  -a sort alphabetically rather than by frequency
          -d delete original input lists
          -h show this message
          -s retain the sum total of tokens (if present in input)
          -v verbose
          -V display version and licence information
Description: This script operates on all arguments given to it. They should be n-gram lists.
The script
- separates frequency numbers from n-grams with a tab
- inserts a tab after the first number (frequency)
- deletes the total n-gram count number at the beginning of each list
- sorts the list and appends .tidy to the list name
- leaves the untidied list in place
"
}
#######################
# define add_to_name function
#######################
# this function checks if a file name (given as argument) exists and
# if so appends a number to the end so as to avoid overwriting existing
# files of the name as in the argument or any with the name of the argument
# plus an incremented count appended.
####
add_to_name ( ) {
count=
if [ "$(egrep '.png$' <<<"$1")" ]; then
	if [ -e "$1" ]; then
		add=-
		count=1
		new="$(sed 's/\.png//' <<< "$1")"
		while [ -e "$new$add$count.png" ];do
			(( count += 1 ))
		done
	else
		count=
		add=
	fi
	output_filename="$(sed 's/\.png//' <<< "$1")$add$count.png"
elif [ "$(egrep '.pdf$' <<< "$1")" ]; then
	if [ -e "$1" ]; then
		add=-
		count=1
		new="$(sed 's/\.pdf//' <<< "$1")"
		while [ -e "$new$add$count.pdf" ];do
			(( count += 1 ))
		done
	else
		count=
		add=
	fi
	output_filename="$(sed 's/\.pdf//' <<< "$1")$add$count.pdf"
elif [ "$(grep '.txt' <<< "$1")" ]; then
	if [ -e "$1" ]; then
		add=-
		count=1
		new="$(sed 's/\.txt//' <<< "$1")"
		while [ -e "$new$add$count.txt" ];do
			(( count += 1 ))
		done
	else
		count=
		add=
	fi
	output_filename="$(sed 's/\.txt//' <<< "$1")$add$count.txt"
else
	if [ -e "$1" ]; then
		add=-
		count=1
		ex="$(grep -o "\....$" <<< "$1")"
		new="$(sed 's/\....$//' <<< "$1")"
		while [ -e "$new$add$count$ex" ]
			do
			(( count += 1 ))
			done
	else
		count=
		add=
	fi
	output_filename=$(echo ""$new"$add$count$ex")
fi
}
################################## END FUNCTION DEFINITIONS #################
# set defaults
sort_by_n='-k2,2nr -k1,1'
extended="-r"
# check what platform we're under
platform=$(uname -s)
# and make adjustments accordingly
if [ "$(grep 'CYGWIN' <<< $platform)" ]; then
	:
elif [ "$(grep 'Darwin' <<< $platform)" ]; then
	extended="-E"
fi
# analyse options
while getopts adhsvV opt
do
	case $opt	in
	a)	sort_by_n=
		;;
	d)	delete_untidy="true"
		;;
	h)	help
		exit 0
		;;
	s)	retain_sumoftok='true'
		;;
	v)	verbose=true
		;;
	V)	echo "$(basename $0)	-	version $version"
		echo "Copyright $copyright"
		exit 0
		;;
	esac
done
shift $((OPTIND -1))
# inform user
if [ -n "$verbose" ]; then
	total=$#
	echo "$total list(s) to be processed"
	progress=0
fi
# process arguments
for lists in $@
do
	# inform user
	if [ "$verbose" == "true" ]; then
		echo processing file $lists
	fi
	# check if file contains mostly Korean
	if [ -n "$(grep -m 1 '[가이를을다습서'] $lists)" ]; then
		korean="LC_ALL='kr'"
		if [ -n "$verbose" ]; then
			echo "Hangeul data detected"
		fi
	fi
	# check if output file name is taken
	add_to_name "$(sed 's/\.txt//' <<< "$lists").tidy.txt"
	
	if [ -n "$verbose" ] && [ -n "$retain_sumoftok" ]; then
		echo "retaining sum of tokens if present"
	fi
	
	
	# set nsize variable by checking first input list (unless unify.pl used)
	line=$(head -2 $lists | tail -1 )|| exit 1
	nsize=$(echo $line | awk '{c+=gsub(s,s)}END{print c}' s='<>') 
	if [ "$nsize" -gt 0 ]; then
		separator='<>'
	else
		nsize=$(echo $line | awk '{c+=gsub(s,s)}END{print c}' s='·')
		if [ "$nsize" -gt 0 ]; then
			separator='·'
		else
			nsize=$(echo $line | awk '{c+=gsub(s,s)}END{print c}' s='_')
			if [ "$nsize" -gt 0 ]; then
				separator='_'
			else
				echo "unknown separator in $line" >&2
				exit 1
			fi
		fi
	fi

	if [ "$verbose" == "true" ]; then
		echo "separator is $separator"
	fi
	# check if there are two consecutive spaces on a line
	consecutive_spaces=$(head -2 $lists | tail -1 | awk '{c+=gsub(s,s)}END{print c}' s='  ') 
	if [ $consecutive_spaces -eq 1 ]; then
		if [ "$retain_sumoftok" ]; then
			# first write sum of tokens to file
			grep '^[0-9]*$' $lists > $output_filename
			# now append the rest
			sed $extended -e "s/$separator([0-9]+)  /$separator	\1	/g" -e 's/ $//g' \
			< $lists | egrep -v '^[0-9]+$' | eval $korean sort $sort_by_n >> $output_filename
		else
			sed $extended -e "s/$separator([0-9]+)  /$separator	\1	/g" -e 's/ $//g' \
			< $lists | egrep -v '^[0-9]+$' | eval $korean sort $sort_by_n > $output_filename
		fi
	else
		if [ "$retain_sumoftok" ]; then
			# first write sum of tokens to file
			egrep '^[0-9]+$' $lists > $output_filename
			sed $extended -e "s/$separator([0-9]+) *$/$separator	\1/g" -e 's/ $//g' \
			< $lists | egrep -v '^[0-9]+$' | eval $korean sort $sort_by_n >> $output_filename
		else
			sed $extended -e "s/$separator([0-9]+) *$/$separator	\1/g" -e 's/ $//g' \
			< $lists | egrep -v '^[0-9]+$' | eval $korean sort $sort_by_n > $output_filename
		fi
	fi
	# the above lines are explained as follows:
	# sed line: replace patterns of '<>' followed by a number 
	# followed by a space
	# replace that pattern with the first number found after the '<>' 
	# followed and preceeded by a tab. This takes care of lines
	# like these 'ZAHL<>—<>ZAHL<>132  38 ' producing this
	# 'ZAHL<>—<>ZAHL<>	132	38'
	# 
	# grep line: get rid of the total number of n-grams printed at the beginning
	# of the list and sort the list
	#
	# sort: we sort without -d option as this option has thrown some errors in
	# testing. If Hangeul data are detected, sort is provided with the 'kr'
	# localisation to handles things correctly
	((progress +=1))
	# delete old list if -d option active
	if [ -n "$delete_untidy" ]; then
		rm $lists
	fi
done
if [ "$verbose" == "true" ]; then
	echo "$progress list(s) tidied."
fi
