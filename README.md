# ocp-demo-scripts

## Prerequisites

1. Create Gogs service (must be Gogs, script relies on Gogs' API). Recommend https://github.com/OpenShiftDemos/gogs-openshift-docker
2. Create Nexus service, or other suitable maven mirror. Recommend https://github.com/OpenShiftDemos/nexus (consider ephemeral, i.e. not persistent, versions if persistent disks have slow IO). 

## Usage

1. (optional) create-users.sh - generate a list of demo users, outputs to users.csv
2. create-user-resources.sh - populate Gogs with above users and create a Ticket Monster repository
3. create-user-projects.sh - create OpenShift projects for Ticket Monster, and populate with templates with user-context defaults
4. (optional) prebuild-and-promote.sh - will build in dev, and promote to test & prod, then delete all in dev for fresh start


