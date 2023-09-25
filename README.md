# rafa-docker

(travail en cours, non déployé en dev,test,prod)

Configuration docker 🐳 pour déployer l'application Rafa (référentiel des annuaires fonctionnels de l'Abes).

Le code source (non opensource car vieux code) de rafa est accessible ici :
https://git.abes.fr/depots/Rafa/


## URLs de rafa

Les URLs correspondantes aux déploiements en local, test et prod de rafa sont les suivantes :

- local : http://127.0.0.1:15180/
- test : https://rafa-test.abes.fr
- prod : https://rafa.abes.fr

## Prérequis

Disposer de :
- ``docker``
- ``docker-compose``

## Installation

Déployer la configuration docker dans un répertoire :
```bash
# adaptez /opt/pod/ avec l'emplacement où vous souhaitez déployer l'application
cd /opt/pod/
git clone https://github.com/abes-esr/rafa-docker.git

cd /opt/pod/rafa-docker/
mkdir -p images/
git clone -b docker https://git.abes.fr/depots/Rafa.git rafa-docker/images/Rafa/
```

Configurer l'application depuis l'exemple du [fichier ``.env-dist``](./.env-dist) (ce fichier contient la liste des variables avec des explications et des exemples de valeurs) :
```bash
cd /opt/pod/rafa-docker/
cp .env-dist .env
# personnaliser alors le contenu du .env
```

Initialisation de la base de données en partant du dump d'une sauvegarde, par exemple `rafa-db-2023-09-07.dmp` qu'il faut préalablement déposer dans le répertoire `/opt/pod/rafa-docker/volumes/rafa-db/backup/` :
```bash
cd /opt/pod/rafa-docker/
chmod 777 ./volumes/rafa-db/oradata/ ./volumes/rafa-db/backup/
docker-compose up -d rafa-db rafa-db-dumper # a noter que le premier démarrage peut prendre jusque à 10 minutes
docker exec -it rafa-db-dumper bash
impdp system/$ORACLE_DB_DUMPER_ORACLE_PWD@//$ORACLE_DB_DUMPER_HOST:$ORACLE_DB_DUMPER_PORT/FREE schemas=$ORACLE_DB_DUMPER_ORACLE_SCHEMA_TO_BACKUP TABLE_EXISTS_ACTION=REPLACE directory=BACKUP_DIR dumpfile=rafa-db-2023-09-07.dmp logfile=rafa-db-2023-09-07.log
```

Au final on peut démarrer le reste de l'application comme ceci :
```bash
cd /opt/pod/rafa-docker/
docker-compose up --build -d
```

## Démarrage et arrêt

```bash
# pour démarrer l'application (ou pour appliquer des modifications 
# faites dans /opt/pod/rafa-docker/.env)
cd /opt/pod/rafa-docker/
docker-compose up -d
```

Remarque : retirer le ``-d`` pour voir passer les logs dans le terminal et utiliser alors CTRL+C pour stopper l'application

```bash
# pour stopper l'application
cd /opt/pod/rafa-docker/
docker-compose stop


# pour redémarrer l'application
cd /opt/pod/rafa-docker/
docker-compose restart
```

## Supervision

```bash
# pour visualiser les logs de l'appli
cd /opt/pod/rafa-docker/
docker-compose logs -f --tail=100
```

Cela va afficher les 100 dernière lignes de logs générées par l'application et toutes les suivantes jusqu'au CTRL+C qui stoppera l'affichage temps réel des logs.


## Configuration

Pour configurer l'application, vous devez créer et personnaliser un fichier ``/opt/pod/rafa-docker/.env`` (cf section [Installation](#installation)). Les paramètres à placer dans ce fichier ``.env`` et des exemples de valeurs sont indiqués dans le fichier [``.env-dist``](https://github.com/abes-esr/rafa-docker/blob/develop/.env-dist)

## Sauvegardes

Les éléments suivants sont à sauvegarder:
- ``/opt/pod/rafa-docker/.env`` : contient la configuration spécifique de notre déploiement
- la base de données oracle de Rafa dont les dumps sont periodiquement et automatiquement générés dans le répertoire ``/opt/pod/rafa-docker/volumes/rafa-db/backup/``

### Restauration depuis une sauvegarde

Réinstallez l'application rafa depuis la [procédure d'installation ci-dessus](#installation) et récupéré depuis les sauvegardes le fichier ``.env`` et placez le dans ``/opt/pod/rafa-docker/.env`` sur la machine qui doit faire repartir rafa.

Restaurez ensuite la dernière version de la base de données oracle de rafa comme ceci :
- s'assurer que conteneur rafa-db est démarré :
  ```
  docker-compose up rafa-db -d
  ```
- entrer dans le conteneur :
  ```
  docker exec -it rafa-db bash
  ```
- lancer les commandes suivantes :
  ```
  docker exec -it rafa-db-dumper bash
  impdp system/$ORACLE_DB_DUMPER_ORACLE_PWD@//$ORACLE_DB_DUMPER_HOST:$ORACLE_DB_DUMPER_PORT/FREE schemas=$ORACLE_DB_DUMPER_ORACLE_SCHEMA_TO_BACKUP TABLE_EXISTS_ACTION=REPLACE directory=BACKUP_DIR dumpfile=rafa-db-2023-09-07.dmp logfile=rafa-db-2023-09-07.log
  ```


Lancez alors toute l'application rafa et vérifiez qu'elle fonctionne bien :
```bash
cd /opt/pod/rafa-docker/
docker-compose up -d
```

## Développements

### Mise à jour du code source de Rafa

Dans le cas où une nouvelle version de Rafa est à déployer, son code source aura été mis à jour ici : https://git.abes.fr/depots/Rafa

Il est alors nécessaire de mettre à jour le code source de Rafa dans le répertoire `/opt/pod/rafa-docker/images/Rafa/` et de le caler sur la version cible (exemple: 1.18.19) :
```bash
cd /opt/pod/rafa-docker/images/Rafa/
git pull origin 1.18.19
```
Ensuite de mettre en cohérence ce n° de version dans la variable RAFA_VERSION dans le fichier `/opt/pod/rafa-docker/.env` :
```bash
cd /opt/pod/rafa-docker/
sed -i 's#^RAFA_VERSION=.*$#RAFA_VERSION=1.18.19#g' /opt/pod/rafa-docker/.env
```

Puis de rebuilder les images et de redéployer les conteneurs dans cette nouvelle version :
```bash
cd /opt/pod/rafa-docker/
docker-compose up --build -d
```

### Mise à jour et déploiement automatique vers la dernière version de Rafa

Le script suivant fait tout le travail au dessus en une seule opération en se callant sur la dernière release trouvée :
```bash
cd /opt/pod/rafa-docker/images/Rafa/
git fetch --tags
RAFA_LAST_VERSION=$(git describe --tags --abbrev=0)
git pull origin $RAFA_LAST_VERSION
cd /opt/pod/rafa-docker/
sed -i "s#^RAFA_VERSION=.*$#RAFA_VERSION=$RAFA_LAST_VERSION#g" /opt/pod/rafa-docker/.env
docker-compose up --build -d
```

