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
while [[ $(oc get pod $pod --no-headers -n $proj  2>/dev/null | grep "Running\|Complete" | wc -l) -lt 1 ]]
do
   sleep 2
   counter=$((counter + 1))
   [[ $counter -gt 200 ]] && echo "*** Gave up waiting for pod $pod in project $proj after 400 seconds" && break
done

echo "*** Waiting for watched pod to complete $proj/$pod"
oc logs -f $pod -n $proj  

}

function find_pod()
{
  labelled=$1
  proj=$2

  echo $(oc get pods -n $proj -l $labelled -o name --no-headers | head -n 1)

}

function pod_ready()
{
  pod=$1
  proj=$2

  statusline=$(oc get $pod -n $proj --no-headers)

  ready=$(echo $statusline | awk '{print $2}')

  echo "${ready%%/*}"
}

function watch_deploy()
{
  dc=$1
  proj=$2

  counter=0
  pod=$(find_pod deploymentConfig=$dc $proj)
  while [[ "$pod" == "" ]]
  do
    echo "*** Looking for a pod for $dc in $proj"
    sleep 2
    
    counter=$((counter + 1))
    [[ $counter -gt 15 ]] && echo "*** Gave up looking for pod $pod for $dc in project $proj after 30 seconds" && break

    pod=$(find_pod deploymentConfig=$dc $proj)
  done

  counter=0
  while [ $(pod_ready $pod $proj) -lt 1 ]
  do
    echo "*** Waiting for $pod in $proj to be ready"
    sleep 5
    counter=$((counter + 1))
    [[ $counter -gt 20 ]] && echo "*** Gave up waiting for pod $pod in project $proj after 400 seconds" && break
  done
  
}

function test_dev()
{
user=$1
proj=dev-$user
echo "*** Testing development project $proj"
oc delete all --all -n $proj 

# create seed pipeline
sed 's/%APP/monster/g' pipeline-seed.yaml | sed 's/%DEV_PROJ/dev-'"$user"'/g' | sed 's/%TEST_PROJ/uat-'"$user"'/g' | sed 's/%PROD_PROJ/prod-'"$user"'/g' | oc process -f - | oc create -n dev-$user -f -

oc new-app monster -n $proj  

watch_pod monster-1-build $proj 
watch_deploy monster $proj 
}



function build_and_deploy()
{
  user=$1
  
  test_dev $user >> logs/$user.log

  oc new-app monster-app -n uat-$user >> logs/$user.log
  oc new-app monster-app -n prod-$user >> logs/$user.log

  watch_deploy monster-mysql uat-$user >> logs/$user.log
  watch_deploy monster-mysql prod-$user >> logs/$user.log

  oc start-build monster-pipeline-preseed -n dev-$user

  watch_deploy monster uat-$user >> logs/$user.log
  watch_deploy monster-green prod-$user >> logs/$user.log
  watch_deploy monster-blue prod-$user >> logs/$user.log

  # clean up in dev
  oc delete all --all -n dev-$user
}

function process_users()
{

  # start count at 9 so that first user is used to prime nexus cache
  count=9 
  modu=1

  while IFS=, read user password name
  do

    build_and_deploy $user &

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
