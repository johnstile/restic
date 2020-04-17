#!/bin/bash
#
# Title:    restic_run.bash
# Date:     20200417
# Purpouse: Perform all restic backup functions 
#
DATE="$(date +%Y%m%d-%H%M%S)"
DEBUG=0
#######################################################################
#
# Usage message
#
export Usage="USAGE: $0 -a [init|backup|check|forget|ls]
-a <action>   : Action to perform 
Actions:
 init   :Initialize bucket
 backup :Perform backup 
 check  :Check
 list   :List
"
#######################################################################
while getopts ":a:d:h" opt
do
    case $opt in
    a) export ACTION="$OPTARG"
       ;;
    d) export DEBUG="1"
       ;;
    *) echo -e "HELP: How to run this script"
       echo "$Usage"
       exit
       ;;
   esac
done
if [ -z $ACTION ]; then
  echo "$Usage"
  exit
fi

#set -e -o pipefail
#set -e

#
# Ensure no other backup is running
#
if pidof -o %PPID -x "restic">/dev/null; then
  echo "Error: Restic Already running!"
  exit 1
fi



#######################################################################
#
# Get this directory
#
SOURCE="${BASH_SOURCE[0]}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#
# Holds keys, passwd, bucket name
#
RESTIC_ENV="${SCRIPT_DIR}/.resticrc"
#
# Holds paths to include and exclude
#
RESTIC_EXCLUDES="${SCRIPT_DIR}/.excludes"
RESTIC_INCLUDES="${SCRIPT_DIR}/.includes"
#
# How many connections to B2, default is 5
#
B2_CONNECTIONS=50
#
# Taging each backup
#
RESTIC_TAG="cron.timer"   #$(date +%Y%m%d.%H%M%S)"
#
# How long to keep
#
RETENTION_DAYS=7
RETENTION_WEEKS=4
RETENTION_MONTHS=6
RETENTION_YEARS=3


echo "VARS:
---------------------------------
DATE=$DATE
ACTION=$ACTION
DEBUG=$DEBUG
SOURCE=$SOURCE
SCRIPT_DIR=$SCRIPT_DIR
RESTIC_ENV=$RESTIC_ENV
RESTIC_EXCLUDES=$RESTIC_EXCLUDES
RESTIC_INCLUDES=$RESTIC_INCLUDES
B2_CONNECTIONS=$B2_CONNECTIONS
RESTIC_TAG=$RESTIC_TAG
---------------------------------
"
#
# Load keys, password, and bucket name
#
if [ -f "$RESTIC_ENV" ]; then
  source "$RESTIC_ENV"
fi
#
# Test for required variables
#
if [ -z $B2_ACCOUNT_ID ]; then
  echo "Error: Did not findB2_ACCOUNT_ID in $RESTIC_ENV"
  exit 1
fi
if [ -z $B2_ACCOUNT_KEY ]; then
  echo "Error: Did not find B2_ACCOUNT_KEY in $RESTIC_ENV"
  exit 1
fi
if [ -z $RESTIC_PASSWORD  ]; then
  echo "Error: Did not find RESTIC_PASSWORD in $RESTIC_ENV"
  exit 1
fi
if [ -z $RESTIC_REPOSITORY ]; then
  echo "Error: Did not find RESTIC_REPOSITORY in $RESTIC_ENV"
  exit 1
fi
#######################################################################
#
# First backup needs this 
# 
if [ $ACTION == "init" ]; then
  restic -r "b2:mother-restic-backup" init

elif [ $ACTION == "backup" ]; then
  echo "Run unlock"
  restic unlock &
  wait $!

  echo "Run Backup"
  restic backup \
   --verbose \
   --one-file-system \
   --tag $BACKUP_TAG \
   --option b2.connections=$B2_CONNECTIONS \
   --exclude-file $RESTIC_EXCLUDES \
   --files-from $RESTIC_INCLUDES &
  wait $!

  # See restic-forget(1) or http://restic.readthedocs.io/en/latest/060_forget.html
  echo "Run Forget and Prune"
  restic forget \
    --tag $BACKUP_TAG \
    --option b2.connections=$B2_CONNECTIONS \
    --prune \
    --group-by "paths,tags" \
    --keep-daily $RETENTION_DAYS \
    --keep-weekly $RETENTION_WEEKS \
    --keep-monthly $RETENTION_MONTHS \
    --keep-yearly $RETENTION_YEARS &
  wait $!

  echo "Run Check"
  restic check &
  wait $!
    

elif [ $ACTION == "check" ]; then
  restic check &
  wait $!

elif [ $ACTION == "list" ]; then
  #usage: list blobs|packs|index|snapshots|keys|locks]
  #echo "blobs"
  #TOO BEAUCOUP: restic list blobs
  #echo "packs"
  #TOO TOO BEAUCOUP: restic list packs
  echo "index"
  restic list index
  echo "snapshots"
  restic list snapshots
  echo "keys"
  restic list keys
  echo "locks"
  restic list locks
else
  echo "Unknown ACTION: $ACTION"
fi
