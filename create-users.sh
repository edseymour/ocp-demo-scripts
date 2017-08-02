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


USAGE="$0 <number of users> "

NUM=$1
check_exists "number of users to create, $USAGE" $NUM


cp users.csv users.csv-bak
rm -f users.csv

for userid in $(seq 1 $NUM); do

   echo "demo$userid,$(mktemp -u XXXXXXXX),Demo User $userid" >> users.csv

done

