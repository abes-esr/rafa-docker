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

Vous pouvez soit procéder à une réinstallation complète de l'application (cf section [procédure d'installation ci-dessus](#installation)), soit procéder à une restauration des données.

Pour restaurer uniquement les données de l'application, commencez par vous positionner sur le serveur où l'on souhaite restaurer les données de l'application (ici diplotaxis3-test est pris comme exemple) :

```bash
ssh diplotaxis3-test
cd /opt/pod/rafa-docker/
```

Restaurez ensuite le ``.env`` depuis les sauvegardes :

```bash
cd /opt/pod/rafa-docker/
rsync -av \
  devel@sotora:/backup_pool/diplotaxis3-prod/daily.0/racine/opt/pod/rafa-docker/.env \
  /opt/pod/rafa-docker/
```

Restaurez ensuite la base de données depuis un dump :

```bash
cd /opt/pod/rafa-docker/

# récupération du dump depuis le serveur de sauvegardes (adaptez la date)
rsync -ravL \
  devel@sotora:/backup_pool/diplotaxis3-prod/daily.0/racine/opt/pod/rafa-docker/volumes/rafa-db/backup/rafa-db-2025-01-23.dmp \
  /opt/pod/rafa-docker/volumes/rafa-db/backup/

# vider physiquement la base de données
# (cf section juste après)
# sans cette opération, vous rencontrerez des erreurs de ce type :
# ORA-31684: Object type SEQUENCE:"RAFA"."SEQ_RESEAU" already exist

# s'assurer que les conteneurs rafa-db et rafa-db-dumper sont démarrés
docker compose up rafa-db rafa-db-dumper -d
```

Entrez ensuite dans le conteneur pour régler les droits sur les fichiers de dump car l'outil de restauration est très sensible aux droits positionnés sur le fichier dmp :

```bash
docker exec -it rafa-db-dumper bash
chown oracle /backup/rafa-db-2025-01-23.dmp
chmod 660 /backup/rafa-db-2025-01-23.dmp
```

Lancez finalement la commande suivante pour importer le dump depuis le conteneur rafa-db-dumper :

```bash
docker exec -it rafa-db-dumper bash
impdp system/$ORACLE_DB_DUMPER_ORACLE_PWD@//$ORACLE_DB_DUMPER_HOST:$ORACLE_DB_DUMPER_PORT/FREE \
  schemas=$ORACLE_DB_DUMPER_ORACLE_SCHEMA_TO_BACKUP \
  TABLE_EXISTS_ACTION=REPLACE \
  directory=BACKUP_DIR \
  dumpfile=rafa-db-2025-01-23.dmp \
  logfile=rafa-db-2025-01-23.dmp.impdp.log
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

## Procédures d'exploitations

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
git switch master
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

### Régler le mot de passe ORACLE si il expire

Une erreur rencontrée le 13/11/2024 était liée au mot de passe d'ORACLE qui avait expiré et qui empêchait le conteneur rafa-db-dumper de fonctionner. Ce bug était lié au réglage initial du mot de passe SYSTEM qui était réglé avec une expiration.
Voici les commandes passées pour désactiver l'expiration du mot de passe SYSTEM (remplacer "xxxxxxxxxxxxx" par le mot de passe venant de la variable ``RAFA_DB_ORACLE_PWD``) :
```bash
# rentrer dans le conteneur
docker exec -it rafa-db bash

# lancer le client sql d'oracle, visualiser les mdp expirés et régler les expirations des mots de passes
sqlplus /nolog
connect / as SYSDBA
SELECT username, account_status FROM dba_users WHERE ACCOUNT_STATUS LIKE '%EXPIRED%';
ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME UNLIMITED;
alter user SYSTEM identified by xxxxxxxxxxxxx account unlock;
commit;
```

### Comment corriger l'erreur ORA-12954

Si rafa-db-dumper rencontre ce type d'erreur ``ORA-12954: The request exceeds the maximum allowed database size of 12 GB.`` cela signifie que des tables système d'ORACLE ont accumulé trop d'information (statistiques, historiques) pour la version FREE d'Oracle qui limite la taille à max 12GB. Voici comment procéder pour nettoyer.

Tout d'abord il faut sauvegarder avec l'ancien système de dump d'Oracle (`exp`) car en passant par `expdp` l'erreur se produira :
```bash
cd /opt/pod/rafa-docker/
sudo docker compose stop rafa-web
sudo docker exec -it rafa-db bash
exp userid=SYSTEM/$ORACLE_PWD owner=RAFA file=/backup/sauvegarde_urgence.dmp statistics=none
```

Ensuite il est nécessaire de faire une réinstallation de la base de données depuis zéro et y charger cette export ``sauvegarde_urgence.dmp``. Pour cela il faut stopper les conteneur`s de la base de données, puis nettoyer le répertoire binaire d'Oracle (on se contente dans l'exemple de le déplacer), puis de relancer la base de données (vide) et y charger le dump ``sauvegarde_urgence.dmp`` : 
```bash
cd /opt/pod/rafa-docker/
sudo docker compose down
mv ./volumes/rafa-db/oradata/ ./volumes/rafa-db/oradata.bak
mkdir ./volumes/rafa-db/oradata/ && chmod 777 ./volumes/rafa-db/oradata/
sudo docker compose up rafa-db rafa-db-dumper -d
# attendre longtemps que la bdd s'initialise (environ 10 min)
sudo docker exec -it rafa-db-dumper bash
imp system/$ORACLE_DB_DUMPER_ORACLE_PWD@//$ORACLE_DB_DUMPER_HOST:$ORACLE_DB_DUMPER_PORT/FREE \
    fromuser=$ORACLE_DB_DUMPER_ORACLE_SCHEMA_TO_BACKUP \
    touser=$ORACLE_DB_DUMPER_ORACLE_SCHEMA_TO_BACKUP \
    file=sauvegarde_urgence.dmp \
    log=sauvegarde_urgence.imp.log \
    ignore=y
```

Normalement c'est ok à ce moment précis et on peut relancer l'ensemble des conteneurs de l'application avec ``docker compose up -d``

Ci-dessous voici quelques commandes utiles pour vérifier que la base de données est dans le bon état : 
```
sudo docker exec -it rafa-db bash
sqlplus /nolog
connect / as SYSDBA
SELECT tablespace_name, 
       round(SUM(bytes) / 1024 / 1024 / 1024, 2) as used_gb
FROM dba_data_files
GROUP BY tablespace_name;
```

Cette commande devrait retourner à peu près ceci (et si la somme est proche de 12GB, warning car les sauvegardes ne fonctionneront bientôt plus) :
```
TABLESPACE_NAME                   USED_GB
------------------------------ ----------
SYSTEM                               1.13
SYSAUX                                .54
UNDOTBS1                              .04
USERS                                 .02
```


### Autres procédures

[Ci-dessous le lien vers notre documentation interne](https://abesfr.sharepoint.com/:w:/r/sites/Bouda/AppliSupport/Rafa/Documentation/RAFA_Procedures_pour_le_maintien_en_conditions_operationnelles.docx?d=wd902d9a46ae444c296170fe8eab32275&csf=1&web=1&e=d60soF) permettant de débloquer certaines situation non prévue dans les fonctionnalités de Rafa (ex: administrer les rôles).
