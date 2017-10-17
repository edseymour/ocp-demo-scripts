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
oc adm new-project dev-$user --display-name="1. JEE Dev - $name ($user)" --description="Example JEE application development project, where applications are coded and built" --admin=$user
oc adm new-project uat-$user --display-name="2. JEE Test - $name ($user)" --description="Example JEE application testing project, where applications tested and approved" --admin=$user
oc adm new-project prod-$user --display-name="3. JEE Prod - $name ($user)" --description="Example JEE application production project, where applications are hosted" --admin=$user

sed 's|%GITURL%|'"$GOGSURL/$user"'/monster.git|g' monster-dev.yaml | sed 's|%MAVENURL%|'"$MAVENURL"'|g' | oc create -n dev-$user -f -
sed 's|%GITURL%|'"$GOGSURL/$user"'/monster.git|g' monster-build.yaml | sed 's|%MAVENURL%|'"$MAVENURL"'|g' | oc create -n dev-$user -f -
sed 's/%DEVNAMESPACE%/'"dev-$user"'/g' monster-test.yaml | oc create -n uat-$user -f -
sed 's/%DEVNAMESPACE%/'"dev-$user"'/g' monster-prod.yaml | oc create -n prod-$user -f -
sed 's/%APP/monster/g' pipeline-template.yaml | sed 's/%DEV_PROJ/dev-'"$user"'/g' | sed 's/%TEST_PROJ/uat-'"$user"'/g' | sed 's/%PROD_PROJ/prod-'"$user"'/g' | oc create -n dev-$user -f -
sed 's/%APP/monster/g' pipeline-seed.yaml | sed 's/%DEV_PROJ/dev-'"$user"'/g' | sed 's/%TEST_PROJ/uat-'"$user"'/g' | sed 's/%PROD_PROJ/prod-'"$user"'/g' | oc process -f - | oc create -n dev-$user -f -

# allow uat project to pull images from dev project
oc policy add-role-to-group system:image-puller system:serviceaccounts:uat-$user -n dev-$user
oc policy add-role-to-group system:image-puller system:serviceaccounts:prod-$user -n dev-$user
# allow jenkins running in dev project to edit uat and prod
oc policy add-role-to-user edit system:serviceaccount:dev-$user:jenkins -n uat-$user
oc policy add-role-to-user edit system:serviceaccount:dev-$user:jenkins -n prod-$user


done <users.csv
