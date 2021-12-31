path=$(realpath $(dirname $0))"/client/client.sh"
if [ -f "$path" ]; then
    echo "alias vsh='bash $path'" >>~/.bashrc
    echo "l'alias a bien ete cree, merci de redemarrer votre terminal"
else
    echo "merci de lancer ce fichier depuis la racine du projet"
fi
