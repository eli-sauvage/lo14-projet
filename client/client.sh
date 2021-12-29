if [ $(echo "$2" | grep "^[0-9]\{4\}$" | wc -l) -ne 1 ] && [ $# -lt 3 ]; then
	echo "usage : vsh CMD ADRESSE PORT [options]"
	exit
fi
ADRESSE=$2
PORT=$3
toArchivePath=$(realpath $(dirname $0))"/toArchive.sh"
if [ "$1" = "-create" ]; then
	if [ -z $3 ]; then
		echo "usage vsh -create ADRESSE PORT nom-archive"
		exit
	fi
	currentFolder="$(basename $(pwd))"
	echo $currentFolder
	cd ..
	commande="create $4 "$(bash $toArchivePath $currentFolder)
	echo "commande qui va etre envoyee au serveur : "$commande
	var=$(echo $commande | sed "s/\\\/\\\\\\\/g" | nc -w1 $ADRESSE $PORT)
	echo $var #response from the server
	cd $currentFolder
elif [ "$1" = "-extract" ]; then
	if [ -f /tmp/arc.arc ]; then rm /tmp/arc.arc; fi
	while read line; do
		echo $line >>/tmp/arc.arc
	done <<<$(echo "extract $4" | nc -w1 localhost $PORT)
	bash unarchive.sh /tmp/arc.arc
elif [ "$1" = "-list" ]; then
	rep=$(echo "list" | nc -w1 $ADRESSE $PORT)
	echo "$rep"
elif [ "$1" = "-browse" ]; then
	path="/"
	if [ -z $4 ]; then
		echo "[options] doit etre le nom de l'archive"
		exit
	fi
	rep=$(echo "browse testForFolder / $4" | nc -w1 $ADRESSE $PORT)
	if [ ! "$rep" = "ok" ]; then #erreur (autre que ok)
		echo "$rep"
		exit
	fi
	printf "$path> "
	while read input; do
		#parse arg (relative to absolute)
		folder=$(echo $input | awk '{print $2}')
		if [ "$folder" = "." ]; then
			folder="$path"
		elif [ "$folder" = ".." ]; then
			if [ "$path" = "/" ]; then
				echo "pas de dossier parent"
				printf "$path> "
				continue
			else
				path=$path/$folder
				if echo $path | grep -wq "^\/[^\/]*\/\.\.$"; then
					folder="/"
				else
					folder=$(echo $path | sed 's/^\(.*\/.*\)\/\(.*\)\/\.\.$/\1/g')
				fi
			fi
		elif [ ! "${folder:0:1}" = "/" ]; then
			if [ "$path" = "/" ]; then
				folder=$path$folder
			else
				folder=$path/$folder
			fi
		fi
		commande=$(echo $input | awk '{print $1}')
		if [ "$commande" = "ls" ]; then
			echo "browse ls $folder archive2"
			rep=$(echo "browse ls $folder archive2" | nc -w1 $ADRESSE $PORT)
			echo "$rep"
		elif [ "$commande" = "cd" ]; then
			rep=$(echo "browse testForFolder $folder $4" | nc -w1 $ADRESSE $PORT)
			if [ ! "$rep" = "ok" ]; then #erreur (autre que ok)
				echo "err:$rep"
			else
				path="$folder"
			fi
		elif [ "$commande" = "pwd" ];then
			echo $path
		elif [ "$commande" = "cat" ];then
			rep=$(echo "browse cat $folder archive2" | nc -w1 $ADRESSE $PORT)
			echo "$rep"
		elif [ "$commande" = "help" ]; then
			echo "commandes : ls, cd, exit"
		elif [ "$commande" = "rm" ];then
			rep=$(echo "browse rm $folder archive2" | nc -w1 $ADRESSE $PORT)
			echo "$rep"
		elif [ "$commande" == "touch" ];then
			rep=$(echo "browse touch $folder archive2" | nc -w1 $ADRESSE $PORT)
			echo "$rep"
		elif [ "$commande" == "mkdir" ];then
			rep=$(echo "browse mkdir $folder archive2" | nc -w1 $ADRESSE $PORT)
			echo "$rep"
		elif [ "$commande" = "exit" ]; then
			break
		else
			echo "commande non reconnue, essayez 'help' pour une liste des commandes ou exit pour sortir"
		fi
		printf "$path> "
	done
else
	echo "CMD must be one of \"-create, -list, -browse, -extract\""
	exit
fi
