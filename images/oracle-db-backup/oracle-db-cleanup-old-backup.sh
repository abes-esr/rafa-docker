#!/bin/bash
# script to remove the old backup file 
# example, remove 7 days older files

ORACLE_DB_CLEANUP_DATE_LIMIT=$(date -d "$ORACLE_DB_BACKUP_CLEANUP_TIME days ago" +%Y-%m-%d)
touch --date "$ORACLE_DB_CLEANUP_DATE_LIMIT" /tmp/oracle-db-cleanup-ref
FILES_TO_RM=$(find /backup/ -not -newer /tmp/oracle-db-cleanup-ref -type f)
if [ "$FILES_TO_RM" == "" ]; then
    echo "-> No backup files to remove older than $ORACLE_DB_BACKUP_CLEANUP_TIME days, here is the (not to cleanup yet) files:"
    find /backup/ -type f
else
    echo "-> Following backup files are going to be deleted (older than $ORACLE_DB_BACKUP_CLEANUP_TIME days):"
    find /backup/ -not -newer /tmp/oracle-db-cleanup-ref -type f
    find /backup/ -not -newer /tmp/oracle-db-cleanup-ref -type f -exec ls {} \;
fi 


