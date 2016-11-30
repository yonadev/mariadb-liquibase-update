#!/bin/bash

ERROR_EXIT_CODE=1

echo "Setting up liquibase"
: ${USER?"USER not set"}
: ${PASSWORD?"PASSWORD not set"}
: ${URL?"URL not set"}
CHANGE_LOG=`echo /changelogs/changelog.*`
[ -f $CHANGE_LOG ] || (echo "Cannot find a single change log matching /changelogs/changelog.*" ; exit $ERROR_EXIT_CODE)

cat <<CONF > liquibase.properties
  driver: org.mariadb.jdbc.Driver
  classpath:/opt/jdbc_drivers/$DRIVER_JAR
  url: $URL
  username: $USER
  password: $PASSWORD
CONF

echo "Applying changelogs ..."
MAX_TRIES=${MAX_TRIES:-1}
COUNT=1
while [  $COUNT -le $MAX_TRIES ]; do
   echo  "Attempting to apply changelogs: attempt $COUNT of $MAX_TRIES"
   liquibase --logLevel=info --changeLogFile=$CHANGE_LOG update
   if [ $? -eq 0 ];then
   	  echo "Changelogs successfully applied"
      exit 0
   fi
   echo "Failed to apply changelogs"
   sleep 1
   let COUNT=COUNT+1
done
echo "Too many failed attempts"
exit $ERROR_EXIT_CODE
