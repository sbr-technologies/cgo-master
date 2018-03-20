namespace :deploy do 
  task :start, :roles => :app do 
    puts "restarting passenger!" 
    run "touch #{current_path}/tmp/restart.txt" 
    # run "sleep 30" # give the service 30 seconds to start before attempting to monitor it 
    # sudo "monit -g app monitor all" 
  end 

  task :stop, :roles => :app do 
    puts "stopping passenger!" 
    # sudo "monit -g app unmonitor all" 
  end 

  desc "removes .htaccess" 
  task :remove_htaccess, :roles => :app do 
    run "rm -rf #{current_path}/public/.htaccess" 
  end 
end 
