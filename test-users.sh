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
while [[ $(oc get pod $pod | grep Running | wc -l) -lt 1 ]]
do
   sleep 1
   counter=$((counter + 1))
   [[ $counter -gt 10 ]] && break
done
oc logs -f $pod

}

while IFS=, read user password name
do

oc project dev-$user

if [[ "dev-$user" == "$(oc project -q)" ]]
then

oc delete all --all
oc new-app monster

while [[ $(oc get builds --no-headers | wc -l) -lt 1 ]]
do
   sleep 1
done

oc logs -f builds/monster-1

watch_deploy monster-1-deploy

fi

oc project uat-$user
if [[ "uat-$user" == "$(oc project -q)" ]]
then

oc delete all --all 
oc new-app monster-app

watch_deploy monster-mysql-1-deploy

oc tag monster:latest monster:uat -n dev-$user

watch_deploy monster-1-deploy

fi

for attempt in $(seq 1 20); do
 ret=$(curl -Is http://monster-dev-$user.apps.openshift.red | grep HTTP| awk '{print $2}')
 [[ $ret -eq 200 ]] && echo "*** dev-$user SUCCESS" && break
 echo "*** dev-$user attempt#$attempt"
 sleep 2
done

for attempt in $(seq 1 20); do
 ret=$(curl -Is http://monster-uat-$user.apps.openshift.red | grep HTTP| awk '{print $2}')
 [[ $ret -eq 200 ]] && echo "*** uat-$user SUCCESS" && break
 echo "*** uat-$user attempt#$attempt"
 sleep 2
done

oc delete all --all -n dev-$user
oc delete all --all -n uat-$user


done <users.csv
