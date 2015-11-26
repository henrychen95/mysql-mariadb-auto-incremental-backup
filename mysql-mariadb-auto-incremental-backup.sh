#!/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin

#Database settings
dbUser="Database User"
dbPass="Database Password"
dbConfigFile="/etc/my.cnf"

#Date
today=$(date +%Y%m%d)
hour=$(date +%H)
yesterday=$(date -d "-1 day" +%Y%m%d)

#Folder Settings
backupPath="/root/mysqlbackup/"
baseFolder="$backupPath$today-00"
folderName="$backupPath$today-$hour"
deleteFolders="$yesterday-*"

#Amazon S3 settings
copytoS3=true
s3BucketName="AWS S3 bucket name"
s3DestFolder="$today/$hour"

echo "today is: $today"
echo "hour is: $hour"
echo "yesterday: $yesterday"
echo "folderName: $folderName"

if [ "$hour" == "00" ]
then
    echo "full backup"
    #Delete yesterday local backup files
    rm -rf $backupPath$deleteFolders

    #Do full backup
    innobackupex --no-timestamp --user=$dbUser --password="$dbPass" $folderName
else
    echo "incremental backup"
    #Do incremental backup
    innobackupex --no-timestamp --incremental --user=$dbUser --password="$dbPass" --incremental-basedir=$baseFolder $folderName

fi

#Copy backup files to S3
if [ $copytoS3 = true ]; then
aws s3 cp $folderName s3://$s3BucketName/$s3DestFolder --recursive
fi
