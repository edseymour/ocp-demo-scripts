#!/bin/bash -e


function check_exists()
{
  [[ "$2" == "" ]] && echo "Missing $1" && exit 1
}

USAGE="$0 <OCP console URL>"
URL=$1
check_exists "OCP Console URL, $USAGE", $URL

if [[ ! -f users.csv ]];
then
   echo "No users.csv file. exiting and doing nothing"
   exit 1
fi

mkdir -p labels

echo '"URL","username","password"' >labels/data.csv

while IFS=, read username password user
do
  echo \"$URL\",\"$username\",\"$password\", >>labels/data.csv
done <users.csv

glabels-3-batch -i labels/data.csv labels.glabels -o labels/labels.pdf
