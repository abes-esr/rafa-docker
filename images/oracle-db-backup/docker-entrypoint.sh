#!/bin/bash

# Default container parameters
export ORACLE_DB_BACKUP_CRON=${ORACLE_DB_BACKUP_CRON:='50 4 * * *'}
export ORACLE_DB_BACKUP_AT_STARTUP=${ORACLE_DB_BACKUP_AT_STARTUP:='1'}
export ORACLE_DB_DUMPER_DUMPNAME_PATTERN=${ORACLE_DB_DUMPER_DUMPNAME_PATTERN:='db-$(date +''%Y-%m-%d'')'}
export ORACLE_DB_BACKUP_CLEANUP_TIME=${ORACLE_DB_BACKUP_CLEANUP_TIME:='7'}

# check ORACLE_DB_BACKUP_CLEANUP_TIME is a positive number (greater than zero)
REGEXP_NUMBER='^[0-9]+$'
if [[ $ORACLE_DB_BACKUP_CLEANUP_TIME =~ $REGEXP_NUMBER ]]; then
  if [ "$ORACLE_DB_BACKUP_CLEANUP_TIME" -lt 1 ]; then
    echo "Erreur : ORACLE_DB_BACKUP_CLEANUP_TIME doit être strictement supérieur à zéro (Valeur actuelle: $ORACLE_DB_BACKUP_CLEANUP_TIME)"
    exit 1
  fi
else
  echo "Erreur : ORACLE_DB_BACKUP_CLEANUP_TIME n'est pas un entier positif (Valeur actuelle: $ORACLE_DB_BACKUP_CLEANUP_TIME)"
  exit 1
fi


# setup env for crontab
echo "$(env)" > /etc/environment

# load crontab config from the template
envsubst < /etc/cron.d/tasks.tmpl > /etc/cron.d/tasks
echo "-> Installation des crontab :"
cat /etc/cron.d/tasks
crontab /etc/cron.d/tasks

# Force or not a backup at container startup
if [ "$ORACLE_DB_BACKUP_AT_STARTUP" = "1" ]; then
  echo "-> Run a first backup at startup"
  /scripts/oracle-db-backup.sh
fi

# execute CMD (crond)
exec "$@"
