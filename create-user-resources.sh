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


USAGE="$0 <number of users>"
CLONE_URL=https://github.com/jim-minter/ose3-demos.git
DOWNLOAD_URL=https://github.com/jim-minter/ose3-demos/archive/master.zip

NUM=$1
check_exists "number of users to create, $USAGE" $NUM

GOGS_URL=$1

