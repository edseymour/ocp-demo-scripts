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

function watch_deploy
{
pod=$1
count=0
while [[ $(oc get pod $pod --no-headers | grep Running | wc -l) -lt 1 ]]
do
   sleep 2
   counter=$((counter + 1))
   [[ $counter -gt 20 ]] && break
   echo "*** Waiting for deployer pod, attempt $counter"
done
oc logs -f $pod

}

function test_dev()
{
user=$1

oc project dev-$user

if [[ "dev-$user" == "$(oc project -q)" ]]
then

oc delete all --all
oc new-app monster

while [[ $(oc get builds --no-headers | wc -l) -lt 1 ]]
do
   sleep 1
done

oc logs -f builds/monster-1 > logs/monster-build-$user.log

watch_deploy monster-1-deploy

fi

}

function test_uat()
{
user=$1
oc project uat-$user
if [[ "uat-$user" == "$(oc project -q)" ]]
then

oc delete all --all
oc new-app monster-app

watch_deploy monster-mysql-1-deploy

oc tag monster:latest monster:uat -n dev-$user
sleep 3
watch_deploy monster-1-deploy

fi

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
test_dev $user

test_uat $user

test_app $user 'dev'
test_app $user 'uat'

  if [[ $load -eq 0 ]]; then
    oc delete all --all -n dev-$user
    oc delete all --all -n uat-$user
  fi
}

LOADTEST=$([[ "$@" == *"load"* ]] && echo "1")

mkdir logs
echo "*** Build logs written to ./logs directory"

if [[ $LOADTEST -eq 0 ]]; then echo "*** Sequential build test started: $(date)"
else echo "*** Load test started: $(date)"; fi

echo "*** Please login to OpenShift with a user with edit control over all target users"
oc login https://console.openshift.red

while IFS=, read user password name
do

test_user $user $LOADTEST &

done <users.csv

wait
if [[ $LOADTEST -eq 0 ]]; then echo "*** Sequential build completed : $(date)"
else

  while IFS=, read user password name
  do
    oc delete all --all -n dev-$user
    oc delete all --all -n uat-$user
  done

  echo "*** Load test completed: $(date)"

fi 
