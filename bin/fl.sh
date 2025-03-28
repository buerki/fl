#!/bin/bash -
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:"$HOME/bin"" # needed for Cygwin
##############################################################################
# written by Andreas Buerki
# requires fl-density.sh and its dependencies, incl. tidy.sh
####
version="0.5.4"
copyright="(c) 2017, 2020, 2021, 2025 Cardiff University; Licensed under the EUPL v. 1.2 or later"
# DESCRRIPTION: annotates texts with formulae from a database
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
##############################################################################
#
################# defining variables ###############################
export extended="-r"
export LC_ALL="en_GB.UTF-8"
################# defining functions ###############################
#
#######################
# define help function
#######################
help ( ) {
	echo "
DESCRRIPTION: $(basename $0) performs a number of functions based on text files
              and a database of formulaic language expressions.
SYNOPSIS:     $(basename $0) [OPTIONS]

OPTIONS:      -d    run in debugging mode
              -h    display this help message
              -V    display version number
              
FUNCTIONS:    The following functions are accessed interactively:
              A: annotation of text files with expressions of the database (also includes L)
              L: listing of expressions from database found in particular file(s)
              D: calculation of fl-density (number of expressions / word count)
              W: calculation of fl-density (number of words in expressions / word count)
              w: calculation of fl-density (both number words in expressions/ word count
                 as well as number of expressions / word count; consolidated, i.e. counted
                  only once); type-token ratio (TTR) for expressions also shown.

GLOSSARY:     fl = formulaic language
              fl-words = number of word tokens in fl expressions
              fl-types = number of formulaic language expression types
              fl-tokens = number of formulaic language expression tokens
              fl-density = density of fl in a text (details depend on options)
              TTR = formulaic language expression type to token ratio
              consolidated fl-words = fl-word tokens without duplicate counting of words
              consolidated fl tokens = fl expression tokens when overlaps between expressions
                                       are consolidated into one single expression
              consolidated fl-types or tokens = overlapping expressions counted as single 
                                                expression

NOTE:         This script is a wrapper for fl-density.sh; to obtain more
              information about processing options (not all of which are
              available through fl.sh) type: fl-density.sh -h
"
}
#######################
# define add_windows_returns function
#######################
add_windows_returns ( ) {
sed 's/$/\r/' "$1"
}
#######################
# define remove_windows_returns function
#######################
remove_windows_returns ( ) {
sed 's/\r//' "$1"
}
#######################
# define splash function
#######################
splash ( ) {
printf "\033c"
echo "fl  $copyright"
echo
echo
echo "          FL"
echo "          version $version"
echo 
echo
echo "          What would you like to do? Type A,L,D,W,w or H and press ENTER."
echo
echo "          A   annotate a text file with occurrences of formulaic sequences."
echo "              (this additionally produces lists of sequences as in L)"
echo
echo "          L   produce a list of formulaic sequences found in a text file."
echo
echo "          D   calculate the formulaic language density of a text file based"
echo "              on expression tokens."
echo
echo "          W   calculate the formulaic language density of a text file based"
echo "              on word tokens that are part of formulaic expressions."
echo
echo "          w   same as 'W' and 'D', but with overlapping expressions"
echo "              (including the words in them) consolidated."
echo
echo "          H   display help, including a glossary of terms"
echo
echo "          x   exit"
echo
read -p '           ' procedure  < /dev/tty
case $procedure	in
	A|a)	:
	;;
	L|l)	:
	;;
	W|w)	:
	;;
	D|d)	:
	;;
	H|h)	clear; help; exit 0
	;;
	X|x)    exit 0
	;;
	*)	echo
		echo "          $procedure is not a valid choice. Please try again."
		read -p '           ' procedure  < /dev/tty
	;;
esac
printf "\033c"
echo
echo
echo
echo
echo 
echo 
echo
echo "          Drag the plain text file to annotate (or a directory with plain text files in it)"
echo "          into this window and press ENTER."
echo 
read -p '           ' infile  < /dev/tty
if [ "$(grep ' ' <<< "$infile")" ]; then
	echo "The path to the folder includes a space. This will cause errors in processing. Please put the textfiles into a path without spaces (for example by replacing spaces in folder names with underscores) and try again."
