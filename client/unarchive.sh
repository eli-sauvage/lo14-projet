if [ $# -ne 1 ] || [ ! -f $1 ] || [ "$(echo $1 | tail -c5)" != ".arc" ];then
	echo "paramter : an archive"
	exit
fi


function error(){
	echo "ERROR : $1"
	exit
}

lineCounter=0
headerBegin=-1
bodyBegin=-1
root=$(pwd)
while read line; do
# echo $line
	((lineCounter++))
	if [ $lineCounter -eq 1 ];then
		headerBegin=$(echo $line | cut -d':' -f1)
		bodyBegin=$(echo $line | cut -d':' -f2)
		if [ $headerBegin -gt $bodyBegin ];then error "wrong first line of archive"; fi
	elif [ $lineCounter -ge $headerBegin ] && [ $lineCounter -lt $bodyBegin ];then #IN HEADER
		if [ "$(echo $line | head -c10)" = "directory " ];then
			currentFolder=$(echo $line | cut -c 11-)
#			echo "dossier $currentFolder"
			if [ ! -d $currentFolder ];then mkdir -p $currentFolder;fi
			#cd $currentFolder
		elif [ "$line" != "@" ];then #file or dir inside the currentFolder
			type=$(echo $line | cut -d' ' -f2 | head -c 1)
			name=$(echo $line | cut -d' ' -f1)
			if [ "$type" = "-" ];then #file
				#echo f $name
				touch "$currentFolder/$name"
				size=$(echo $line | cut -d ' ' -f3)
				if [ "$size" != "0" ];then
					startLine=$(echo $line | cut -d ' ' -f4)
					lineNb=$(echo $line | cut -d ' ' -f5)
					if [ -z $startLine ] || [ -z $lineNb ];then error "wrong line format on file $currentFolder/$currentFile";fi
					# echo $(cat $1 | head -n $((bodyBegin-2+startLine+lineNb)) | tail -$(($lineNb)))
					while read fileLine; do
#						echo "line : $fileLine"
						echo $fileLine >> "$currentFolder/$name"
					done <<< $(cat $1 | head -n $((bodyBegin-2+startLine+lineNb)) | tail -$(($lineNb)))
				fi
			elif [ "$type" = "d" ];then #dir
#				echo d $name
				(())
			fi
			#touch $currentFolder $(echo $line | cut -d' ' -f1)
		fi
	elif [ $lineCounter -ge $bodyBegin ];then #IN BODY
#		echo "body "$line
		(())
	fi
	#echo $lineCounter $line
done < $1
#echo $headerBegin $bodyBegin
