#!/bin/bash -
##############################################################################
# fl-density.sh 
copyright="(c) Cardiff University 2016, 2017, 2020, 2021, 2025; Licensed under the EUPL v. 1.2 or later written by Andreas Buerki"
version='0.5.5'
####
# DESCRRIPTION: calculates formulaic language density of a text, given a database
# SYNOPSIS:     fl-density.sh FILE/DIR DATABASE
###############
# dependencies:
# TreeTagger, NGP (http://buerki.github.io/ngramprocessor/)
############### settings for incorporation of Tree Tagger
# the -a, -s, -i, -m, -M and -f options rely on the use of TreeTagger (http://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/)
# the following variables need to be set in relation to the TreeTagger installation:
TOKENIZER='utf8-tokenize.pl'
ABBR_LIST="${HOME}/bin/en-abr-adjusted"
TAGGER='tree-tagger'
PARFILE="${HOME}/bin/english.par"
LEXFILE="${HOME}/bin/english-lexicon.txt"
############### contraction lists (relative to TreeTagger format)
word_contractions="'d_MD|'d_VHD|'ll_MD|n't_RB"
verb_contractions="'m_VBP|'re_VBP|'s_VBZ|'ve_VH|'ve_VHP"
possessive_s="'s_POS"
############### other presets
export extended="-r"
# initialise processing variables
wc= # the wordcount of each document as it is processed (global wc -w)
tokencount= # the wordcount of each document as it is processed with any adjustments (in -D,-1,-2)
fl_word_tokens_consolidated= # number of consolidated word tokens part of fl expressions
fl_word_tokens_unconsolidated= # unconsolidated word tokens part of expressions in current doc
fl_tokens_unconsolidated= # number of expression tokens of current doc
fl_tokens_consolidated= # number of consolidated expression tokens of current doc
fl_types_unconsolidated= # number of expression types of current doc
fl_types_consolidated= # detail count of consolidated fl types (first, actual types)
fl_density= # fl-density of current doc (type of density depends on options)
######################
# define help function
######################
help ( ) {
	echo "
Usage: fl-density.sh [OPTIONS] FILE/DIR DATABASE
Example: fl-density.sh test_dir ../FL-db
Options: 
-a  use this script as auxiliary script: only return fl-density score; output of -D option
    (if active) diverted to a log file within 'details' directory
-A [MD|XML|U] annotate source texts with formulaic sequences detected (time-intensive!)
    MD = annotate using markdown
    XML = annotate using XML tags
    U = annotate using underscores between words of formulaic sequences
-d  debugging mode
-D  display details of FL-density calculation, incl. list of all FSs found in input text
-h  display this message
-i  ignore case when matching formulaic sequences to text (otherwise matches are case sensitive)
-L  output list of n-grams found in document(s) instead of density (unless -a active, the list is also
    produced as saved as txt document.
-s DATABASE sort the database from longest to shortest sequence (and do nothing else)
-S  skip the automatic length-sorting of the database (shorter process id db is known to be sorted)
-n  calculate density based on number of formulaic expressions per word of text rather than
    number of words part of formulaic expressions per word of text.
-N  no density: do not produce density score (e.g. in conjunction with -A)
-u  use unconsolidated fl-word counts (or item counts if -n active) when calculating fl-density 
    (i.e. words in overlapping formulaic sequences are counted as though they did not overlap,
    that is, the overlapping words are not deducted from the fl-word count; if -n option active,
    if two items of FL overlap, they are still counted as 2 items of FL rather than a single item).
-V  display version information
-v  verbose
-1  do not count contractions as two words, i.e. you're, don't, etc. are only one word
-2  count contractions as two words, but possessive 's is not a separate word.
-5  go over text with an additional 5th pass to increase likelihood of all overlapping sequences
    being caught.

NOTE ON DEPENDENCIES: this version of fl-density.sh requires the N-Gram Processor (NGP) to work.
    the NGP can be downloaded from http://buerki.github.io/ngramprocessor/

NOTE ON DATABASE FORMAT: 
    database files must be of the following format:
       n_gram_one_
       n_gram_two_
       ...
     That is, underscores in place of spaces with trailing underscores and one
     n-gram per line. Before the first use, the database has to be sorted using the -s option.

NOTE on word counts: Words can be counted in various sensible ways. The standard way this 
     programme counts words is by using the unix utility 'wc'. It counts space-separated 
     sequences as words, including punctuation marks if space-separated, so \"won't\" is
     one word and \"red-faced\" is one word, but \"gone – well\" is three words.
     Option -1 changes this behaviour to count strings only of alphanumeric characters (hyphen
     and '+' are also considered alphanumeric here) as a word. Contractions are also counted
     as one word, where contractions are defined as the following: 'll / n't / 'm / 's [=is] / 
     're / 'd / 've / 's [= possessive]. Hyphenated words (e.g. bus-stop) are counted as one. 
     Option -2 counts contractions as separate words, but does NOT count possessive 's, as
     \"'s\" in \"Paul's\", as separate words. Contractions other than those defined above 
     (e.g. ma'am) count as one word in all cases.
     To check details of what is counted as a word (or character), use the -D option which 
     prints a exact log where each (non-fl) word counted is shown on a separate line and tagged
     'w'. Even if neither option -1 nor -2 are active, the wordcount of the log can differ from
     the global wordcount of a text performed by the 'wc' utility because the detailed count only
     counts words (no punctuation marks). The global word count is used for calculating density
     and other ratios unless options -1 or -2 are active. If these options are active, the
     respective detailed word counts are used for calculations in place of the global word counts
     supplied by the 'wc' utility.
"|more
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
if [ "$(grep -E '.csv$' <<<"$1")" ]; then
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
elif [ "$(grep -E '.md$' <<<"$1")" ]; then
	if [ -e "$1" ]; then
		add=-
		count=1
		new="$(sed 's/\.md//' <<< "$1")"
		while [ -e "$new$add$count.md" ];do
			(( count += 1 ))
		done
	else
		count=
		add=
	fi
	output_filename="$(sed 's/\.md//' <<< "$1")$add$count.md"
elif [ "$(grep -E '.dat$' <<< "$1")" ]; then
	if [ -e "$1" ]; then
		add=-
		count=1
		new="$(sed 's/\.dat//' <<< "$1")"
		while [ -e "$new$add$count.dat" ];do
			(( count += 1 ))
		done
	else
		count=
		add=
	fi
	output_filename="$(sed 's/\.dat//' <<< "$1")$add$count.dat"
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
elif [ "$(grep -E '.xml$' <<<"$1")" ]; then
	if [ -e "$1" ]; then
		add=-
		count=1
		new="$(sed 's/\.xml//' <<< "$1")"
		while [ -e "$new$add$count.xml" ];do
			(( count += 1 ))
		done
	else
		count=
		add=
	fi
	output_filename="$(sed 's/\.xml//' <<< "$1")$add$count.xml"
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
	output_filename=$(echo ""$1"$add$count")
fi
}
#########################
# define sort db function
#########################
sort_db ( ) {
add_to_name "$1.bkup"
echo "Processing $1 ..." >&2 
mv "$1" "$output_filename"
for line in $(cat "$output_filename"); do echo "$line  $(tr -dc '_' <<<$line | wc -c)"; done | sort -nrk 2 | cut -d ' ' -f 1 > "$1"
echo "Processing complete." >&2 
}
#################################
# define counts FS-words function
#################################
count_fs_words ( ) {
fls="$(while read; do fgrep $ignore_case -o " $REPLY" <<<"$in";done <<< "$db")"
			if [ "$debug" ]; then
				echo "fls:"
				echo "$fls"
			fi
			# write list to SCRATCHDIR
			echo "$fls" >> $SCRATCHDIR/fls.txt
			# count words contained in fls variable and write count to fl.txt (unless -L option active)
			if [ -z "$list" ]; then
				echo "$(wc -w <<< $fls ) + " >> $SCRATCHDIR/fl.txt
			fi
			# eliminate duplicate strings in $fls
			fls="$(uniq <<<"$fls")"
			# if fls were empty, make it 0
			if [ -z "$fls" ]; then
				fls=0
			fi
}
#######################
# define get_pos functions
#######################
get_pos ( ) {
if [ "$debug" ]; then
	echo "calling get_pos"
fi
# get the parts-of-speech for relevant_txt
# if option supplied, get POS and tokens, otherwise get POS only
# SENT tag is adjusted so that multiples are reduced to a single occurrence and end-sentence punct before ) is labeled NOTHING
if [ "$1" ]; then
	pos=$($TOKENIZER -e -a "$ABBR_LIST" <<< "$assembled_txt" | grep -v '^$' | $TAGGER -pt-with-lemma -hyphen-heuristics -token -quiet "$PARFILE" | tr '\n' ' ' | sed -e 's/\$/DOLLAR/g' -e 's/$./SENT/g' -e 's/SENT SENT/SENT/g' -e 's/SENT SENT/SENT/g' -e 's/:/SENT/g' -e 's/SENT )	)/NOTHING )	)/g' )
else
	pos=$($TOKENIZER -e -a "$ABBR_LIST" <<< "$assembled_txt" | grep -v '^$' | $TAGGER -pt-with-lemma -hyphen-heuristics -quiet "$PARFILE" | tr '\n' ' ' | sed -e 's/\$/DOLLAR/g' -e 's/$./SENT/g' -e 's/SENT SENT/SENT/g' -e 's/SENT SENT/SENT/g' -e 's/:/SENT/g' -e 's/ $//g' -e 's/SENT )	)/NOTHING )	)/g')
fi
if [ "$debug" ]; then
	echo "tagged text:"
	$TOKENIZER -e -a "$ABBR_LIST" <<< "$assembled_txt" | grep -v '^$' | $TAGGER -pt-with-lemma -hyphen-heuristics -token -quiet "$PARFILE" | tr '\n' ' ' | sed -e 's/\$/DOLLAR/g' -e 's/$./SENT/g' -e 's/SENT SENT/SENT/g' -e 's/SENT SENT/SENT/g' -e 's/:/SENT/g' -e 's/ $//g' -e 's/SENT )	)/NOTHING )	)/g'
fi
}
#######################
# define annotation_pass function
#######################
annotation_pass ( ) {
while read; do assembled_txt="$(sed $extended -e "s/([^_])[_ ]$(sed $extended -e 's/^ //g' -e 's/ $//g' -e "s/ /[_ ]+/g" -e 's/[_ ]$//g' -e 's/^[_ ]/_/g' <<<"$REPLY")( |_)([^_])/\1 _$(sed "s/ /_/g" <<<"$REPLY")_ \3/" -e 's/_ ([[:alnum:]]+_)/_\1/g' -e 's/(_[[:alnum:]]+) /\1/g' -e  's/_([[:alnum:]]+)__([[:alnum:]]+)_/_\1_\2_/g' -e  's/_([[:alnum:]]+)__([[:alnum:]]+)_/_\1_\2_/g' <<<"$assembled_txt")";done <<<"$fls"
}
#######################
# define get_details function (carries out word counts and optionally displays the details (if -D active))
#######################
get_details ( ) {
# reset counter
tokencount=0
# calculate measure inside detail_container
get_pos with_tokens
fl_word_tokens_consolidated=0
# look at pos-tagger output word by word
for line in $(sed -e 's/_/UNDERSCORE/g' -e 's/	/_/g' -e "s/\'\'/_SYM/g" <<<"$pos"); do
	(( linecount += 1 ))
	# if we have a FS
	if [ "$(grep -E 'UNDERSCOREUNDERSCORE' <<<"$line")" ]; then
		#sed $extended -e 's/_.+\$*$/	FS of length /' <<<"$line"
		fl_line=$(sed -e 's/_[[:upper:]]*//g' -e 's/UNDERSCORE/_/g' <<<"$line")
		fl_wc=$(sed 's/_/ /g' <<<$fl_line | wc -w | sed 's/ //g')
		(( fl_tokens_consolidated += 1 ))
		if [ "$detail" ]; then 
			if [ "$aux" ]; then echo "$fl_line	formulaic ($fl_wc words)">> $log_name
			else echo "$fl_line	formulaic ($fl_wc words)"; fi
		fi
		(( fl_word_tokens_consolidated += $fl_wc))
		fl_types_consolidated="$fl_types_consolidated
$fl_line"
	# if we have a verb
	elif [ "$(grep -E '_V[[:upper:]]+$' <<<"$line")" ]; then
			# if -1 option is active and we have a contracted verb
			if [ "$wc_option_1" ] && [ "$(grep -E "$verb_contractions" <<<"$line")" ];then
				# we must not count contractions as separate words
				if [ "$detail" ]; then 
					if [ "$aux" ]; then sed $extended -e 's/_[[:upper:]]+$//' <<<"$line" >> $log_name
					else sed $extended -e 's/_[[:upper:]]+$//' <<<"$line"; fi
				fi
			else
				if [ "$detail" ]; then
					if [ "$aux" ]; then sed $extended -e 's/_[[:upper:]]+$/	w/' <<<"$line" >> $log_name
					else  sed $extended -e 's/_[[:upper:]]+$/	w/' <<<"$line"; fi
				fi
				(( tokencount += 1 ))
			fi
	elif [ "$(grep -E '^\+_' <<<"$line")" ]; then
		if [ "$detail" ]; then 
			if [ "$aux" ]; then
				echo "$(sed $extended 's/_([[:upper:]]|[[:punct:]])*$//g' <<<"$line")	w" >> $log_name
			else
				echo "$(sed $extended 's/_([[:upper:]]|[[:punct:]])*$//g' <<<"$line")	w"
			fi
		fi
		(( tokencount += 1 ))
	# if we have punctuation, let through 
	elif [ "$(grep -E '^[[:punct:]]_' <<<"$line")" ]; then
		if [ "$detail" ]; then 
			if [ "$aux" ]; then sed $extended 's/_([[:upper:]]|[[:punct:]])*$//g' <<<"$line" >> $log_name
			else sed $extended 's/_([[:upper:]]|[[:punct:]])*$//g' <<<"$line" ; fi
		fi
	# if we have a symbol
	elif [ "$(grep -E '_SYM$' <<<"$line")" ]; then
		# except for a '+' which is counted as word)
		if [ "$(grep -E '\+_SYM$' <<<"$line")" ]; then
			if [ "$detail" ]; then
				if [ "$aux" ]; then sed 's/_SYM/	w/g' <<<"$line" >>$log_name
				else sed 's/_SYM/	w/g' <<<"$line"; fi
			fi
			(( tokencount += 1 ))
		else
			if [ "$detail" ]; then 
				if [ "$aux" ]; then sed 's/_SYM//g' <<<"$line" >> $log_name
				else  sed 's/_SYM//g' <<<"$line" ;fi
			fi
		fi
	# if we have an end of sentence tag
	elif [ "$(grep -E 'SENT$' <<<"$line")" ]; then
		echo '	'
	# if we have a normal token
	else
		# if wordcount option -1 is active,
		if [ "$wc_option_1" ];then
			# we must not count contractions as separate words, so we filter them out
			if [ "$(grep -E "$word_contractions|$possessive_s" <<<"$line")" ]; then
				if [ "$detail" ]; then 
					if [ "$aux" ]; then sed $extended -e 's/_.+\$*$//' <<<"$line" >> $log_name
					else sed $extended -e 's/_.+\$*$//' <<<"$line";fi # cut off the tag
				fi
			else
				if [ "$detail" ]; then 
					if [ "$aux" ]; then sed $extended -e 's/_.+\$*$/	w/' <<<"$line" >> $log_name
					else sed $extended -e 's/_.+\$*$/	w/' <<<"$line";fi # cut off the tag but show as word
				fi
				(( tokencount += 1 ))
			fi
		elif [ "$wc_option_2" ]; then
			# we must not count possessive -s as separate words, so we filter them out
			if [ "$(grep -E "$possessive_s" <<<"$line")" ]; then
				if [ "$detail" ]; then
					if [ "$aux" ]; then sed $extended -e 's/_.+\$*$//' <<<"$line" >> $log_name
					else sed $extended -e 's/_.+\$*$//' <<<"$line" ;fi # cut off the tag
				fi
			else
				if [ "$detail" ]; then 
					if [ "$aux" ]; then sed $extended -e 's/_.+\$*$/	w/' <<<"$line" >> $log_name
					else sed $extended -e 's/_.+\$*$/	w/' <<<"$line";fi # cut off the tag but show as word
				fi
				(( tokencount += 1 ))
			fi
		else
			if [ "$detail" ]; then
				if [ "$aux" ]; then sed $extended -e 's/_.+\$*$/	w/' <<<"$line" >>$log_name
				else  sed $extended -e 's/_.+\$*$/	w/' <<<"$line";fi # cut off the tag but show it was a word
			fi
			(( tokencount += 1 ))
		fi
	fi
	if [ $linecount -eq 30 ] && [ "$detail" ]; then
		if [ -z "$fl_tokens_consolidated" ]; then
			fl_tokens_consolidated=0
		fi
		if [ "$wc_option_1" ] || [ "$wc_option_2" ]; then
			non_fl_wc="$tokencount non-fl word tokens, "
		fi
		if [ "$aux" ]; then
			echo "--- intermediate tallies: $non_fl_wc$fl_word_tokens_consolidated fl-word tokens (consolidated), $fl_tokens_consolidated fl-tokens (consolidated) ---" >> $log_name
		else
			echo "--- intermediate tallies: $non_fl_wc$fl_word_tokens_consolidated fl-word tokens (consolidated), $fl_tokens_consolidated fl-tokens (consolidated) ---"
		fi
		linecount=0
	fi
done
# calculate number of consolidated fl_types
if [ "$debug" ]; then
	echo "fl-types (consolidated):"
	sort <<< "$fl_types_consolidated" | uniq -c
fi	
fl_types_consolidated=$(sort <<< "$fl_types_consolidated" | uniq | wc -l)
fl_types_consolidated=$(( fl_types_consolidated -1 )) # adjust for first (empty) line
if [ "$wc_option_1" ] || [ "$wc_option_2" ]; then
	non_fl_wc="$tokencount non-fl word tokens, "
fi
if [ "$aux" ]; then
	echo "--- final tallies: $non_fl_wc$fl_word_tokens_consolidated fl-word tokens (consolidated), $fl_tokens_consolidated fl-tokens (consolidated) ---" >> $log_name
else
	echo "--- final tallies: $non_fl_wc$fl_word_tokens_consolidated fl-word tokens (consolidated), $fl_tokens_consolidated fl-tokens (consolidated) ---"
fi
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
############# END DEFINING FUNCTIONS ##################
# analyse options
while getopts A:aDdhijLnNs:SuvV125 opt
do
	case $opt	in
	A)	annotate=$OPTARG
		case $annotate in
		    MD)	:
				;;
		    XML)	:
				;;
		    U)	:
				;;
			*)	echo "$annotate is not a recognised mode; will use MD."
				annotate=MD
				;;
		esac
		;;
	a)	aux=true
		;;
	d)	debug=true
		verbose=true
		;;
	D)	detail=true
		;;
	h)	help
		exit 0
		;;
	n)	number=true
		;;
	N)	no_density=true
		;;
	i)	ignore_case="-i"
		echo "ignoring case" >&2
		;;
	L)	list=true
		;;
	s)	sort_db $OPTARG
		exit 0
		;;
	S)	skip_length_sort=true
		;;
	u)	unconsolidated=true
		;;
	v)	verbose=true
		;;
	V)	echo "$(basename $0)	-	version $version"
		echo "$copyright"
		exit 0
		;;
	1)	wc_option_1=true
		;;
	2)	wc_option_2=true
		;;
	5)	fifth_pass=true
		;;
	esac
