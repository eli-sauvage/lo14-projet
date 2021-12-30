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
		echo "err:$rep"
		exit
	fi
	printf "$path> "
	while read input; do
		#parse arg (relative to absolute)
		folders=$(echo $input | awk '{for (i=2; i<=NF; i++) print $i}')
		if [ -z "$(echo $folders | sed 's/-[^ ]*//g' | sed 's/ //g')" ]; then folders=$folders" ."; fi #sed to repose opts
		out=""
		args=""
		stopArgs=0
		for folder in $folders; do
			if [ "$folder" = "--" ]; then
				stopArgs=1
				continue
			elif [ "${folder:0:1}" = "-" ] && [ $stopArgs -ne 1 ]; then
				args="$args ${folder:1}"
				continue
			elif [ "$folder" = "." ]; then
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
			if [ ! -z "$out" ]; then out="$out "; fi
			out="$out$folder"
		done
		folder=$out
		# break
		commande=$(echo $input | awk '{print $1}')
		if [ "$commande" = "ls" ]; then
			optionA="0"
			optionL="0"
			for arg in $args; do
				if [ "$arg" = "a" ]; then
					optionA="1"
				elif [ "$arg" = "l" ]; then
					optionL="1"
				elif [ "$arg" = "la" ] || [ "$arg" = "al" ]; then
					optionL="1"
					optionA="1"
				else
					echo argument $arg inconnu
					printf "$path> "
					continue 2
				fi
			done
			rep=$(echo "browse ls $folder $4" | nc -w1 $ADRESSE $PORT)
			if [ ! "$optionA" = "1" ]; then
				rep=$(echo "$rep" | awk '{if(substr($1, 0, 1)!=".")print $0}')
			fi
			if [ ! "$optionL" = "1" ]; then
				rep=$(echo "$rep" | awk '{if(substr($2, 0, 1)=="d")print $1"\\"; else if(index($2, "x") != 0)print $1"*";else print$1}')
			fi
			echo "$rep"
		elif [ "$commande" = "cd" ]; then
			if [ -z "$args" ]; then
				folder="$(echo $folder | awk '{print $1}')" #only one arg
				# echo $"browse testForFolder $folder $4"
				rep=$(echo "browse testForFolder $folder $4" | nc -w1 $ADRESSE $PORT)
				if [ ! "$rep" = "ok" ]; then #erreur (autre que ok)
					echo "err:$rep"
				else
					path="$folder"
				fi
			else
				echo "argument(s) $args inconnu(s)"
			fi
		elif [ "$commande" = "pwd" ]; then
			if [ -z "$args" ]; then
				echo $path
			else
				echo "argument(s) $args inconnu(s)"
			fi
		elif [ "$commande" = "cat" ]; then
			if [ -z "$args" ]; then
				# echo "browse cat $folder $4"
				rep=$(echo "browse cat $folder $4" | nc -w1 $ADRESSE $PORT)
				echo "$rep"
			else
				echo "argument(s) $args inconnu(s)"
			fi
		elif [ "$commande" = "rm" ]; then
			if [ -z "$args" ]; then
				rep=$(echo "browse rm $folder $4" | nc -w1 $ADRESSE $PORT)
				echo "$rep"
			else
				echo "argument(s) $args inconnu(s)"
			fi
		elif [ "$commande" == "touch" ]; then
			if [ -z "$args" ]; then
				rep=$(echo "browse touch $folder $4" | nc -w1 $ADRESSE $PORT)
				echo "$rep"
			else
				echo "argument(s) $args inconnu(s)"
			fi
		elif [ "$commande" == "mkdir" ]; then
			if [ -z "$args" ]; then
				rep=$(echo "browse mkdir $folder $4" | nc -w1 $ADRESSE $PORT)
				echo "$rep"
			else
				optionP="0"
				for arg in $args; do
					if [ "$arg" == "p" ]; then
						optionP="1"
					else
						echo argument $arg inconnu
						printf "$path> "
						continue 2
					fi
				done
				if [ "$optionP" = "1" ]; then
					foldersToCreate=$(echo $folder | awk -F "/" 'BEGIN{p=""};{for(i=2; i<=NF; i++){p=p"/"$i;print p}}')
					for folder in $foldersToCreate; do
						rep=$(echo "browse mkdir $folder $4" | nc -w1 $ADRESSE $PORT)
						echo "$rep"
					done
				fi
			fi
		elif [ "$commande" = "help" ]; then
			if [ -z "$args" ]; then
				echo "commandes : ls, cd, exit"
			else
				echo "argument(s) $args inconnu(s)"
			fi
		elif [ "$commande" = "exit" ]; then
			if [ -z "$args" ]; then
				break
			else
				echo "argument(s) $args inconnu(s)"
			fi
		elif [ ! -z "$commande" ]; then
			echo "commande non reconnue, essayez 'help' pour une liste des commandes ou exit pour sortir"
		fi
		printf "$path> "
	done
else
	echo "CMD must be one of \"-create, -list, -browse, -extract\""
	exit
fi
