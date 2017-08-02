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

echo "**"
echo "**"
echo "** Creating default projects for $user"
oc adm new-project dev-$user --display-name="App Dev - $name ($user)" --description="Application development project, where applications are coded and built" --admin=$user
oc adm new-project uat-$user --display-name="App Test - $name ($user)" --description="Application testing project, where applications tested and approved" --admin=$user
oc adm new-project prod-$user --display-name="App Prod - $name ($user)" --description="Application production project, where applications are hosted" --admin=$user

sed 's|%GITURL%|'"$GOGSURL/$user"'/monster.git|g' monster-dev.yaml | sed 's|%MAVENURL%|'"$MAVENURL"'|g' | oc create -n dev-$user -f -
sed 's/%DEVNAMESPACE%/'"dev-$user"'/g' monster-test.yaml | oc create -n uat-$user -f -
sed 's/%DEVNAMESPACE%/'"dev-$user"'/g' monster-prod.yaml | oc create -n prod-$user -f -
sed 's/%APP/monster/g' pipeline-template.yaml | sed 's/%DEV_PROJ/dev-'"$user"'/g' | sed 's/%TEST_PROJ/uat-'"$user"'/g' | sed 's/%PROD_PROJ/prod-'"$user"'/g' | oc create -n dev-$user -f -

# allow uat project to pull images from dev project
oc policy add-role-to-group system:image-puller system:serviceaccounts:uat-$user -n dev-$user
oc policy add-role-to-group system:image-puller system:serviceaccounts:prod-$user -n dev-$user
# allow jenkins running in dev project to edit uat and prod
oc policy add-role-to-user edit system:serviceaccount:dev-$user:jenkins -n uat-$user
oc policy add-role-to-user edit system:serviceaccount:dev-$user:jenkins -n prod-$user


done <users.csv
