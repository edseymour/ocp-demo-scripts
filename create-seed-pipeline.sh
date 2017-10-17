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

sed 's/%APP/monster/g' pipeline-seed.yaml | sed 's/%DEV_PROJ/dev-'"$user"'/g' | sed 's/%TEST_PROJ/uat-'"$user"'/g' | sed 's/%PROD_PROJ/prod-'"$user"'/g' | oc process -f - | oc create -n dev-$user -f -


done <users.csv
