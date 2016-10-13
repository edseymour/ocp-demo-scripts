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


cp users.csv users.csv-bak
rm -f users.csv

for userid in $(seq 1 $NUM); do

   echo "demo$userid,$(mktemp -u XXXXXXXX)" >> users.csv

done

cat users.csv

while IFS=, read user password
do

echo "***********************************"
echo "** Creating the user login for $user"
ansible -i ansible-hosts masters -m "command" -a " htpasswd  -b  /etc/origin/master/htpasswd $user $password" -b

echo "**"
echo "**"
echo "** Creating default projects for $user"
oc adm new-project dev-$user --display-name="App Dev" --description="Application development project, where applications are coded and built" --admin=$user
oc adm new-project uat-$user --display-name="App Test" --description="Application testing project, where applications tested and approved" --admin=$user

sed 's/%GITURI%/http:\/\/gogs.apps.openshift.red\/'"$user"'\/monster.git/g'  monster-dev.yaml | sed 's/%MAVENURL%/'"$MAVENURL"'/g' | oc create -f -n dev-$user -
sed 's/%DEVNAMESPACE%/'"dev-$user"'/g' monster-prod.yaml | oc create -f -n uat-$user -

# allow uat project to pull images from dev project
oc policy add-role-to-user system:image-puller system:serviceaccounts:uat-$user -n dev-$user

done <users.csv
