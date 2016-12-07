#!/bin/bash


# The purpose of this script to to create resources for use with an OCP cluster, that does not require a desktop server. 
# It is expected when used, OCP users will bring their own devices. 
 
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

while IFS=, read user password name
do

## add the user
curl -v -u $GOGSUSER:$GOGSPASS -H "Content-Type: application/json" -X POST -d '{ "username": "'"$user"'", "email": "'"$user"'@openshift.red","password":"'"$password"'" }' $GOGSURL/api/v1/admin/users

## create the repo
curl -v -u $user:$password -H "Content-Type: application/json" -X POST -d '{"name":"monster","description":"Ticket Monster for '"$name"'","private":false}' $GOGSURL/api/v1/user/repos

pushd ose3-demos-master/git/monster/

git init
git add .

git config --global user.name "$name"
git config --global user.email "$user@openshift.red"
git config credential.helper 'store --file .git/credentials'
echo "http://$user:$password@gogs.apps.openshift.red" > .git/credentials
chmod 600 .git/credentials

git commit -am "inital commit for $name"
git remote add origin $GOGSURL/$user/monster.git
git push -u origin master

# clean git init
rm -rf .git

popd


done <users.csv