exit 0
fi
# get rid of any single quotation marks that might have attached
export infile="$(sed "s/'//g" <<<"$infile")"
checking
}
#######################
# define checking function
#######################
checking ( ) {
# check if anything was entered
if [ -z "$infile" ]; then
	echo "          A textfile must be provided. Please drop the file into this window and press ENTER."
	read -p '           ' infile  < /dev/tty
	if [ -z "$infile" ]; then
		echo "No data provided." >&2; sleep 1
		splash
		return
	fi
elif [ "$(grep .txt <<< $infile)" ]; then
	:
elif [ -d $infile ]; then
	:
else
	echo "ERROR: the textfile provided must be a plain text file with extension .txt."
	echo "Please drop the file into this window, or press ENTER to exit."
	if [ -z "$infile" ]; then
		echo "No data provided." >&2; sleep 1
		splash
		return
	elif [ "$(grep .txt <<< $infile)" ]; then
		:
	else
		echo "ERROR: file provided is not a plain text file with extension .txt."; sleep 1
		splash
		return
	fi
fi
# remove any Windows returns from in-file
if [ -d "$infile" ]; then
	for file in $(ls $infile); do
		remove_windows_returns "$infile/$file" > "$infile/$file."
		mv "$infile/$file." "$infile/$file"
	done
else
	remove_windows_returns "$infile" > "$infile."
	mv "$infile." "$infile"
fi
}
#######################
# define make SCRATCHDIRs function
#######################
make_SCRATCHDIRs ( ) {
	################ create scratch directories
	# for the outputNGP
	export SCRATCHDIR1=$(mktemp -dt NGP1XXX) 
	# if mktemp fails, use a different method to create the SCRATCHDIR
	if [ "$SCRATCHDIR1" == "" ] ; then
		mkdir ${TMPDIR-/tmp/}NGP1XXX.1$$
		SCRATCHDIR1=${TMPDIR-/tmp/}NGP1XXX.1$$
	fi
	# for spare
	export SCRATCHDIR2=$(mktemp -dt NGP2XXX) 
	# if mktemp fails, use a different method to create the SCRATCHDIR
	if [ "$SCRATCHDIR2" == "" ] ; then
		mkdir ${TMPDIR-/tmp/}NGP2XXX.1$$
		SCRATCHDIR2=${TMPDIR-/tmp/}NGP2XXX.1$$
	fi
	# another one to keep other auxiliary and temporary files in
	export SCRATCHDIR=$(mktemp -dt NGPXXX) 
	# if mktemp fails, use a different method to create the SCRATCHDIR
	if [ "$SCRATCHDIR" == "" ] ; then
		mkdir ${TMPDIR-/tmp/}NGPXXX.1$$
		SCRATCHDIR=${TMPDIR-/tmp/}NGPXXX.1$$
	fi
	if [ "$diagnostic" ]; then
		open $SCRATCHDIR $SCRATCHDIR1 $SCRATCHDIR2 $R_SCRATCHDIR
	fi
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
if [ "$(grep '.csv' <<< "$1")" ]; then
	if [ -e "$1" ]; then
		add=-
		count=1
		new="$(sed 's/\.csv//' <<< "$1")"
		while [ -e "$new$add$count.csv" ];do
			(( count += 1 ))
		done
	else
		count=
		add=
	fi
	output_filename="$(sed 's/\.csv//' <<< "$1")$add$count.csv"
elif [ "$(grep '.lst' <<< "$1")" ]; then
	if [ -e "$1" ]; then
		add=-
		count=1
		new="$(sed 's/\.lst//' <<< "$1")"
		while [ -e "$new$add$count.lst" ];do
			(( count += 1 ))
		done
	else
		count=
		add=
	fi
	output_filename="$(sed 's/\.lst//' <<< "$1")$add$count.lst"
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
		while [ -e "$1"-$count ]
			do
			(( count += 1 ))
			done
	else
		count=
		add=
	fi
	output_filename=$(echo "$1$add$count")
fi
}
############### end defining functions #####################

# check what platform we're under
platform=$(uname -s)
# and make adjustments accordingly
if [ "$(grep 'Darwin' <<< $platform)" ]; then
	extended="-E"
	DARWIN=true
else
	LINUX=true
fi
# analyse options
while getopts dhV opt
do
	case $opt	in
	d)	diagnostic="-d"
		echo "Running in debug mode";sleep 1
		;;
	h)	help
		exit 0
		;;
	V)	echo "$(basename "$0")	-	version $version"
		echo "$copyright"
		exit 0
		;;
	esac
done
shift $((OPTIND -1))
printf "\033c"
splash
##### select database
printf "\033c"
echo 
echo 
echo
echo "          Drag the database file into this window and press ENTER."
echo "           (alternatively, just press ENTER to see more information)"
echo 
echo 
read -p '           ' db  < /dev/tty
if [ "$(grep ' ' <<< "db")" ]; then
	echo "The path to the folder includes a space. This will cause errors in processing. Please put the textfiles into a path without spaces (for example by replacing spaces in folder names with underscores) and try again."
