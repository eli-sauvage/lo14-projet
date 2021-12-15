#!/bin/bash
if [ $# -ne 1 ]; then
    echo "usage: $(basename $0) PORT"
    exit -1
fi
PORT="$1"
FIFO="/tmp/$USER-fifo-$$"

function nettoyage() { rm -f "$FIFO"; }
trap nettoyage EXIT

[ -e "FIFO" ] || mkfifo "$FIFO"

function accept-loop() {
    while true; do
	interaction < "$FIFO" | netcat -l -p "$PORT" > "$FIFO"
    done
}

function interaction() {
    local cmd args
    while true; do
	read cmd args || exit -1
	fun="commande-$cmd"
	if [ "$(type -t $fun)" = "function" ]; then
	    $fun "$args"
	else
	    commande-non-comprise $fun $args
	fi
    done
}

function commande-non-comprise () {
   echo "Le serveur ne peut pas interpreter cette commande"
}

function commande-test() {
   echo test
}

function commande-create() {
	name=$(echo $1 | cut -d' ' -f1)
	content=$(echo $1 | cut -d' ' -f2-)
	printf "$content" > "./$name.arc"
	echo "archive created"
}

function commande-extract(){
	name=$1
	if [ ! -f "$1.arc" ];then
		echo "archive $1 doesn't exist"
		return
	fi
	while read line;do
		echo "$line"
	done < "$1.arc"
}
function commande-list(){
	echo $(ls | grep '.*\.arc' | sed 's/\(.\)\.arc/\1/g')
}

function commande-browse() { #browse mode[ls, cd, cat, rm, touch, mkdir] currentPath archiveName
	mode="$(echo $1 | cut -d' ' -f1)"
	path="$(echo $1 | cut -d' ' -f2)"
	archive="$(echo $1 | cut -d' ' -f3)"
	#verify if archive exists
	echo "archive : $archive; mode : $mode; path : $path"
	if [ ! -f "./$archive.arc" ];then echo "l'archive $archive n'existe pas"; return; fi
	#verify current path
	if ! cat "./$archive.arc" | grep -q "^directory $path$"; then echo "path $path doesnt exist in $archive"; return; fi
	if [ $mode = "ls" ]; then
		filesInCurrentPath=$(sed -n "/^directory $(echo $path | sed 's/\//\\\//g')/,/^@/{p;/^@/q}" $archive.arc | head --lines=-1 | tail --lines=+2)
		echo $filesInCurrentPath
	elif [ $mode = "cd" ]; then
		((0))
	fi
}

accept-loop