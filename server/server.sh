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
	fPath=$1
	fArchive=$2
	fp=$(echo $fPath | sed 's/\(.*\)\/\(.*\)$/\1/')
	ff=$(echo $fPath | sed 's/\(.*\)\/\(.*\)$/\2/')
	fileExists=$(awk -f testForFileInArchive.awk -v path=$fp -v file=$ff ./$fArchive.arc)
	if [ "$fileExists" = "0" ]; then
		return 0
	else
		return 1
	fi
}
function testForFolder() {
	fPath=$1
	fArchive=$2
	if ! cat "./$fArchive.arc" | grep -q "^directory ${fPath}$"; then
		return 1
	else
		return 0
	fi
}
function commande-browse() { #browse mode[ls, cd, cat, rm, touch, mkdir] currentPath archiveName
	mode="$(echo $1 | cut -d' ' -f1)"
	paths="$(echo $1 | awk '{for(i=2; i<NF; i++)print "folderForTesting"$i}')"
	# return
	archive="$(echo $1 | awk '{print $NF}')"
	echo $archive >out
	#verify if archive exists
	if [ ! -f "./$archive.arc" ]; then
		echo "l'archive $archive n'existe pas"
		return
	fi
	for path in $paths; do #in case of several inputs
		if [ "${path: -1}" = "/" ]; then path="${path::-1}"; fi
		if [ $mode = "testForFolder" ]; then
			if testForFolder $path $archive; then
				echo "ok"
			else
				echo "le dossier n'existe pas dans $archive"
			fi
		elif [ $mode = "ls" ]; then
			if ! testForFolder "$path" $archive; then
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
				echo "$(awk -f rmFile.awk -v p=$p -v f=$f $archive.arc)" >$archive.arc
				echo "fichier supprime"
			elif testForFolder $path $archive; then
				echo "$(awk -f rmFolder.awk -v p=$p -v f=$f $archive.arc)" >$archive.arc
				echo "dossier supprime"
			else
				echo "pas de dossier ou fichier $path dans l'archive $archive"
			fi
		elif [ $mode = "touch" ]; then
			p=$(echo $path | sed 's/\(.*\)\/\(.*\)$/\1/')
			f=$(echo $path | sed 's/\(.*\)\/\(.*\)$/\2/')
			if ! testForFolder $p $archive; then
				echo "le dossier $p n'existe pas dans $archive"
				return
			fi
			if testForFile "$path" $archive; then
				echo "le fichier $path existe deja, merci de le supprimer d'abord"
				return
			fi
			cat $archive.arc >/tmp/$archive.arc
			rm $archive.arc
			while read l; do
				echo $l >>$archive.arc
			done <<<$(awk -f touch.awk -F " |:" -v p=$p -v f=$f /tmp/$archive.arc)
			rm /tmp/$archive.arc
			echo "fichier cree"
		elif [ $mode = "mkdir" ]; then
			p=$(echo $path | sed 's/\(.*\)\/\(.*\)$/\1/')
			f=$(echo $path | sed 's/\(.*\)\/\(.*\)$/\2/')
			if ! testForFolder $p $archive; then
				echo "le dossier $p n'existe pas dans $archive"
				return
			fi
			if testForFolder "$path" $archive; then
				echo "le dossier $path existe deja, merci de le supprimer d'abord"
				return
			fi
			cat $archive.arc >/tmp/$archive.arc
			rm $archive.arc
			while read l; do
				echo $l >>$archive.arc
			done <<<$(awk -f mkdir.awk -F " |:" -v p=$p -v f=$f /tmp/$archive.arc)
			rm /tmp/$archive.arc
			echo "dossier cree"
		fi
	done
}

accept-loop
