#!/bin/bash

#      ref: master
#      uri: https://github.com/jim-minter/ose3-demos.git

function check_exists
{
  [[ "$2" == "" ]] && echo "Missing $1" && exit 1
}

function default_if_empty
{
  [[ "$2" == "" ]] && echo "Missing $1" && exit 1
}


USAGE="$0 <home-dir> <Gogs URL> <Gogs User> <Gogs Password>"

HOMED=$1
check_exists "provide a base home directory, $USAGE" $HOMED
GOGSURL=$2
check_exists "provide a Gogs URL, $USAGE" $GOGSURL
GOGSHOST=$(echo $GOGSURL | awk -F/ '{print $3}')
GOGSSCHEME=$(echo $GOGSURL | awk -F/ '{print $1}')
echo "Using $GOGSSCHEME//$GOGSHOST as the Gogs base URL"
GOGSUSER=$3
check_exists "provide a Gogs user, $USAGE" $GOGSUSER
GOGSPASS=$4
check_exists "provide a Gogs user password, $USAGE" $GOGSPASS

while IFS=, read user password name
do

## add the user
curl -v -u $GOGSUSER:$GOGSPASS -H "Content-Type: application/json" -X POST -d '{ "username": "'"$user"'", "email": "'"$user"'@openshift.red","password":"'"$password"'" }' $GOGSURL/api/v1/admin/users

## create the repo
curl -v -u $user:$password -H "Content-Type: application/json" -X POST -d '{"name":"monster","description":"Ticket Monster for '"$name"'","private":false}' $GOGSURL/api/v1/user/repos

USERHOME=$HOMED/$user

runuser -l $user -c "pushd $USERHOME/code/monster
git init
git add .
git config --global user.name \"$name\"
git config --global user.email \"$user@openshift.red\"
git config credential.helper 'store --file .git/credentials'
echo \"$GOGSSCHEME//$user:$password@$GOGSHOST\" > .git/credentials
chmod 600 .git/credentials

git commit -am \"inital commit for $name\"
git remote add origin $GOGSURL/$user/monster.git
git push -u origin master

popd"


done <users.csv


