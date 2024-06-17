# rafa-docker

Configuration docker 🐳 pour déployer l'application Rafa (référentiel des annuaires fonctionnels de l'Abes).

![image](https://github.com/abes-esr/rafa-docker/assets/328244/1bf18055-d992-4da7-b922-57856261e104)


Le code source (non opensource car vieux code) de rafa est accessible ici :  
https://git.abes.fr/depots/Rafa/


## URLs de rafa

Les URLs correspondantes aux déploiements en local, test et prod de rafa sont les suivantes :

- local : http://127.0.0.1:15180/
- dev : https://rafa-dev.abes.fr
- test : https://rafa-test.abes.fr
- prod : https://rafa.abes.fr

## Prérequis

Disposer de :
- ``docker``
- ``docker compose``

## Installation

Déployer la configuration docker dans un répertoire :
```bash
# adaptez /opt/pod/ avec l'emplacement où vous souhaitez déployer l'application
cd /opt/pod/
git clone https://github.com/abes-esr/rafa-docker.git

cd /opt/pod/rafa-docker/
mkdir -p images/
git clone https://git.abes.fr/depots/Rafa.git ./images/Rafa/
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
chmod 777 -R ./volumes/rafa-db/oradata/ ./volumes/rafa-db/backup/ ./volumes/rafa-db/setup-scripts/
docker compose up -d rafa-db rafa-db-dumper # a noter que le premier démarrage peut prendre jusque à 10 minutes
docker exec -it rafa-db-dumper bash
impdp system/$ORACLE_DB_DUMPER_ORACLE_PWD@//$ORACLE_DB_DUMPER_HOST:$ORACLE_DB_DUMPER_PORT/FREE \
      schemas=$ORACLE_DB_DUMPER_ORACLE_SCHEMA_TO_BACKUP \
      TABLE_EXISTS_ACTION=REPLACE \
      directory=BACKUP_DIR \
      dumpfile=rafa-db-2023-09-07.dmp logfile=rafa-db-2023-09-07.impdp.log
```

Au final on peut démarrer le reste de l'application comme ceci :
```bash
cd /opt/pod/rafa-docker/
docker compose up --build -d
```

## Démarrage et arrêt

```bash
# pour démarrer l'application (ou pour appliquer des modifications 
# faites dans /opt/pod/rafa-docker/.env)
cd /opt/pod/rafa-docker/
docker compose up -d
```

Remarque : retirer le ``-d`` pour voir passer les logs dans le terminal et utiliser alors CTRL+C pour stopper l'application

```bash
# pour stopper l'application
cd /opt/pod/rafa-docker/
docker compose stop


# pour redémarrer l'application
cd /opt/pod/rafa-docker/
docker compose stop
docker compose start
```

**Point d'attention** : éviter d'utiliser la commande ``docker compose restart`` car cette dernière ne respecte pas [la directive ``depends_on`` de ``rafa-web``](https://github.com/abes-esr/rafa-docker/blob/dd9a39000540b441107dfbca16a751f9c158a342/docker-compose.yml#L33-L35) et cela provoquera une erreur 404 temporaire au démarrage du conteneur ``rafa-web`` car son WAR n'arrivera pas à se déployer du fait que ``rafa-db`` n'est pas encore démarré. Cette erreur 404 sera temporaire car un système automatique de redémarrage du conteneur ``rafa-web`` a été mise en place à partir du 23/02/2024.


## Supervision

```bash
# pour visualiser les logs de l'appli
cd /opt/pod/rafa-docker/
docker compose logs -f --tail=100
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
- localiser ou bien déposer le fichier à restaurer dans le répertoire `/opt/pod/rafa-docker/volumes/rafa-db/backup/`, exemple :
  ```
  -rw-rw----+ 1                54321 docker@levant.abes.fr 8376320 Dec  3 05:52 rafa-db-2023-12-03.dmp
  -rw-rw----+ 1                54321 docker@levant.abes.fr    5617 Dec  3 05:52 rafa-db-2023-12-03.log
  -rw-rw----+ 1                54321 docker@levant.abes.fr 8376320 Dec  4 05:52 rafa-db-2023-12-04.dmp
  -rw-rw----+ 1                54321 docker@levant.abes.fr     436 Dec  4 09:51 rafa-db-2023-12-04.log
  ```
- s'assurer que les conteneurs rafa-db et rafa-db-dumper sont démarrés :
  ```
  docker compose up rafa-db rafa-db-dumper -d
  ```
- entrer dans le conteneur, identifiez le dump à restaurer et régler éventuellement ses droits (l'outil de restauration est très sensible aux droits positionnés sur le fichier dmp) :
  ```
  docker exec -it rafa-db-dumper bash
  chown oracle /backup/rafa-db-2024-06-15.dmp
  chmod 660 /backup/rafa-db-2024-06-15.dmp
  ```
- lancer la commandes suivantes (en remplaçant le nom du fichier) :
  ```bash
  impdp system/$ORACLE_DB_DUMPER_ORACLE_PWD@//$ORACLE_DB_DUMPER_HOST:$ORACLE_DB_DUMPER_PORT/FREE \
        schemas=$ORACLE_DB_DUMPER_ORACLE_SCHEMA_TO_BACKUP \
        TABLE_EXISTS_ACTION=REPLACE \
        directory=BACKUP_DIR \
        dumpfile=rafa-db-2023-06-15.dmp \
        logfile=rafa-db-2023-06-15.impdp.log
  ```

Lancez alors toute l'application rafa et vérifiez qu'elle fonctionne bien :
```bash
cd /opt/pod/rafa-docker/
docker compose up -d
```

### Vider complètement la base de données

Il peut être utile de recharger depuis zéro la base de données dans le cadre d'une restauration. Pöur cela il est recommandé de nettoyer complètement la base de données en supprimant totalement le répertoire où Oracle stock ses données.

Voici comment procéder :
```bash
cd /opt/pod/rafa-docker/
docker compose down rafa-db rafa-db-dumper
rm -rf /opt/pod/rafa-docker/volumes/rafa-db/oradata/
git checkout /opt/pod/rafa-docker/volumes/rafa-db/oradata/
chmod -R 777 /opt/pod/rafa-docker/volumes/rafa-db/oradata/
```

## Développements

### Mise à jour du code source de Rafa

TLDR : une procédure à copier coller est dispo dans la [section juste après](#mise-à-jour-et-déploiement-automatique-vers-la-dernière-version-de-rafa)

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
docker compose up --build -d
```

### Mise à jour et déploiement automatique vers la dernière version de Rafa

Le script suivant fait tout le travail au dessus en une seule opération en se callant sur la dernière release trouvée :
```bash
cd /opt/pod/rafa-docker/images/Rafa/
git pull 
RAFA_LAST_VERSION=$(git describe --tags --abbrev=0)
git checkout $RAFA_LAST_VERSION
cd /opt/pod/rafa-docker/
sed -i "s#^RAFA_VERSION=.*\$#RAFA_VERSION=$RAFA_LAST_VERSION#g" /opt/pod/rafa-docker/.env
docker compose up --build -d
```

### Copier les données d'une instance de Rafa vers une autre

Pour cela on peut utiliser l'outil SQL developer et utiliser sa fonctionnalité `Copie de base de données` : 
![image](https://github.com/abes-esr/rafa-docker/assets/328244/b2321eb7-3612-46d1-8e73-8705f5782d21)

![image](https://github.com/abes-esr/rafa-docker/assets/328244/1c7a1d60-10f3-4b6f-8506-465652997cc0)


Remarque : la copie des données de Rafa entre un Oracle 12c et un Oracle 23.2 fonctionne.

