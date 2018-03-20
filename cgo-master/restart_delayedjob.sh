#!/bin/bash
# written by: federico kattan
# date: March 20, 2013

export RAILS_ENV=production

cd /mnt/app/current

PIDS=`ps -ef| grep delayed_job| grep -v grep |awk '{print $2}'`

while [ -n "$PIDS" ]
do
   echo "Stopping delayed Job PID: ${PIDS}"
   kill -9 $PIDS
   echo 'Stop requested, waiting for process to finish ...'
done

echo "Restarting delayed job"
./script/delayed_job -n 2 start
