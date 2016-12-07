#!/bin/bash

function usage()
{
   echo "$0 prefix number guacadmin-password [home root path] [startnum] [vncserver hostname]
Use this script to create users on the localhost and automatically configure a vncserver service.
Expects JBoss Dev Studio binarys to be installed to /usr/share/users/devstudio/devstudio"

   exit 1
}


function check_error()
{
   [[ $? -ne 0 ]] && report_error $1
}


function report_error()
{
   echo "Problem $1"
   exit 1
}


DEVSTUDIO=/usr/share/users/devstudio/devstudio

PRE=$1
NUM=$2
GUAC_PASS=$3
HROOT=$4
STARTNUM=$5

SPATH=$(dirname $0)
GUAC_AUTOMATION=$SPATH/create-user-clients.py
HIP=$6 


[[ "$PRE" == "" ]] && usage
[[ "$NUM" == "" ]] && usage
[[ "$GUAC_PASS" == "" ]] && usage
[[ "$HROOT" == "" ]] && HROOT=/home
[[ "$STARTNUM" == "" ]] && STARTNUM=1
[[ "$HIP" == "" ]] && HIP=$(hostname -i)


[[ -e "users.csv" ]] && mv users.csv users.csv-$(date +%Y%m%d-%H%M%S)

for user in $(seq $STARTNUM $NUM) 
do

   username=demo$user
   password=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 8)

   echo "$username,$password,Demo User $userid" >> users.csv

   HDIR=$HROOT/$username
   useradd -b $HROOT $username
   chcon -R -t user_home_dir_t $HDIR
   passwd $username --stdin <<<$password


   ## create the VNC service for this user
   servicefile=/etc/systemd/system/vncserver-$username@.service
   sed 's/<USER>/'"$username"'/g'  /usr/lib/systemd/system/vncserver@.service > $servicefile
   sed -i 's|/home|'"$HROOT"'|g' $servicefile
   
   runuser -l $username -c "mkdir $HDIR/.vnc; echo $password | vncpasswd -f > $HDIR/.vnc/passwd"
   chmod 600 $HDIR/.vnc/passwd


   python $GUAC_AUTOMATION $GUAC_PASS $username $password $HIP $((5900 + $user)) 


done


systemctl daemon-reload


for user in $(seq 1 $NUM)
do


   username=demo$user
   systemctl start vncserver-$username@:$user.service
   systemctl enable vncserver-$username@:$user.service


done
