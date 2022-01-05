if [ $# -ne 1 ] || [ ! -d "$1" ];then #not 1 arg or not folder
	echo "parameter : one folder"
	exit
fi

folder="$1"

folderNext=true
currentFolder=""

h="" #header value
b="" #body
bodyLine=1
while read line;do
	if [ -z $line ];then
		folderNext=true
		h=$h"@\n"
		continue
	fi
	if [ $folderNext = true ];then #we are in a folder
		currentFolder=${line::-1} #remove last char (':')
		folderNext=false
		h=$h"directory $currentFolder\n"
	else
		element="$currentFolder/$line"
		h=$h"$line "
		h=$h"$(ls -ld $element | cut -d' ' -f1) "
		h=$h"$(du -bhs $element | cut -f1) "
		if [ ! -d $element ];then
			size=$(wc -l $element | cut -d' ' -f1)
			if [ "$size" != "0" ];then
			# echo $currentFolder $size $element >> out
				h=$h"$bodyLine "
				h=$h$size
				bodyLine=$((bodyLine+size))
				while read elemLine;do
					b=$b"$elemLine\n"
				done < $element
			fi
		fi
		h=$h"\n"
	fi
done <<< $(ls -R "$folder")
h=$h"@\n"

lineNb=$(echo $h | grep -Fo "\n" | wc -l)
lineNb=$((lineNb+3))

echo "3:$lineNb\n\n${h}${b}\n"
