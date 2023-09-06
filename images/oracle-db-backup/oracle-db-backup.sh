#!/bin/bash
# This script does the backup!

# How is named the backup files.
# A pattern is attended because it could be like that:
# ORACLE_DB_DUMPER_DUMPNAME_PATTERN: "rafa-db-$(date +'%Y-%m-%d')"
eval "ORACLE_DB_DUMPER_DUMPNAME=$ORACLE_DB_DUMPER_DUMPNAME_PATTERN"

# configure oracle database bind to the /backup directory where the backup will be done
echo "CREATE OR REPLACE DIRECTORY BACKUP_DIR AS '/backup';" \
  | sqlplus sys/$ORACLE_DB_DUMPER_ORACLE_PWD@//$ORACLE_DB_DUMPER_HOST:$ORACLE_DB_DUMPER_PORT/FREE as sysdba

# Tells oracle to do the backup with the expdp command
# Warning:
#    the backup files are NOT written from this container,
#    the .dmp and .log files are created from the oracle database container.
expdp system/$ORACLE_DB_DUMPER_ORACLE_PWD@//$ORACLE_DB_DUMPER_HOST:$ORACLE_DB_DUMPER_PORT/FREE \
  schemas=$ORACLE_DB_DUMPER_ORACLE_SCHEMA_TO_BACKUP \
  directory=BACKUP_DIR \
  dumpfile=$ORACLE_DB_DUMPER_DUMPNAME.dmp \
  logfile=$ORACLE_DB_DUMPER_DUMPNAME.log
