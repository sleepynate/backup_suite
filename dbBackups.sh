#!/bin/bash

####### Config path
# Path to load the config file from
CONFIGDIR=$(cd $(dirname $0); pwd -P)/ 
source $CONFIGDIR/config.sh

# This is the minimum allowed backup filesize in bytes.
# If a DB is smaller, send an alert email!
FILESIZE=8192

ENDEMAILTEXT="Summary of Backups on $HOST"

mkdir -p $BACKUPDIR

for dbName in $DBLIST; do

	TODAY=$BACKUPDIR/$DBPREFIX$( echo $dbName )_$(date +%Y-%m-%d).sql

	echo Dumping database $dbName to $TODAY
	ENDEMAILTEXT=$ENDEMAILTEXT"$dbName	"

	mysqldump -u"$DBUSER" -p"$DBPASS" --opt \
		"$DBPREFIX$(echo $dbName)" > $TODAY

	if [ `du -b $TODAY | cut -f1` -lt $FILESIZE ]
	then
		echo Big problem while running backup on $dbName. File too small. It is only `du -h $TODAY | cut -f1`
		echo "While backing up $dbName on $HOST, $TODAY did not yield a valid filesize. You may wish to check it." | \
		    mail -s "Errors while backing up $HOST" $EMAILS
			ENDEMAILTEXT=$ENDEMAILTEXT"didn't make .sql file properly	"
	else
		echo Wrote $dbName to $TODAY OK.
		ENDEMAILTEXT=$ENDEMAILTEXT"written to $TODAY	filesize: `du -h $TODAY | cut -f1`	"
	fi

	cd /$BACKUPDIR/
	gzip $TODAY
	if [ -e $TODAY.gz ]
	then
		echo Archive of $dbName successful.
		ENDEMAILTEXT=$ENDEMAILTEXT"zipped to size filesize: `du -h $TODAY.gz | cut -f1`	"
	else
		echo Big problem while running backup on $dbName. No gzip file.
		echo "While backing up $dbName on $HOST, couldn't create a valid gzip. You may wish to check it." | \
		    mail -s "Errors while backing up $HOST" $EMAILS
		ENDEMAILTEXT=$ENDEMAILTEXT"Couldn't create gzip file"
	fi

	ENDEMAILTEXT=$ENDEMAILTEXT""
done

if [ -n $SCPLOCATION ] ; then
	scplist=' '
	for dbName in $DBLIST; do
		scplist=$scplist' '$BACKUPDIR/$DBPREFIX$( echo $dbName )_$(date +%Y-%m-%d).sql.gz
	done
	echo scp $scplist $SCPLOADTION
	scp $scplist $SCPLOCATION
	ENDEMAILTEXT="$ENDEMAILTEXT$scplist copied to $SCPLOCATION"
fi

echo "Backup on $HOST ran $(date +'%a %m/%d/%y')
$ENDEMAILTEXT" | \
	mail -s "Backup of $HOST for $(date +%Y-%m-%d)" $EMAILS 