exit 0
elif [ -z "$db" ] || [ -z '$(grep '_' "$db")' ] ; then
	echo "              NOTE ON REQUIRED DATABASE FORMAT"
	echo "              database files must be of the following format"
	echo "               n_gram_one_"
	echo "               n_gram_two_"
	echo "               ..."
	echo "              That is, underscores in place of spaces with trailing underscores and one"
	echo "              n-gram per line. The database has to be sorted listing longest n-grams first and shortest last."
	echo 
	echo
	echo "              To exit the programme, press ctrl-c"
	echo "              To proceed, drag the database file into this window and press ENTER."
	echo
	echo
	read -p '           ' db  < /dev/tty
	if [ "$(grep ' ' <<< "db")" ]; then
		echo "The path to the folder includes a space. This will cause errors in processing. Please put the textfiles into a path without spaces (for example by replacing spaces in folder names with underscores) and try again."
	exit 0
	fi
fi
# get rid of any single quotation marks that might have attached
export db="$(sed "s/'//g" <<<"$db")"
############### routine for procedure A
if [ "$procedure" == A ] || [ "$procedure" == a ]; then
	##### select annotation type
	printf "\033c"
	echo 
	echo 
	echo
	echo "        Please type one of the following options and press ENTER"
	echo
	echo "            MD = annotate using markdown"
	echo "           XML = annotate using XML tags"
	echo "             U = annotate using underscores between words of formulaic sequences"
	echo 
	echo 
	read -p '           ' format  < /dev/tty
	if [ "$format" == "MD" ] || [ "$format" == "XML" ] || [ "$format" == "U" ]; then
		:
	else
		format=MD
	fi

	echo
	echo "Processing file...        (this may take a while)"
	echo
	fl-density.sh $diagnostic -iNA "$format" "$infile" "$db"
	if [ "$diagnostic" ]; then
		echo "fl-density.sh $diagnostic -iNA $format $infile $db"
	fi
	echo
	echo "          Annotated file and list of formulae placed in $(pwd)."
	echo "          Would you like to open the output directory?"
	echo "          (Y) yes       (N) no"
	echo
	read -p '          > ' a  < /dev/tty
	if [ "$a" == "y" ] || [ "$a" == "Y" ] || [ -z "$a" ]; then
		if [ "$(grep 'Darwin' <<< $platform)" ]; then
			open "$(pwd)"
		else
			xdg-open "$(pwd)"
		fi
	fi
############ routine for procedure L
elif [ "$procedure" == l ] || [ "$procedure" == L ]; then
	echo
	echo "Processing file...        (this may take a while)"
	echo
	fl-density.sh $diagnostic -Liu "$infile" "$db"
	if [ "$diagnostic" ]; then
		echo "fl-density.sh -Liu $infile $db"
	fi
	# 
	echo
	echo "          List of formulae placed in $(pwd)."
	echo "          Would you like to open the output directory?"
	echo "          (Y) yes       (N) no"
	echo
	read -p '          > ' a  < /dev/tty
	if [ "$a" == "y" ] || [ "$a" == "Y" ] || [ -z "$a" ]; then
		if [ "$(grep 'Darwin' <<< $platform)" ]; then
			open "$(pwd)"
		else
			xdg-open "$(pwd)"
		fi
	fi
########### routine for procedure W
elif [ "$procedure" == W ]; then
		echo
		fl-density.sh $diagnostic -iu "$infile" "$db"
		if [ "$diagnostic" ]; then
			echo "fl-density.sh -iu $infile $db"
		fi
		echo " Press ENTER to exit the programme."
		read -p ''	
########### routine for procedure w
elif [ "$procedure" == w ]; then
		echo
		fl-density.sh $diagnostic -i "$infile" "$db"
		if [ "$diagnostic" ]; then
			echo "fl-density.sh -i $infile $db"
		fi
		echo " Press ENTER to exit the programme."
		read -p ''	
########### routine for procedure D
elif [ "$procedure" == D ] || [ "$procedure" == d ]; then
	echo
	fl-density.sh $diagnostic -inu "$infile" "$db"
	if [ "$diagnostic" ]; then
		echo "fl-density.sh -inu $infile $db"
	fi
	echo " Press ENTER to exit the programme."
	read -p ''	
else
	echo "ERROR: $procedure is not a valid choice. Exiting."
fi
