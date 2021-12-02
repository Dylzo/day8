#!/bin/sh

### Config ###

### Postgres ###
PUSER="postgres"

# DAY/MONTHS
DAYS=7
MONTHS=1
YEARS=1

NOW=$(date +%Y%m%d)

### Binaries ###
TAR="$(which tar)"
GZIP="$(which gzip)"
PGDUMP="$(which pg_dump)"
PGDUMPALL="$(which pg_dumpall)"
SUDO="$(which sudo)"

BACKUP=/home/backup

### create tmp dir ###
mkdir $BACKUP/$NOW

### all databases postgres ###
DBS="$(su - $PUSER -c 'psql -c "select datname from pg_database" -Xt')"
for db in $DBS
do
    if [ $db ]
    then
        FILE=$BACKUP/$NOW/$db.sql.gz
        $SUDO -u $PUSER $PGDUMP $db $i | $GZIP -9 > $FILE
    fi
done

FILE=$BACKUP/$NOW/pgdumpall.sql.gz
$SUDO -u $PUSER $PGDUMPALL | $GZIP -9 > $FILE

### all into one archive ###
ARCHIVEDB=$BACKUP/postgres-$NOW.tar.gz

cd $BACKUP/$NOW;
$TAR -zcvf $ARCHIVEDB ./

### clear ###
rm -rf $BACKUP/$NOW

### Time / Delete ###
cd $BACKUP

LIST="$(ls -1F | grep -v \/)"
for li in $LIST
do
    EXIST=0

    if [ "$li" = "." ]
    then
        continue
    fi

    for day in `seq 0 $DAYS`
    do
        d="$(date +%Y%m%d -d "$day days ago")"
        if [ "postgres-$d.tar.gz" = "$li" ]
        then
            EXIST=1
            continue
        fi
    done

    for month in `seq 0 $MONTHS`
    do
        d="$(date +%Y%m01 -d "$month month ago")"
        if [ "postgres-$d.tar.gz" = $li ]
        then
            EXIST=1
            continue
        fi
    done

    for year in `seq 0 $YEARS`
    do
        d="$(date +%Y -d "$year year ago")"
        if [ "postgres-$d.tar.gz" = $li ]
        then
            EXIST=1
            continue
        fi
    done

    if [ $EXIST -eq 0 ]
    then
        find . -type f -name "$li" -exec rm -f {} \;
    fi
done