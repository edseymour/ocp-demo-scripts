#!/bin/bash

function check_exists()
{
  [[ "$2" == "" ]] && echo "Missing $1" && exit 1
}

function default_if_empty()
{
  if [[ "$2" == "" ]]; then 
    echo $1
  else
    echo $2
  fi
}


USAGE="$0 <number of users> <gogs-url> <nexus-url>"

NUM=$1
check_exists "number of users to create, $USAGE" $NUM
GOGSURL=$2
check_exists "Gogs URL, $USAGE" $GOGSURL
MAVENURL=$3
check_exists "Maven repository URL, $USAGE" $MAVENURL

while IFS=, read user password name
do

sed 's|%GITURL%|'"$GOGSURL/$user"'/monster.git|g' monster-dev.yaml | sed 's|%MAVENURL%|'"$MAVENURL"'|g' | oc replace -n dev-$user -f -
sed 's/%DEVNAMESPACE%/'"dev-$user"'/g' monster-prod.yaml | oc replace -n uat-$user -f -

done <users.csv
