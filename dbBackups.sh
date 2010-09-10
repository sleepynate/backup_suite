#!/bin/bash
#name of host
#HOST=vlad
# Path to back up to.
#BACKUPDIR=/tmp
# list of databases, space-separated, to back up
#DBLIST="db1 db2 db3"
# DB User
#DBUSER="my_user"
# DB password
#DBUSER="mypass"
# prefix to all DBLIST names
#DBPREFIX="mydb_"
# Who should we notify ?
#EMAILS="me@hotmail.com you@gmail.com we@yahoo.com"
source config.sh

# This is the minimum allowed backup filesize. If a DB is smaller, send an alert email!
FILESIZE=1024

ENDEMAILTEXT="Summary of Backups on $HOST\n\n"

mkdir -p $BACKUPDIR

for dbName in $DBLIST; do

	TODAY=$BACKUPDIR/$DBPREFIX$( echo $dbName )_$(date +%Y-%m-%d).sql

	echo Dumping database $dbName to $TODAY
	ENDEMAILTEXT=$ENDEMAILTEXT"$dbName\t"

	mysqldump -u"$DBUSER" -p"$DBPASS" --opt \
		"$DBPREFIX$(echo $dbName)" > $TODAY

	if [ `du $TODAY | cut -f1` -lt $FILESIZE ]
	then
		echo Big problem while running backup on $dbName. File too small.
		echo "While backing up $dbName on $HOST, $TODAY did not yield a valid filesize. You may wish to check it." | \
		    mail -s "Errors while backing up $HOST" $EMAILS
			ENDEMAILTEXT=$ENDEMAILTEXT"didn't make .sql file\t"
	else
		echo Wrote $dbName to $TODAY OK.
		ENDEMAILTEXT=$ENDEMAILTEXT"written to $TODAY\tfilesize: `du -h $TODAY | cut -f1`\t"
	fi

	cd /$BACKUPDIR/
	gzip $TODAY
	if [ -e $TODAY.gz ]
	then
		echo Archive of $dbName successful.
		ENDEMAILTEXT=$ENDEMAILTEXT"zipped to size filesize: `du -h $TODAY.gz | cut -f1`\t"
	else
		echo Big problem while running backup on $dbName. No gzip file.
		echo "While backing up $dbName on $HOST, couldn't create a valid gzip. You may wish to check it." | \
		    mail -s "Errors while backing up $HOST" $EMAILS
		ENDEMAILTEXT=$ENDEMAILTEXT"Couldn't create gzip file"
	fi

	ENDEMAILTEXT=$ENDEMAILTEXT"\n"
done

echo "Backup on $HOST ran $(date +'%a %m/%d/%y')\n$ENDEMAILTEXT" | mail -s "Backup of $HOST for $(date +%Y-%m-%d)" $EMAILS 

