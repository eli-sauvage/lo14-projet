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
		interaction <"$FIFO" | netcat -l -p "$PORT" >"$FIFO"
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

function commande-non-comprise() {
	echo "Le serveur ne peut pas interpreter cette commande"
}

function commande-test() {
	echo test
}

function commande-create() {
	name=$(echo $1 | cut -d' ' -f1)
	content=$(echo $1 | cut -d' ' -f2-)
	printf "$content" >"./$name.arc"
	echo "archive created"
}

function commande-extract() {
	name=$1
	if [ ! -f "$1.arc" ]; then
		echo "archive $1 doesn't exist"
		return
	fi
	while read line; do
		echo "$line"
	done <"$1.arc"
}
function commande-list() {
	echo $(ls | grep '.*\.arc' | sed 's/\(.\)\.arc/\1/g')
}

function testForFile() {
	path=$1
	archive=$2
	p=$(echo $path | sed 's/\(.*\)\/\(.*\)$/\1/')
	f=$(echo $path | sed 's/\(.*\)\/\(.*\)$/\2/')
	echo file $f path $p arch $archive >out
	fileExists=$(awk -f testForFileInArchive.awk -v path=$p -v file=$f ./$archive.arc)
	echo $fileExists >>out
	if [ "$fileExists" = "0" ]; then
		return 0
	else
		return 1
	fi
}
function testForFolder() {
	if ! cat "./$archive.arc" | grep -q "^directory ${path}$"; then
		return 1
	else
		return 0
	fi
}
function commande-browse() { #browse mode[ls, cd, cat, rm, touch, mkdir] currentPath archiveName
	mode="$(echo $1 | cut -d' ' -f1)"
	path="folderForTesting$(echo $1 | cut -d' ' -f2)"
	if [ "${path: -1}" = "/" ]; then path="${path::-1}"; fi
	archive="$(echo $1 | cut -d' ' -f3)"
	#verify if archive exists
	if [ ! -f "./$archive.arc" ]; then
		echo "l'archive $archive n'existe pas"
		return
	fi
	if [ $mode = "testForFolder" ]; then
		if testForFolder $path $archive; then
			echo "ok"
		else
			echo "le dossier n'existe pas dans $archive"
		fi
	elif [ $mode = "ls" ]; then
		if ! testForFolder $path $archive; then
			echo "le dossier $path n'existe pas dans $archive"
			return
		fi
		while read l; do
			echo $l
		done <<<$(sed -n "/^directory $(echo $path | sed 's/\//\\\//g')/,/^@/{p;/^@/q}" $archive.arc | head --lines=-1 | tail --lines=+2) #https://unix.stackexchange.com/questions/264962/print-lines-of-a-file-between-two-matching-patterns
		echo $filesInCurrentPath
	elif [ $mode = "cat" ]; then
		if ! testForFile $path $archive; then
			echo "le fichier $path n'existe pas dans $archive"
			return
		fi
		p=$(echo $path | sed 's/\(.*\)\/\(.*\)$/\1/')
		f=$(echo $path | sed 's/\(.*\)\/\(.*\)$/\2/')
		while read l; do
			echo $l
		done <<<$(awk -f cat.awk -v path=$p -v file=$f ./$archive.arc)
	elif [ $mode = "rm" ]; then
		p=$(echo $path | sed 's/\(.*\)\/\(.*\)$/\1/')
		f=$(echo $path | sed 's/\(.*\)\/\(.*\)$/\2/')
		if testForFile $path $archive; then
			echo "$(awk -f rmFile.awk -v p=$p -v f=$f $archive.arc)" > $archive.arc
			echo "fichier supprime"
		elif testForFolder $path $archive; then
			echo "$(awk -f rmFolder.awk -v p=$p -v f=$f $archive.arc)" > $archive.arc
			echo "dossier supprime"
		else
			echo "pas de dossier ou fichier $path dans l'archive $archive"
		fi
	fi
}

accept-loop
