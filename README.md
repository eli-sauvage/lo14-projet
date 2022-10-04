# LO14 - Archive manager
Ceci est un projet d'école (LO14 - Administration des systèmes unix)
C'est un petit utilitaire en bash, pour créer et décompresser des archives 
- l'utilitaire ne permet pas de réduire la place que prennent les fichiers : il ne fait que regrouper les noms, permissions et contenus des ficiers de l'arborescence à archiver

L'utilitaire permet également de se déplacer dans les archives alors qu'elles ne sont pas encore décompressées
Il permet d'executer les commandes de base linux : cd, ls, cat, touch ...

## Pour démarrer le serveur
`cd lo14-projet/server && bash server.sh <PORT>` sur la machine serveur
## En tant que client
### Installation
`cd lo14-projet && bash setup.sh` puis suivre les instructions
### Utilisation
`vsh <CMD> <ADRESSE> <PORT> [opt]` sur la machine client

# A faire / problèmes connus
 - ajouter la possibilité de  "cd ../.."
 - chmod pour -extract
 - commande `vsh help` pour les fonctionnalités de base
