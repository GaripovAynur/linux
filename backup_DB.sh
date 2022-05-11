#!/usr/bin/env bash
set -e
##############################################
# Backup PostgreSQL DB and delete old backups.
# Run from cron every night
# Store backups on a remote backups storage on PVE3 via NFS


#########################
# Make a full base backup
#

# Define where full backups are stored
case $# in
0|1) echo "Usage: $0 <backup directory> <PostgreSQL version>" 1>&2; exit 1
esac

system="saas"
backup_dir=$1
pgsql_ver=$2

POSTGRES_UID=$(id -u postgres)
RUNNING_EUID=$(id -u)





##############make buckup

if [ "$POSTGRES_UID" -ne "$RUNNING_EUID" ]; then
   logger -t $0 -p cron.error "$0 ERROR: This script should be running as a postgres user"
   exit 1
fi


# Define a name of a backup dir to store full basebackup.
basebackup="${backup_dir}/$system.$(date +%Y%m%d)"

if [ ! -d "$basebackup" ]; then
  mkdir "$basebackup" && chown postgres:postgres "$basebackup" && chmod 750 "$basebackup"
  /usr/bin/pg_basebackup -D "$basebackup" -F t -R -X stream -z
else
  logger -t $0 -p cron.error "$0 ERROR: Directory $basebackup already exists."
fi


####################
# Delete old backups
#

# How many full backups to keep
days_to_keep=2
count=0

if [ $days_to_keep -eq 0 ]; then
   logger -p cron.err -t $0 "Error - number of days to keep backups can't be less than one."
fi
for dir in `ls -td ${backup_dir}/$system.*`; do
   if tar -xzOf ${dir}/base.tar.gz &> /dev/null; then
      if tar -xzOf ${dir}/pg_wal.tar.gz &> /dev/null; then
          pg_wal=$(tar -tzvf ${dir}/pg_wal.tar.gz | awk 'length($6) == 24 && NR == 1 { print $6 }')
          count=$((count + 1))
          if [ "$count" -gt "$days_to_keep" ]; then
             logger -t $0 -p cron.info "Removing old basebackup $dir"
             rm -rf $dir
             pg_wal_keep=$pg_wal_prev
          fi
          pg_wal_prev=$pg_wal
        else
          logger -p cron.err -t $0 "Error extracting ${dir}/pg_wal.tar.gz to get pg_wal filename for archivecleanup"
      fi
   else
      logger -p cron.info -t $0 "Error extracting ${dir}/base.tar.gz - removing $dir"
      rm -rf $dir
   fi
done

if [ $count -ne 0 ]; then
   if [ "$pg_wal_keep" != "" ]; then
      logger -p cron.info -t $0 "Running pg_archivecleanup -d $backup_dir $pg_wal_keep"
      /usr/pgsql-${pgsql_ver}/bin/pg_archivecleanup -d $backup_dir $pg_wal_keep 2>&1 | logger -p cron.info -t $0
      logger -p cron.info -t $0 "Deleting old *.backup points older than ${backup_dir}/${pg_wal_keep}"
      find $backup_dir -type f -name "*.backup" -not -newer ${backup_dir}/${pg_wal_keep} -delete 2>&1 | logger -p cron.info -t $0
   else
     logger -t $0 -p cron.info "There is no any old pg_wals to delete."
   fi
fi


###################################____MongoDB___###############################################################

###############dump#############
# Make a full base backup mongodb

now_data=$(date +"%m-%d-%y")

find $backup_dir/mongodb/*.mongodb -mtime +0 -exec rm {} \;

mongodump --gzip --archive=$backup_dir/mongodb/$now_data.gz.mongodb

###Restore#####
#mongorestore --gzip --drop --archive=$backup_dir/mongodb/*.gz.mongodb
