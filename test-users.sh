#!/bin/bash

function check_exists()
{
  [[ "$2" == "" ]] && echo "Missing $1" && exit 1
}


TOKEN=$1
SERVER=$2
check_exists "OpenShift user token with edit access to all target projects" $TOKEN
check_exists "OpenShift server" $SERVER

OCOPTS="--token=$TOKEN --server=$SERVER"


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
while [[ $(oc get pod $pod --no-headers -n $proj $OCOPTS 2>/dev/null | grep Running | wc -l) -lt 1 ]]
do
   sleep 2
   counter=$((counter + 1))
   [[ $counter -gt 50 ]] && echo "*** Gave up waiting for pod $pod in project $proj" && break
   echo "*** Waiting for pod $proj/$pod, attempt $counter"
done

oc logs -f $pod -n $proj $OCOPTS

}

function test_dev()
{
user=$1
proj=dev-$user 
echo "*** Testing development project $proj"
oc delete all --all -n $proj $OCOPTS
oc new-app monster -n $proj $OCOPTS

watch_pod monster-1-build $proj

echo "*** Waiting for $user build to complete"
oc logs -f builds/monster-1 -n $proj $OCOPTS 2>&1 logs/monster-build-$user.log

watch_pod monster-1-deploy $proj

}

function test_uat()
{
user=$1
proj=uat-$user

echo "*** Testing promotion in project $proj"
oc delete all --all -n $proj $OCOPTS
oc new-app monster-app -n $proj $OCOPTS

watch_pod monster-mysql-1-deploy $proj

echo "*** Tagging image"
oc tag monster:latest monster:uat -n dev-$user $OCOPTS
watch_pod monster-1-deploy $proj

}

function test_app()
{
user=$1
stage=$2

for attempt in $(seq 1 20); do
 ret=$(curl -Is http://monster-$stage-$user.apps.openshift.red | grep HTTP| awk '{print $2}')
 [[ $ret -eq 200 ]] && echo "*** $stage-$user SUCCESS" && break
 echo "*** $stage-$user attempt#$attempt"
 sleep 2
done


}

function test_user()
{
user=$1
load=$2
echo "**"
echo "*** TESTING USER $1"
test_dev $user

test_uat $user

test_app $user 'dev'
test_app $user 'uat'

  if [[ $load -eq 0 ]]; then
    oc delete all --all -n dev-$user $OCOPTS
    oc delete all --all -n uat-$user $OCOPTS
  fi
}

LOADTEST=$([[ "$@" == *"load"* ]] && echo "1")

mkdir logs
echo "*** Build logs written to ./logs directory"

if [[ $LOADTEST -eq 0 ]]; then echo "*** Sequential build test started: $(date)"
else echo "*** Load test started: $(date)"; fi


while IFS=, read user password name
do

test_user $user $LOADTEST &

done <users.csv

wait
if [[ $LOADTEST -eq 0 ]]; then echo "*** Sequential build completed : $(date)"
else

  while IFS=, read user password name
  do
    oc delete all --all -n dev-$user $OCOPTS
    oc delete all --all -n uat-$user $OCOPTS
  done

  echo "*** Load test completed: $(date)"

fi 
