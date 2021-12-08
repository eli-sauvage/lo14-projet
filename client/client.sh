if [ $(echo "$2" | grep "^[0-9]\{4\}$" | wc -l) -ne 1 ] && [ $# -lt 3 ];then
	echo "usage : vsh CMD ADRESSE PORT [options]"
	exit
fi
ADRESSE=$2
PORT=$3
toArchivePath="/mnt/c/Users/elico/OneDrive-UTT/lo14/projet/toArchive.sh"
if [ "$1" = "-create" ];then
		if [ -z $3 ];then echo "usage vsh -create ADRESSE PORT nom-archive";exit;fi 
	pwd="$(pwd)"
	commande="create $4 "$(bash "$toArchivePath" "$pwd")
	echo "commande qui va etre envoyee au serveur : "$commande 
    var=$(echo $commande | sed "s/\\\/\\\\\\\/g" | nc -w1 $ADRESSE $PORT)
	echo $var #response from the server
elif [ "$1" = "-extract" ];then
	if [ -f /tmp/arc.arc ];then rm /tmp/arc.arc; fi
	while read line;do
		echo $line >> /tmp/arc.arc
	done <<< $(echo "extract $4" | nc -w1 localhost $PORT)
	bash unarchive.sh /tmp/arc.arc
elif [ "$1" = "-list" ];then
	rep=$(echo "list" | nc -w1 $ADRESSE $PORT)
	echo $rep
elif [ "$1" = "-browse" ];then
	(())
else
	echo "CMD must be one of \"-create, -list, -browse, -extract\""
	exit
fi
