#!/bin/bash
# ce script est exécuté à chaque démarrage du conteneur oracle
# il permet de créer si il n'existe pas l'utilisateur RAFA et de lui régler son mot de passe
# et de lui donner les droits nécessaires pour pouvoir se connecter, créer des tables etc

echo "Création ou réinitialistion du schéma $RAFA_DATASOURCE_USER (mot de passe $RAFA_DATASOURCE_PASSWORD)"

echo "
ALTER SESSION SET \"_ORACLE_SCRIPT\"=true;
CREATE USER $RAFA_DATASOURCE_USER IDENTIFIED BY \"$RAFA_DATASOURCE_PASSWORD\";
ALTER USER $RAFA_DATASOURCE_USER IDENTIFIED BY \"$RAFA_DATASOURCE_PASSWORD\"; 
GRANT CONNECT TO $RAFA_DATASOURCE_USER CONTAINER=CURRENT;  
GRANT CREATE SESSION TO $RAFA_DATASOURCE_USER CONTAINER=CURRENT;
GRANT RESOURCE TO $RAFA_DATASOURCE_USER CONTAINER=CURRENT;               
GRANT UNLIMITED TABLESPACE TO $RAFA_DATASOURCE_USER;
" | sqlplus sys/$ORACLE_PWD@//localhost:1521/FREE as sysdba
