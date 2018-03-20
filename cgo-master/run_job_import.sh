#!/bin/bash   
# This script should be used by cron to upload jobs
# written by: federico kattan
# date: December 20, 2011

#cd /mnt/app/current
export RAILS_ENV=production


if [ -e ./tmp/pids/delayed_job.pid ]; then

	while [ `pgrep -f delayed_job` ]
	do
		ppid=`pgrep -f delayed_job`
		echo "Stopping delayed Job PID: ${ppid}"
		./script/delayed_job stop
		sleep 15
	done

	while [ -f ./tmp/pids/delayed_job.pid ]
	do 
		echo 'Stop requested, waiting for process to finish ...'
		sleep 2
	done
	sleep 30
	echo "Delayed Job Stopped"
fi

echo "Restarting delayed job"
./script/delayed_job start
sleep 60

echo "Starting Job Import"
rails runner "require 'jobs_import_job.rb'; Delayed::Job.enqueue JobsImportJob.new"
