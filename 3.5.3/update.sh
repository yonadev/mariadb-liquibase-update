#!/bin/bash

# Note - We are running under K8S as an init job.
# If we exit non zero we will be rescheduled until success

ERROR_EXIT_CODE=1
GIT_BASE="https://raw.githubusercontent.com/yonadev/yona-server/"

apply_external_json () {
  SOURCE="${GIT_BASE}build-${RELEASE}/dbinit/data/${1}"
  TARGET="${2}"
  DOWNLOAD="${1}"
  download_validate $DOWNLOAD $SOURCE
  if [ $? -eq 1 ]; then
    echo "Failed to download valid json from ${TARGET}"
    return 1
  fi
  upload_validate $DOWNLOAD $TARGET
  if [ $? -eq 1 ]; then
    echo "Failed to upload valid json to ${TARGET}"
    return 1
  fi
}

download_validate () {
  STATUS=$(curl -s -o "/tmp/${1}" -w '%{http_code}' "${2}")
  if [ $STATUS != "200" ]; then
    echo "Failed to download ${2} - Error Code ${STATUS}"
    return 1
  fi
  /usr/local/bin/jq . "/tmp/${1}"
  if [ $? -ne 0 ]; then
    echo "Download fails json validation ${2}"
    cat ${2}
    return 1
  fi
}

upload_validate () {
  STATUS=$(curl -s -o "/tmp/response" -w '%{http_code}' -X PUT "${2}" -d @/tmp/${1} --header "Content-Type: application/json")
  if [ $STATUS != "200" ]; then
    echo "Failed to post ${2} - Error Code ${STATUS}"
    cat /tmp/response
    return 1
  fi
  return 0
}

liquibase_apply () {
  echo "Applying changelogs ..."
  MAX_TRIES=${MAX_TRIES:-1}
  COUNT=1
  while [  $COUNT -le $MAX_TRIES ]; do
     echo  "Attempting to apply changelogs: attempt $COUNT of $MAX_TRIES"
     liquibase --logLevel=info --changeLogFile=$CHANGE_LOG update
     if [ $? -eq 0 ];then
        echo "Changelogs successfully applied"
        if [ -n "${RELEASE}" ]; then
          echo "Tagging with ${RELEASE}"
          liquibase tag ${RELEASE}
        fi
        return 0
     fi
     echo "Failed to apply changelogs"
     sleep 2
     let COUNT=COUNT+1
  done
  echo "Too many failed attempts"
  return 1
}

echo "Setting up liquibase"
: ${USER?"USER not set"}
: ${PASSWORD?"PASSWORD not set"}
: ${URL?"URL not set"}
[ -d /changelogs ] || (echo "Folder /changelogs/ does not exist" ; exit $ERROR_EXIT_CODE)
cd /changelogs
CHANGE_LOG=`echo changelog.*`
[ -f "$CHANGE_LOG" ] || (echo "Cannot find a single change log matching /changelogs/changelog.*" ; exit $ERROR_EXIT_CODE)

cat <<CONF > liquibase.properties
  driver: org.mariadb.jdbc.Driver
  classpath:/opt/jdbc_drivers/$DRIVER_JAR
  url: $URL
  username: $USER
  password: $PASSWORD
CONF

#Main 

# Apply Liquibase
if [ $? -eq 1 ]; then
  echo "Failed to apply Liquibase Changes - Exiting"
  exit $ERROR_EXIT_CODE
fi

if [ -n "${RELEASE}" ]; then
  # Apply Quartz Jobs
  echo "Applying Quartz Jobs"
  apply_external_json "QuartzOtherJobs.json" "http://batch.yona.svc.cluster.local:8080/scheduler/jobs/OTHER/"
  if [ $? -eq 1 ]; then
    exit $ERROR_EXIT_CODE
  fi

  # Apply Quartz Triggers (requires RELEASE env to be set)
  echo "Applying Quartz Triggers"
  apply_external_json "QuartzOtherCronTriggers.json" "http://batch.yona.svc.cluster.local:8080/scheduler/triggers/cron/OTHER/"
  if [ $? -eq 1 ]; then
    exit $ERROR_EXIT_CODE
  fi

  # Apply Categories
  echo "Applying Categories"
  apply_external_json "productionActivityCategories.json" "http://admin.yona.svc.cluster.local:8080/activityCategories/"
  if [ $? -eq 1 ]; then
    exit $ERROR_EXIT_CODE
  fi
else
  echo "RELEASE environment variable not set - Not running JSON updates"
fi

echo "All updates applied"
exit 0
