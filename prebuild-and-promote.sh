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

function watch_pod()
{
pod=$1
proj=$2
counter=0
echo "*** Waiting for pod $pod in project $proj"
while [[ $(oc get pod $pod --no-headers -n $proj  2>/dev/null | grep Running | wc -l) -lt 1 ]]
do
   sleep 2
   counter=$((counter + 1))
   [[ $counter -gt 200 ]] && echo "*** Gave up waiting for pod $pod in project $proj after 400 seconds" && break
done

echo "*** Waiting for watched pod to complete $proj/$pod"
oc logs -f $pod -n $proj  2>&1 >> logs/$proj.log

}

function test_dev()
{
user=$1
proj=dev-$user
echo "*** Testing development project $proj"
oc delete all --all -n $proj 

# create seed pipeline
sed 's/%APP/monster/g' pipeline-seed.yaml | sed 's/%DEV_PROJ/dev-'"$user"'/g' | sed 's/%TEST_PROJ/uat-'"$user"'/g' | sed 's/%PROD_PROJ/prod-'"$user"'/g' | oc process -f - | oc create -n dev-$user -f -

oc new-app monster -n $proj  >> logs/$proj.log

watch_pod monster-1-build $proj >> logs/$proj.log
watch_pod monster-1-deploy $proj >> logs/$proj.log

}

function build_and_deploy()
{
  user=$1
  
  test_dev $user

  oc start-build monster-pipeline-preseed -n dev-$user

  watch_pod monster-1-deploy uat-$user >> logs/$proj.log
  watch_pod monster-1-deploy prod-$user >> logs/$proj.log
}

function process_users()
{

  count=0
  modu=1

  while IFS=, read user password name
  do

    test_dev $user &

    let "count++"
    let "modu = $count % 10"
    if [ "$modu" -eq 0 ]; then
      echo "*** Waiting on batch to finish..."
      wait
      echo "*** Batch finished, next batch..."
    fi

  done <users.csv

  echo "*** Waiting for builds to complete"
  wait

  echo "*** Tidying up"
  while IFS=, read user password name
  do
    oc delete all --all -n dev-$user
  done <users.csv

}

process_users
