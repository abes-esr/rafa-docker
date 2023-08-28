# rafa-docker

Configuration docker 🐳 pour déployer l'application Rafa (référentiel des annuaires fonctionnels de l'Abes).

Le code source (non opensource car vieux code) de rafa est accessible ici :
https://git.abes.fr/depots/Rafa/


## URLs de rafa

Les URLs correspondantes aux déploiements en local, test et prod de rafa sont les suivantes :

- local : http://127.0.0.1:11080/
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
mkdir -p rafa-docker/images/
git clone -b docker https://git.abes.fr/depots/Rafa.git rafa-docker/images/Rafa/
```

Configurer l'application depuis l'exemple du [fichier ``.env-dist``](./.env-dist) (ce fichier contient la liste des variables avec des explications et des exemples de valeurs) :
```bash
cd /opt/pod/rafa-docker/
cp .env-dist .env
# personnaliser alors le contenu du .env
```

Démarrer l'application :
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
- la base de données oracle de Rafa

### Restauration depuis une sauvegarde

Réinstallez l'application rafa depuis la [procédure d'installation ci-dessus](#installation) et récupéré depuis les sauvegardes le fichier ``.env`` et placez le dans ``/opt/pod/rafa-docker/.env`` sur la machine qui doit faire repartir rafa.

Restaurez ensuite la dernière version de la base de données oracle de rafa.

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

