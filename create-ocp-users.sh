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


USAGE="$0 <gogs-url> <nexus-url>"

GOGSURL=$1
check_exists "Gogs URL, $USAGE" $GOGSURL
MAVENURL=$2
check_exists "Maven repository URL, $USAGE" $MAVENURL

while IFS=, read user password name
do

echo "***********************************"
echo "** Creating the user login for $user"
ansible -i ansible-hosts masters -m "command" -a " htpasswd  -b  /etc/origin/master/htpasswd $user $password" -b

echo "**"
echo "**"
echo "** Creating default projects for $user"
oc adm new-project dev-$user --display-name="App Dev - $name" --description="Application development project, where applications are coded and built" --admin=$user
oc adm new-project uat-$user --display-name="App Test - $name" --description="Application testing project, where applications tested and approved" --admin=$user

sed 's|%GITURL%|'"$GOGSURL/$user"'/monster.git|g' monster-dev.yaml | sed 's|%MAVENURL%|'"$MAVENURL"'|g' | oc create -n dev-$user -f -
sed 's/%DEVNAMESPACE%/'"dev-$user"'/g' monster-prod.yaml | oc create -n uat-$user -f -

# allow uat project to pull images from dev project
oc policy add-role-to-group system:image-puller system:serviceaccounts:uat-$user -n dev-$user

done <users.csv
