#!/bin/bash -
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin" # needed for Cygwin
##############################################################################
# installer
copyright="Copyright (c) 2015-6 Cardiff University"
# written by Andreas Buerki
version="0.5.1"
####
## set installation variables
export title="fl"
export components="fl.sh fl-density.sh tidy.sh"
export DESTINATION="${HOME}/bin"
export DESTINATION2="/" # for cygwin-only files
export cygwin_only=""
export linux_only=""
export osx_only=""
export licence="European Union Public Licence (EUPL) v. 1.1."
export URL="https://joinup.ec.europa.eu/community/eupl/og_page/european-union-public-licence-eupl-v11"
# define functions
help ( ) {
	echo "
Usage: $(basename $(sed 's/ //g' <<<$0))  [OPTIONS]
Example: $(basename $(sed 's/ //g' <<<$0))  -u
IMPORTANT: this script should not be moved outside of its original directory.
           (it will stop working if it is moved)
Options:   -u	uninstalls the software
           -V   displays version information
           -p   only attempts to set path
"
}
# analyse options
while getopts dhpuV opt
do
	case $opt	in
	d)	diagnostic=true
		;;
	h)	help
		exit 0
		;;
	u)	uninstall=true
		;;
	p)	pathonly=true
		;;
	V)	echo "$(basename $(sed 's/ //g' <<<$0))	-	version $version"
		echo "$copyright"
		echo "licensed under the EUPL V.1.1"
		echo "written by Andreas Buerki"
		exit 0
		;;
	esac
done
echo ""
echo "Installer"
echo "---------"
echo ""
if [ "$diagnostic" ]; then
	echo "pwd is $(pwd)"
	echo "current path is $PATH"
	echo "home: $HOME"
fi
# check what platform we're under
platform=$(uname -s)
# and make adjustments accordingly
if [ "$(grep 'CYGWIN' <<< $platform)" ]; then
	echo "WARNING: this software was not tested on CYGWIN and is not likely to work on that platform."
elif [ "$(grep 'Darwin' <<< $platform)" ];then
	DARWIN=true
else
	LINUX=true
fi
# ascertain source directory
export sourcedir="$(dirname "$0")"
if [ "$(grep '^\.' <<<"$sourcedir")" ]; then
	sourcedir="$(pwd)/bin"
fi
if [ "$diagnostic" ]; then 
	echo "sourcedir is $sourcedir"
	echo "0 is $0"
	echo "dirname is $(dirname "$0")"
fi
# check it's in its proper directory
if [ "$(grep "$title" <<<"$sourcedir")" ]; then
	:
else
	echo "This installer script appears to have been moved out of its original directory. Please move it back into the $title directory and run it again." >&2
	sleep 2
	exit 1
fi
###########
# getting agreement on licence
###########
#echo "This software is licensed under the open-source"
#echo "$licence"
#echo "The full licence is found at"
#echo "$URL"
#echo "or in the accompanying licence file."
#echo "Before installing and using the software, we ask"
#echo "that you agree to the terms of this licence."
#echo "If you agree, please type 'agree' and press ENTER,"
#echo "otherwise just press ENTER."
#read -p '> ' d < /dev/tty
#if [ "$d" != "agree" ]; then
#	echo
#	echo "Since the installation and use of this software requires"
#	echo "agreement to the licence, installation cannot continue."
#	sleep 2
#	exit 1
#else
#	echo "Thank you."
#fi
##### Cardiff Uni internal use statement
echo "This installer is for use within the Centre for Language Communication Research of Cardiff University only."; sleep 0.5
###########
# setting path
###########
if [ "$uninstall" ]; then
	echo "path needs to be uninstalled manually."
	exit 0
else
	# set path
	# from now on, commands are executed from a subshell with -l (login) 
	# option (needed for Cygwin)
	bash -lc 'if [ "$(egrep -o "$HOME/bin" <<<$PATH)" ]; then
		echo "Path already set."
	elif [ -e ~/.bash_profile ]; then
		cp "${HOME}/.bash_profile" "${HOME}/.bash_profile.bkup"
		echo "">> "${HOME}/.bash_profile"
		echo "export PATH="\${PATH}:\"${HOME}/bin\""">> "${HOME}/.bash_profile"
		echo "Setting path in ~/.bash_profile"
		echo "Logout and login may be required before new path takes effect."
	else
		cp "${HOME}/.profile" "${HOME}/.profile.bkup"
		echo "">> "${HOME}/.profile"
		echo "export PATH="$\{PATH}:${HOME}/bin"">> "${HOME}/.profile"
		echo "Setting path in ~/.profile"
		echo "Logout and login may be required before new path takes effect."
	fi'
	if [ "$pathonly" ]; then
		exit 0
	fi
fi
###########
# removing old installations
###########
bash -lc 'echo "Checking for existing installations..."
for file in $components; do
	existing="$(which $file 2>/dev/null)"
	if [ "$existing" ]; then
		echo "removing $existing"
		rm -f "$existing" 2>/dev/null || sudo rm "$existing"
		if [ "$CYGWIN" ]; then
			echo "removing $DESTINATION2$cygwin_only"
		elif [ "$LINUX" ]; then
			echo "removing $HOME/.icons/$linux_only"
		fi
	fi
	# remove programme file in $HOME/bin
	rm -f "$HOME/bin/$file" 2>/dev/null
	existing=""
done'
if [ "$CYGWIN" ] && [ "$cygwin_only" ]; then
	rm "$DESTINATION2$cygwin_only" 2>/dev/null
	rm /cygdrive/c/Users/"$USERNAME"/Desktop/Substring.lnk 2>/dev/null
elif [ "$DARWIN" ] && [ "$osx_only" ]; then
	rm -r /Applications/$osx_only 2>/dev/null
	rm -r $HOME/Desktop/$osx_only 2>/dev/null
elif [ "$linux_only" ]; then
	rm "$HOME/.icons/$linux_only" 2>/dev/null
	rm $HOME/Desktop/Substring.desktop 2>/dev/null
fi
if [ "debug" ]; then
	echo "finished removing old installations."
fi
if [ "$uninstall" ]; then
	exit 0
fi
##########
# install files
#########
echo ""
echo "Installing files to $HOME/bin"
mkdir -p "$DESTINATION"
for file in $components; do
	cp "$sourcedir/$file" "$DESTINATION/" || problem=true
	if [ "$problem" ]; then
		echo "Installation encountered problems. Manual installation may be required." >&2
		exit 1
	fi
done
if [ "$CYGWIN" ]; then
	cp "$sourcedir/$cygwin_only" "$DESTINATION2" 2> /dev/null
elif [ "$DARWIN" ]; then
	:
else
	mkdir $HOME/.icons 2>/dev/null
	cp "$sourcedir/$linux_only" $HOME/.icons 2> /dev/null
fi

echo "The following files were placed in $HOME/bin:"
echo "$components $(if [ "$CYGWIN" ]; then echo "$cygwin_only"; elif [ "$DARWIN" ]; then :;else echo "$linux_only placed in $HOME/.icons";fi)" | tr ' ' '\n'
echo ""
sleep 10
echo "Installation complete."
echo "This window can now be closed."