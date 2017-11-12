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


while IFS=, read user password name
do

oc new-app monster-app -n uat-$user
oc new-app monster-app -n prod-$user


done <users.csv