done
shift $((OPTIND -1))
#############################
# Preliminaries
#############################
# produce error if NGP not installed
if command -v multi-list.sh > /dev/null 2>&1; then
	:
else
	echo "WARNING: NSP cannot be found on this computer, but is required. Please" >&2
	echo "install the NSP and try again." >&2
	echo "The NSP can be downloaded here: http://buerki.github.io/ngramprocessor/" >&2
	exit 1
fi
# run initial plausibility checks
# check if 2 args supplied
if [ $# == 2 ]; then
	# check if first arg is a dir or file
	if [ -d "$1" ]; then
		dir=true
		echo "input directory provided..." >&2
	elif [ -e "$1" ]; then
		:
	else
		echo "ERROR: $1 does not exist" >&2
		exit 1
	fi
	# check if db exists
	if [ -e "$2" ]; then
		:
	else
		echo "ERROR: $2 does not exist" >&2
		exit 1
	fi
elif [ $# == 1 ]; then
	# we assume this is a db
	# check if db exists
	if [ -e "$1" ]; then
		:
	else
		echo "ERROR: $1 does not exist" >&2
		exit 1
	fi
else
	echo "ERROR: please either supply a file and a database as arguments or pipe text in and provide a database as argument." >&2
fi
# check if word count options conflict
if [ "$wc_option_1" ] && [ "$wc_option_2" ];then
	echo "WARNING: options -1 and -2 cannot be active at the same time; option will be -1 deactivated." >&2
	wc_option_1=
fi
# create scratch directories
SCRATCHDIR=$(mktemp -dt fldensityXXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
if [ "$SCRATCHDIR" == "" ] ; then
	mkdir ${TMPDIR-/tmp/}fldensity.1$$
	SCRATCHDIR=${TMPDIR-/tmp/}fldensity.1$$
fi
# check what platform we're under
platform=$(uname -s)
# and make adjustments accordingly
if [ "$(grep 'CYGWIN' <<< $platform)" ]; then
	alias clear='printf "\033c"'
	echo "running under Cygwin"
	CYGWIN=true
elif [ "$(grep 'Darwin' <<< $platform)" ]; then
	extended="-E"
	DARWIN=true
else
	LINUX=true
fi
# open SCRATCHDIR if in debug
if [ "$debug" ]; then
	if [ "$CYGWIN" ]; then
		cygstart $SCRATCHDIR
	elif [ "$(grep 'Darwin' <<< $platform)" ]; then
		open $SCRATCHDIR
	else
		xdg-open $SCRATCHDIR
	fi
fi
# put db into memory
if [ "$pipe" ]; then
	db="$(tr '_' ' ' < "$1" | sed -e 's/(/LBRACKET/g' -e 's/)/RBRACKET/g')"
	db_name="$1"
else
	db="$(tr '_' ' ' < "$2" | sed -e 's/(/LBRACKET/g' -e 's/)/RBRACKET/g')"
	db_name="$2"
fi
# check for duplicates in db
db_entries=$(wc -l <<< "$db" | sed 's/ //g')
if [ "$debug" ]; then
	echo "db_entries: $db_entries"
fi
uniq_db_entries=$(sort -d <<< "$db" | uniq | wc -l | sed 's/ //g')
if [ "$debug" ]; then
	echo "uniq_db_entries: $uniq_db_entries"
fi
if [ $db_entries -ne $uniq_db_entries ]; then
	echo "WARNING: duplicate entries detected in $db_name."
	echo "removing duplicate entries..."
	db="$(sort -d <<< "$db" | uniq)"
	if [ "$debug" ]; then
		echo "list with duplicates removed:"
		echo "$db"
	fi
fi
# sort db by length
db="$(for line in $(sed 's/ /_/g'<<< "$db"); do echo "$line  $(tr -dc '_' <<<$line | wc -c)"; done | sort -nrk 2 | cut -d ' ' -f 1 )"
if [ "$debug" ]; then
	echo "length-sorted db:"
	echo "$db"
fi
# create log dir and file if -a and -D
if [ "$aux" ] && [ "$detail" ]; then
	mkdir details 2> /dev/null
	add_to_name details/FS-density_log.txt
	log_name="$output_filename"
	echo "FL-density calculation using $(basename $0), version $version – $(date)" >> $log_name
	echo "FL-database used: $db_name" >> $log_name
	echo "=======================================================================" >> $log_name
	if [ "$wc_option_1" ]; then echo "word count option -1 active" >> $log_name; fi
	if [ "$wc_option_2" ]; then echo "word count option -2 active" >> $log_name; fi
	if [ "$ignore_case" ]; then echo "case ignorned for matching purposes (option -i)" >> $log_name; fi 
fi
###############################################################
# start processing in-files
###############################################################
if [ -z "$dir" ]; then
	if [ "$pipe" ]; then
		docs=piped_text
	else
		docs="$1"
	fi
else
	docs=$(ls "$1")
	outdir="$(pwd)/"
	cd $1
	if [ -z "$docs" ]; then
		echo "ERROR: $1 is empty."
		exit 1
	fi
fi
#### carry out some prep
# create special n-gram list directories
mkdir $SCRATCHDIR/n-gram_lists
mkdir $SCRATCHDIR/in
tr '\r' '\n' <<< "$db" | grep -v '^$' | sort > $SCRATCHDIR/db.txt
if [ "$debug" ]; then
	echo "Using $db_name as database..."
	echo "sampling $db_name :"
	head $SCRATCHDIR/db.txt
fi
# process each input text
for doc in $docs; do
	# set up counter
	(( current_doc_number += 1 ))
	# say which doc is being processed
	echo "processing $doc" >&2
	# check it exists
	if [ -e "$doc" ]; then
		:
	else
		echo "ERROR: $doc not found."
		exit 1
	fi
	# remove any Windows returns in file
	if [ "$CYGWIN" ]; then
		remove_windows_returns $doc > $doc.
		mv $doc. $doc
	fi
	# make sure there are no issues with line breaks
	tr '\r' '\n' < $doc > $doc.
	mv $doc. $doc
	# write to log
	if [ "$aux" ] && [ "$detail" ]; then
		echo "------- $doc --------" >> $log_name
	fi
	# insert empty space at the beginning of each line
	if [ "$pipe" ]; then
		sed 's/^/ /' <<<"$piped_text" > $SCRATCHDIR/input.txt
	else
		sed 's/^/ /' $doc > $SCRATCHDIR/input.txt
	fi
	# make sure $doc is only basename now
	doc=$(basename $doc)
	#  get wordcount for document
	if [ -z "$list" ]; then
		wc="$(sed 's/\([[:punct:]]\)//g' $SCRATCHDIR/input.txt | wc -w | sed 's/ //g')"
	fi
	################ joining algorhythm kicks in now
	sed -e 's/\([[:punct:]]\)/ \1/g' -e 's/\(-\)/\1 /g' $SCRATCHDIR/input.txt > $SCRATCHDIR/in/input.txt; rm $SCRATCHDIR/input.txt
	size="2 3 4 5 6 7 8 9" # producting all sizes 2 to 9
	for num in $size; do 
		multi-list.sh -vdn $num $SCRATCHDIR/n-gram_lists $SCRATCHDIR/in > /dev/null
		tidy.sh -ad $SCRATCHDIR/n-gram_lists/$num.per_doc/*
	done
	# create list of all n-grams (n = 2 to 9) found in doc
	cat $SCRATCHDIR/n-gram_lists/*.per_doc/* | sed 's/·/_/g' | sort > $SCRATCHDIR/lists.txt
	# create list of n-gram types (+ their freqs) in doc that also appear in db
	join $SCRATCHDIR/lists.txt $SCRATCHDIR/db.txt | sed -e 's/ /	/g' -e s'/_/ /g' -e 's/^/ /g' | sort -rk 2 -t '	' > $SCRATCHDIR/fls.txt
	############################
	# derive number of FS tokens in doc
	fl_tokens_unconsolidated=$(echo "0 $(cut -d '	' -f 2 $SCRATCHDIR/fls.txt | sed 's/^/+ /g' | tr '\n' ' ')" | bc)
	if [ "$debug" ]; then
		echo "Number of FS tokens found: $fl_tokens_unconsolidated"
	fi
	# derive number of FS types in doc
	fl_types_unconsolidated=$(cat $SCRATCHDIR/fls.txt | wc -l | sed 's/ //g')
	# copy list of FSs found (with freqs) to separate list for later output
	cp $SCRATCHDIR/fls.txt $SCRATCHDIR/fls+freqs.txt
	# skip next block if no FSs in the text at all
	if [ $fl_tokens_unconsolidated -eq 0 ]; then
		# create dummy file with zero count to prevent problems later
		echo "0 +" > $SCRATCHDIR/fl.txt
	else
		# cut freqs off of fls.txt, insert underscores
		cut -d '	' -f 1 $SCRATCHDIR/fls+freqs.txt | sed 's/ /_/g' > $SCRATCHDIR/fls.txt
		# sort according to length
		sort_db $SCRATCHDIR/fls.txt
		# take underscores out again
		sed 's/_/ /g' $SCRATCHDIR/fls.txt > $SCRATCHDIR/fls.txt.; mv $SCRATCHDIR/fls.txt. $SCRATCHDIR/fls.txt
		# count words contained in fls.txt and write count to fl.txt (unless -L option active)
		if [ -z "$list" ]; then
			for ngram in $(sed -e 's/	/_/g' -e 's/ /·/g' $SCRATCHDIR/fls+freqs.txt); do
				ngramfreq=$(cut -d "_" -f 2 <<< "$ngram")
				ngram="$(cut -d "_" -f 1 <<< "$ngram" | sed 's/·/ /g')"
				echo "$(wc -w <<< $ngram) * $ngramfreq" | bc >> $SCRATCHDIR/fl.txt
			done
			echo "$(sed 's/$/ + /g' $SCRATCHDIR/fl.txt)" > $SCRATCHDIR/fl.txt.
			mv $SCRATCHDIR/fl.txt. $SCRATCHDIR/fl.txt
		fi
		# annotate if necessary
		if [ -z "$unconsolidated" ] || ( [ "$unconsolidated" ] && [ "$detail" ] ) || ( [ "$unconsolidated" ] && ( [ "$wc_option_1" ] || [ "$wc_option_2" ] ) ); then
			# load necessary files into memory
			#assembled_txt="$(sed -e 's/	/ /g' -e 's/,//g' $SCRATCHDIR/in/input.txt)"
			assembled_txt="$(sed -e 's/	/ /g' -e 's/-/HYPHEE/g' -e 's/&/AMPERSS/g' -e 's/§/PARAGRR/g' -e 's/+/PLUSS/g' -e 's/°/DEGRRR/g' -e 's/%/PERCEE/g' -e 's/[[:punct:]]//g' -e 's/HYPHEE/-/g' -e 's/AMPERSS/\&/g' -e 's/PARAGRR/§/g' -e 's/PLUSS/+/g' -e 's/DEGRRR/°/g' -e 's/PERCEE/%/g' $SCRATCHDIR/in/input.txt)"
			fls=$(cut -d '	' -f 1 $SCRATCHDIR/fls.txt)
			# first pass (double)
			while read; do assembled_txt="$(sed "s/$REPLY/ _$(sed "s/ /_/g" <<<"$REPLY")_ /" <<<"$assembled_txt")";done <<<"$fls"
			while read; do assembled_txt="$(sed "s/$REPLY/ _$(sed "s/ /_/g" <<<"$REPLY")_ /" <<<"$assembled_txt")";done <<<"$fls"
			if [ "$debug" ]; then
				echo "text after first pass: $assembled_txt"
			fi
			# second pass
			annotation_pass
			if [ "$debug" ]; then
				echo "text after second pass: $assembled_txt"
			fi
		fi
	fi
	############################
	# produce list of FSs found if required
	if [ "$aux" ]; then
		if [ "$list" ]; then
			cat $SCRATCHDIR/fls+freqs.txt | sed -e 's/^ //g' -e 's/ /·/g'
		fi
	elif [ "$detail" ] || [ "$annotate" ] || [ "$list" ]; then
		# tidy up and move list of FSs found
		docname=$(sed 's/.txt//' <<<$doc)
		add_to_name $outdir$docname.FSs.txt
		echo "==============================================================================" >  $output_filename
		echo "List of items of formulaic language found in $docname and their frequencies" >> $output_filename
		echo "(these might overlap in the annotated text)" >>  $output_filename
		echo "produced by $(basename $0), version $version on $(date)" >>  $output_filename
		echo "FL-database used: $db_name" >> $output_filename
		echo "------------------------------------------------------------------------------" >>  $output_filename
		 # carry on
		echo "unconsolidated fl-tokens: $fl_tokens_unconsolidated" >>  $output_filename
		echo "unconsolidated fl-types:  $fl_types_unconsolidated" >>  $output_filename
		# calculate TTRs
		if [ $fl_types_unconsolidated -gt 0 ]; then
			TTR_uncons=$(echo "scale=3; $fl_types_unconsolidated/$fl_tokens_unconsolidated" | bc)
		fi
		echo "TTR (unconsolidated): $TTR_uncons" >>  $output_filename
		echo "==============================================================================" >>  $output_filename
		cat $SCRATCHDIR/fls+freqs.txt >> $output_filename
		if [ "$list" ]; then
			cat $output_filename
		fi
		echo "list of formulaic sequences in $doc placed in $(pwd)/$output_filename"
		# remove any Windows returns in file
		if [ "$CYGWIN" ]; then
			remove_windows_returns $output_filename > $output_filename.
			mv $output_filename. $output_filename
		fi
	fi
	# exit if only list was required
	if [ "$list" ]; then
		############################
		# tidy up
		# move files not to be in the way
		if [ "$debug" ]; then
			mv $SCRATCHDIR/sections $SCRATCHDIR/sections$(date +%s) 2>/dev/null
			mv $SCRATCHDIR/fl.txt $SCRATCHDIR/fl.$(date +%s).txt 2>/dev/null
			mv $SCRATCHDIR/n-gram_lists $SCRATCHDIR/n-gram_lists.$(date +%s) 2>/dev/null
			mkdir $SCRATCHDIR/n-gram_lists
			mv $SCRATCHDIR/fls.txt $SCRATCHDIR/fls.$(date +%s).txt 2>/dev/null
		else
			rm -r $SCRATCHDIR/sections 2>/dev/null
			rm $SCRATCHDIR/fl.txt 2>/dev/null
			rm -r $SCRATCHDIR/n-gram_lists/* 2>/dev/null
			rm $SCRATCHDIR/fls.txt 2>/dev/null
		fi		
		# reset variables
		fl=
		wc=
		tokencount=
		fl_word_tokens_consolidated=
		fl_word_tokens_unconsolidated=
		fl_tokens_unconsolidated=
		fl_tokens_consolidated=
		fl_density=
		fl_types_unconsolidated=
		fl_types_consolidated=
		continue
	fi
	############################
	# produce consolidated word token figures if required
	############################
	if [ "$unconsolidated" ] && [ -z "$detail" ] || [ $fl_tokens_unconsolidated -eq 0 ]; then
		# produce assembled text
		assembled_txt="$(cat $SCRATCHDIR/in/input.txt)"
	else
		:
	fi
	if [ "$debug" ]; then
		echo "sampling assembled_txt:"
		head <<< $assembled_txt
	fi
	# if no FSs in the text at all, skip this next block, otherwise carry out 3rd + 4th pass
	if [ $fl_tokens_unconsolidated -gt 0 ]; then
		if [ "$debug" ]; then
			echo "third pass"
		fi
		annotation_pass
		if [ "$debug" ]; then
			echo "fourth pass"
		fi
		annotation_pass
		if [ -z "$fifth_pass" ]; then
			# undo adjustments made earlier for the sake of processing and place output in pwd
			assembled_txt="$(sed $extended -e 's/^ //' -e 's/([[:alnum:]]|\)) ([,;:.?!-])/\1\2/g' -e "s/([[:alnum:]]) '([[:lower:]])/\1'\2/g" -e 's/  –/ –/g' -e 's/ \)/)/g'<<<"$assembled_txt")"
		fi
		# fifth pass if requested
		if [ "$fifth_pass" ]; then
			if [ "$debug" ]; then
				echo "fifth pass"
			fi
			annotation_pass
			# undo adjustments made earlier for the sake of processing and place output in pwd
		assembled_txt="$(sed $extended -e 's/^ //' -e 's/([[:alnum:]]|\)) ([,;:.?!-])/\1\2/g' -e "s/([[:alnum:]]) '([[:lower:]])/\1'\2/g" -e 's/  –/ –/g' -e 's/ \)/)/g'<<<"$assembled_txt")"
		fi
	else
		# undo adjustments made earlier for the sake of processing and place output in pwd
assembled_txt="$(sed $extended -e 's/^ //' -e 's/([[:alnum:]]|\)) ([,;:.?!-])/\1\2/g' -e "s/([[:alnum:]]) '([[:lower:]])/\1'\2/g" -e 's/  –/ –/g' -e 's/ \)/)/g'<<<"$assembled_txt")"
	fi
	#############################
	# if annotation required, re-assemble sections, run another pass and put annotated files in pwd
	#############################
	if [ "$annotate" ]; then
		# process annotated data according to chosen format
		docname=$(sed 's/.txt//' <<<$doc)
		case $annotate	in
				MD)	add_to_name $outdir$docname.md
					sed -e 's/LBRACKET/(/g' -e 's/RBRACKET/)/g' -e 's/\([[:alnum:]]\)_\([[:alnum:]]\)/\1 \2/g' -e 's/_\-_/-/g' -e 's/\([[:alnum:]]\)_\([[:alnum:]]\)/\1 \2/g' <<< "$assembled_txt" > $output_filename
					;;
				U)	add_to_name $outdir$docname.txt
					sed -e 's/__/_/g' -e 's/LBRACKET/(/g' -e 's/RBRACKET/)/g' <<<"$assembled_txt" > $output_filename
					# remove any Windows returns in file
					if [ "$CYGWIN" ]; then
						add_windows_returns $output_filename > $output_filename.
						mv $output_filename. $output_filename
					fi
					;;
				XML)	add_to_name $outdir$docname.xml
					echo '<?xml version = "1.0" encoding = "UTF-8"?>' > $output_filename
					echo '<!DOCTYPE text [' >> $output_filename
					echo '<!ELEMENT text ANY>' >> $output_filename
					echo '<!ELEMENT fl ANY>' >> $output_filename
					echo ']>' >> $output_filename
					echo '<text>' >> $output_filename
					sed -e 's/ __/ <fl>/g' -e 's/^__/<fl>/g' -e 's|__ |</fl> |g' -e 's|__$|</fl>|g' -e 's/_/ /g' -e 's/LBRACKET/(/g' -e 's/RBRACKET/)/g' <<<"$assembled_txt" >> $output_filename
					echo '</text>' >> $output_filename
					# remove any Windows returns in file
					if [ "$CYGWIN" ]; then
						add_windows_returns $output_filename > $output_filename.
						mv $output_filename. $output_filename
					fi
					;;
		esac
		echo "annotated files placed in $(pwd)/$output_filename"
	fi
	############################
	if [ "$debug" ]; then
		echo "wc = $wc"
		if [ $fl_tokens_unconsolidated -gt 0 ]; then
			echo "fl = $(tr '\n' ' ' < $SCRATCHDIR/fl.txt)"
		fi
	fi
	############################
	# carry out any necessary preparatory calculations for fl-density calculation
	############################
	if [ "$no_density" ]; then
		:
	elif [ -z "$detail" ] && [ "$unconsolidated" ] && [ -z "$wc_option_1" ] && [ -z "$wc_option_2" ]; then
		# if no -D, unconsolidated and not -1 or -2, nothing further needs doing
		:
	# in all other cases (i.e. if detail required, consolidated figures or special word count options)
	else
		# we need to derive detailed tallies of wc in and outside of FSs (because either -D is active or consolidation is required 
		# or special word count settings)
		# in this section we have, as of version 0.3.2.2, discrepanies between -j option on non-j; likely due to difference in 
		# the way $assembled_txt is marked up with FLs
		if [ -z "$wc_option_1" ] && [ -z "$wc_option_2" ]; then
			# if no -1/-2
			# set things up to display one word per line
			for word in $assembled_txt; do
				(( linecount += 1 ))
				# if we have an annoted FS
				if [ "$(grep -om 1 '_' <<<$word)" ]; then
					fs_length=$(sed 's/_/ /g' <<<$word | wc -w | sed 's/ //g')
					(( fl_tokens_consolidated += 1 )) # advance count of consolidated FS tokens
					if [ "$detail" ]; then # show that this entry is formulaic and its word count
						if [ "$aux" ]; then echo "$word	formulaic ($fs_length words)" | sed -e 's/LBRACKET/(/g' -e 's/RBRACKET/)/g' >> $log_name
						else echo "$word	formulaic ($fs_length words)" | sed -e 's/LBRACKET/(/g' -e 's/RBRACKET/)/g'
						fi
					fi
					(( fl_word_tokens_consolidated += $fs_length )) # advance count word tokens in consolidated FSs by words in most recent FS
					fl_types_consolidated="$fl_types_consolidated
$word"
				# if we have an apostrophy s, just write it out, no extra counting
				elif [ "$word" == "'s" ]; then
					if [ "$detail" ]; then 
						if [ "$aux" ]; then echo "$word" >>$log_name
						else echo "$word"; fi
					fi
				# if we have a normal word
				elif [ "$(grep -o '[[:alnum:]]' <<<$word)" ]; then
					if [ "$detail" ]; then
						if [ "$aux" ]; then echo "$word	w" | sed -e 's/LBRACKET/(/g' -e 's/RBRACKET/)/g' >> $log_name
						else echo "$word	w" | sed -e 's/LBRACKET/(/g' -e 's/RBRACKET/)/g'; fi
					fi	
					(( tokencount += 1 )) # advance word token count
				# if we have anything else, just show it, no counting
				else
					if [ "$detail" ]; then
						if [ "$aux" ]; then sed -e 's/LBRACKET/(/g' -e 's/RBRACKET/)/g' <<< "$word" >> $log_name
						else sed -e 's/LBRACKET/(/g' -e 's/RBRACKET/)/g' <<< "$word"; fi
					fi
				fi
				# insert intermediate tally every 30 lines
				if [ "$detail" ] && [ $linecount -eq 30 ]; then
					if [ "$wc_option_1" ] || [ "$wc_option_2" ]; then
						non_fl_wc="$tokencount non-fl word tokens, "
					fi
					if [ "$aux" ]; then
					echo "--- intermediate tallies: $non_fl_wc$fl_word_tokens_consolidated fl-word tokens (consolidated), $fl_tokens_consolidated fl-tokens (consolidated) ---" >> $log_name
					else echo "--- intermediate tallies: $non_fl_wc$fl_word_tokens_consolidated fl-word tokens (consolidated), $fl_tokens_consolidated fl-tokens (consolidated) ---"
					fi
					linecount=0 # reset linecount
				fi
			done
			# calculate number of consolidated fl_types
			if [ "$debug" ]; then
				echo "fl-types (consolidated):"
				sort <<< "$fl_types_consolidated" | uniq -c
			fi	
			fl_types_consolidated=$(sort <<< "$fl_types_consolidated" | uniq | wc -l)
			fl_types_consolidated=$(( fl_types_consolidated -1 )) # adjust for first (empty) line
			if [ "$wc_option_1" ] || [ "$wc_option_2" ]; then
				non_fl_wc="$tokencount non-fl word tokens, "
			fi
			if [ "$aux" ]; then
				echo "--- final tallies: $non_fl_wc$fl_word_tokens_consolidated fl-word tokens (consolidated), $fl_tokens_consolidated fl-tokens (consolidated) ---" >> $log_name
			else
				echo "--- final tallies: $non_fl_wc$fl_word_tokens_consolidated fl-word tokens (consolidated), $fl_tokens_consolidated fl-tokens (consolidated) ---"
			fi
			### cross-check wc
			outside=$tokencount
			if [ -z "$fl_word_tokens_consolidated" ]; then
				fl_word_tokens_consolidated=0
			fi
			# add tokens inside FSs to those outside
			(( tokencount += $fl_word_tokens_consolidated ))
			# now check if they agree with value stored in $wc variable
			if [ "$wc" != "$tokencount" ] && [ "$debug" ] && [ -z "$wc_option_1" ] && [ -z "$wc_option_2" ]; then
				echo "NB: wc discrepancy of $wc before and $tokencount in detail. $wc will be used for consistency." >&2
			fi
			if [ "$debug" ]; then
				echo "words outside FL: $outside"
				echo "words within FL (consolidated):  $fl_word_tokens_consolidated"
				echo "words within FL (with overlaps): $(echo "$(tr '\n' ' ' < $SCRATCHDIR/fl.txt) 0 "| bc)"
				echo "FL types (with overlaps): $(wc -l < $SCRATCHDIR/fls+freqs.txt)"
				echo "FL types (without overlaps): $fl_types_consolidated"
			fi
		# if one of -1 or -2 active
		else
			# established detailed token counts according to requirements of -1/-2 options
			get_details
			# add tokens inside FSs to those outside
			(( tokencount += $fl_word_tokens_consolidated ))
			if [ "$debug" ]; then
				echo "wc = $wc"
				echo "tokencount = $tokencount"
				echo "fl_word_tokens_consolidated = $fl_word_tokens_consolidated"
				echo "fl_word_tokens_unconsolidated = $fl_word_tokens_unconsolidated"
				echo "fl_tokens_consolidated = $fl_tokens_consolidated"
				echo "fl_types_consolidated = $fl_types_consolidated"
			fi
		fi
	fi
	############################
	# calculate fl-density 
	############################
	# wc=$(echo "$wc 0" | bc)0
	if [ -z "$no_density" ]; then
		fl_word_tokens_unconsolidated=$(echo "$(tr '\n' ' ' < $SCRATCHDIR/fl.txt) 0 "| bc)
	fi
	if [ "$no_density" ]; then
		:
	elif [ "$unconsolidated" ]; then
		if [ -z "$wc_option_1" ] && [ -z "$wc_option_2" ]; then
			# set tokencount to unix wc established earlier
			tokencount=$wc
		fi
		if [ "$number" ]; then # if density based on unconsolidated fs-tokens
			fl_density=$(echo "scale=6; $fl_tokens_unconsolidated / $tokencount" | bc)
		else # if based on unconsolidated word tokens within expressions
			fl_density=$(echo "scale=6; $fl_word_tokens_unconsolidated / $tokencount" | bc)
		fi
	else
		if [ "$number" ]; then # if density based on consolidated fs-tokens
			fl_density=$(echo "scale=6; $fl_tokens_consolidated / $tokencount" | bc)
		else # if based on unconsolidated word tokens within expressions
			# if no special token count measures, set tokencount to unix wc
			# established earlier (for consistency's sake)
			if [ -z "$wc_option_1" ] && [ -z "$wc_option_2" ]; then
				detailed_tokencount=$tokencount
				tokencount=$wc
			fi
			fl_density=$(echo "scale=6; $fl_word_tokens_consolidated / $tokencount" | bc)
		fi
	fi
	# if $fl_density is empty, set to 0
	if [ -z "$fl_density" ]; then fl_density=0; fi
	##########################
	# output fl-density 
	##########################
	if [ "$no_density" ]; then
		:
	# if input was a whole directory of texts
	elif [ "$dir" ]; then
		if [ "$aux" ]; then
			echo -e $fl_density >> $SCRATCHDIR/result.csv
		else
			# zero fl_tokens_consolidated if empty
			if [ -z "$fl_tokens_consolidated" ]; then
				fl_tokens_consolidated=0
			fi
			# if based on unconsolidated number of word tokens:
			if [ "$unconsolidated" ] && [ -z "$number" ]; then
				if [ $current_doc_number == 1 ]; then
					echo "document	wordcount	fl-word tokens (unconsolidated)	fl-density (unconsolidated)	fl-types (unconsolidated)	fl-tokens (unconsolidated)" >> $SCRATCHDIR/result.csv
				fi
				echo "$doc	$tokencount	$fl_word_tokens_unconsolidated	$fl_density	$fl_types_unconsolidated	$fl_tokens_unconsolidated" >> $SCRATCHDIR/result.csv
			# if based on number of unconsolidated fs-tokens:
			elif [ "$number" ]; then
				if [ "$unconsolidated" ]; then
					if [ $current_doc_number == 1 ]; then
						echo "document	wordcount	fl-tokens (unconsolidated)	fl-density	fl-types (unconsolidated)" >> $SCRATCHDIR/result.csv
					fi
					echo "$doc	$tokencount	$fl_tokens_unconsolidated	$fl_density	$fl_types_unconsolidated" >> $SCRATCHDIR/result.csv
				# if based on number of consolidated fl-tokens
				else
					if [ $current_doc_number == 1 ]; then
						echo "document	wordcount	fl-tokens (consolidated)	fl-density (consolid.)	fl-types (unconsolidated)" >> $SCRATCHDIR/result.csv
					fi
					echo "$doc	$tokencount	$fl_tokens_consolidated	$fl_density	$fl_types_unconsolidated" >> $SCRATCHDIR/result.csv
				fi
			# if based on consolidated number of word tokens
			else
				if [ $current_doc_number == 1 ]; then
					echo "document	wordcount	fl-word tokens (cons.)	fl-density (cons.)	fl-types (unconsolidated)	fl-tokens (unconsolidated)	TTR (unconsolidated)	fl-types (cons.)	fl-tokens (cons.)	TTR (cons.)" >> $SCRATCHDIR/result.csv
				fi
				# calculate TTRs
				if [ $fl_types_unconsolidated -gt 0 ]; then
					TTR_uncons=$(echo "scale=3; $fl_types_unconsolidated/$fl_tokens_unconsolidated" | bc)
				else
					TTR_uncons=0
				fi
				if [ $fl_types_consolidated -gt 0 ]; then
					TTR_cons=$(echo "scale=3; $fl_types_consolidated/$fl_tokens_consolidated" | bc)
				else
					TTR_cons=0
				fi
				echo "$doc	$tokencount	$fl_word_tokens_consolidated	$fl_density	$fl_types_unconsolidated	$fl_tokens_unconsolidated	$TTR_uncons	$fl_types_consolidated	$fl_tokens_consolidated	$TTR_cons" >> $SCRATCHDIR/result.csv
			fi
		fi
	# if single text input
	else
		if [ "$aux" ] && [ -z "$detail" ]; then
			echo -e $fl_density
		else
			# if based on unconsolidated number of word tokens:
			if [ "$unconsolidated" ] && [ -z "$number" ]; then
				if [ "$aux" ]; then
					printf "%-39s %25s\n" \
					document $(basename $doc) "wordcount" $tokencount "fl-word tokens (unconsolidated)" $fl_word_tokens_unconsolidated "fl-density (based on unconsol. fl-word tokens)" $fl_density "fl-types" "$fl_types_unconsolidated" "fl-tokens" $fl_tokens_unconsolidated >> $log_name
					echo -e "$fl_density,$log_name"
				else
					echo "================================================================="
					printf "%-39s %25s\n" \
					document $(basename $doc) "wordcount" $tokencount "fl-word tokens (unconsolidated)" $fl_word_tokens_unconsolidated "fl-density (based on unconsol. fl-word tokens)" $fl_density "fl-types" "$fl_types_unconsolidated" "fl-tokens" $fl_tokens_unconsolidated
				fi
			# if based on number of tokens of FL
			elif [ "$number" ]; then
				if [ "$unconsolidated" ]; then
					option="(based on unconsol. fl-tokens)"
					fl_tokens=$fl_tokens_unconsolidated
				else
					option="(based on consol. fl-tokens)"
					fl_tokens=$fl_tokens_consolidated
				fi		
				if [ "$aux" ]; then
					printf "%-39s %25s\n" \
					document $(basename $doc) "wordcount" $tokencount "fl-tokens (unconsolidated)" $fl_tokens "fl-density $option"  $fl_density "fl-types (unconsolidated)" $fl_types_unconsolidated >> $log_name
					echo -e "$fl_density,$log_name"
				else
					echo "================================================================="
					printf "%-39s %25s\n" \
						document $(basename $doc) "wordcount" $tokencount "fl-tokens" $fl_tokens "fl-density $option"  $fl_density "fl-types (unconsolidated)" $fl_types_unconsolidated
				fi
			# if based on consolidated number of word tokens:
			else
				# calculate TTRs
				if [ $fl_types_unconsolidated -gt 0 ]; then
					TTR_uncons=$(echo "scale=3; $fl_types_unconsolidated/$fl_tokens_unconsolidated" | bc)
				else
					TTR_uncons=0
				fi
				if [ $fl_types_consolidated -gt 0 ]; then
					TTR_cons=$(echo "scale=3; $fl_types_consolidated/$fl_tokens_consolidated" | bc)
				else
					TTR_cons=0
				fi
				# set fl_tokens_consolidated to 0 if needed
				if [ -z "$fl_tokens_consolidated" ]; then
					fl_tokens_consolidated=0
				fi
				if [ "$aux" ]; then
					printf "%-49s %25s\n" \
					document $(basename $doc) "wordcount" $tokencount "fl-word tokens (unconsolidated)" $fl_word_tokens_unconsolidated "fl-density (based on unconsolid. fl-word tokens)" $(echo "scale=6; $fl_word_tokens_unconsolidated / $tokencount" | bc) "fl-word tokens (consolidated)" $fl_word_tokens_consolidated "fl-density (based on consolidated fl-word tokens)" $fl_density "fl-types (unconsolidated)" $fl_types_unconsolidated "fl-tokens (unconsolidated)" $fl_tokens_unconsolidated "TTR (unconsolidated)" $TTR_uncons "fl-types (consolidated)" $fl_types_consolidated "fl-tokens (consolidated)" $fl_tokens_consolidated "TTR (consolidated)" $TTR_cons >> $log_name
					echo -e "$fl_density,$log_name"
				else
					echo "==========================================================================="
					printf "%-49s %25s\n" \
					document $(basename $doc) "wordcount" $tokencount "fl-word tokens (unconsolidated)" $fl_word_tokens_unconsolidated "fl-density (based on unconsolidated fl-word tokens)" $(echo "scale=6; $fl_word_tokens_unconsolidated / $tokencount" | bc) "fl-word tokens (consolidated)" $fl_word_tokens_consolidated "fl-density (based on consolidated fl-word tokens)" $fl_density "fl-types (unconsolidated)" $fl_types_unconsolidated "fl-tokens (unconsolidated)" $fl_tokens_unconsolidated "TTR (unconsolidated)" $TTR_uncons "fl-types (consolidated)" $fl_types_consolidated "fl-tokens (consolidated)" $fl_tokens_consolidated "TTR (consolidated)" $TTR_cons
				fi
			fi
			if [ -z "$aux" ]; then
				echo "---------------------------------------------------------------------------"
				echo "fl = formulaic language"
				echo "fl-tokens = number of fl expression tokens"
				echo "fl-word tokens = number of word tokens in fl expressions"
				echo "fl-density = proportion of fl relative to text size"
				echo "consolidated fl-word tokens = without duplicate counting of words"
				echo "where expressions overlap"
				echo "unconsolidated/unconsol. = overlaps between expressions remain unconsolidated"
				echo "TTR = fl expression type-token ratio"
				echo "==========================================================================="
				echo
			fi
		fi
	fi
	############################
	# tidy up
	# move files not to be in the way
	if [ "$debug" ]; then
		mv $SCRATCHDIR/sections $SCRATCHDIR/sections$(date +%s) 2>/dev/null
		mv $SCRATCHDIR/fl.txt $SCRATCHDIR/fl.$(date +%s).txt 2>/dev/null
		mv $SCRATCHDIR/n-gram_lists $SCRATCHDIR/n-gram_lists.$(date +%s) 2>/dev/null
		mkdir $SCRATCHDIR/n-gram_lists
		mv $SCRATCHDIR/fls.txt $SCRATCHDIR/fls.$(date +%s).txt 2>/dev/null
	else
		rm -r $SCRATCHDIR/sections 2>/dev/null
		rm $SCRATCHDIR/fl.txt 2>/dev/null
		rm -r $SCRATCHDIR/n-gram_lists/* 2>/dev/null
		rm $SCRATCHDIR/fls.txt 2>/dev/null
	fi
	# reset variables
	fl=
	wc=
	tokencount=
	fl_word_tokens_consolidated=
	fl_word_tokens_unconsolidated=
	fl_tokens_unconsolidated=
	fl_tokens_consolidated=
	fl_density=
	fl_types_unconsolidated=
	fl_types_consolidated=
done
if [ "$list" ]; then
	:
elif [ "$dir" ] && [ -z "$no_density" ]; then
	column -s '	' -t $SCRATCHDIR/result.csv 2>/dev/null
	resultsoutdir=$(sed 's|/$||' <<<$outdir)
	add_to_name $resultsoutdir/results.csv
	mv $SCRATCHDIR/result.csv $output_filename
	if [ -z "$aux" ] || [ "$list" ] || [ "$no_density" ]; then
		echo "results file placed in $output_filename."
	fi
fi
# delete SCRATCHDIR
if [ -z "$debug" ]; then
	rm -r $SCRATCHDIR &
fi
