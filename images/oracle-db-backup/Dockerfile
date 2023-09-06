FROM container-registry.oracle.com/database/free:23.2.0.0
HEALTHCHECK NONE

USER root

# crontab system
# cronie: replace crond because CTRL+C is not suported with docker (so it is difficult to stop a such container if crond was used)
# gettext: to have envsubst for crontab template tasks.tmpl
RUN dnf install -y cronie gettext && \
    crond -V && rm -rf /etc/cron.*/*
COPY ./tasks.tmpl /etc/cron.d/tasks.tmpl

# backup scripts
COPY ./oracle-db-backup.sh             /scripts/oracle-db-backup.sh
COPY ./oracle-db-cleanup-old-backup.sh /scripts/oracle-db-cleanup-old-backup.sh
RUN chmod +x /scripts/oracle-db-backup.sh
RUN chmod +x /scripts/oracle-db-cleanup-old-backup.sh

# where backup are done (this is a mounted and shared volume with the real oracle database)
RUN mkdir /backup/ && chmod 777 /backup/

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["crond", "-n"]

