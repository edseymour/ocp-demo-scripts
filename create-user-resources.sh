#!/bin/bash

#Gogs ref
#https://github.com/gogits/go-gogs-client/wiki/Repositories

#Creating a repo
#curl -v -u demo02:r3dh4t* -H "Content-Type: application/json" -X POST -d '{"name":"hello","description":"Some name","private":false}'  http://gogs.apps.openshift.red/api/v1/user/repos
#Create user
#{
#    "source_id": 1,
#    "login_name": "apiuser",
#    "username": "apiuser",
#    "email": "apiuser@user.com"
#}

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


USAGE="$0 <Gogs URL> <Gogs User> <Gogs Password>"
CLONE_URL=https://github.com/jim-minter/ose3-demos.git
DOWNLOAD_URL=https://github.com/jim-minter/ose3-demos/archive/master.zip

GOGSURL=$1
check_exists "provide a Gogs URL, $USAGE" $GOGSURL
GOGSUSER=$2
check_exists "provide a Gogs user, $USAGE" $GOGSUSER
GOGSPASS=$3
check_exists "provide a Gogs user password, $USAGE" $GOGSPASS

wget $DOWNLOAD_URL
unzip master.zip
git config credential.helper 'store'

while IFS=, read user password name
do

#USERADD='{ "source_id": 1, "login_name": "'$user'", "username": "'$user'", "email": "'$user'@openshift.red","password":"'$password'" }'
#REPOADD='{"name":"monster","description":"Ticket Monster for '$name'","private":false}'

## add the user
curl -v -u $GOGSUSER:$GOGSPASS -H "Content-Type: application/json" -X POST -d '{ "source_id": 1, "login_name": "'$user'", "username": "'$user'", "email": "'$user'@openshift.red","password":"'$password'" }' $GOGSURL/api/v1/admin/users

## create the repo
curl -v -u $user:$password -H "Content-Type: application/json" -X POST -d '{"name":"monster","description":"Ticket Monster for '$name'","private":false}' $GOGSURL/api/v1/user/repo

echo "http://$user:$password@gogs.apps.openshift.red" > $HOME/.git-credentials

pushd ose3-demos-master/git/monster/

git init
git add .
git commit -am "inital commit for $name"
git remote add origin $GOGSURL/$user/monster.git
git push -u origin master

# clean git init
rm -rf .git

popd


done <users.csv


