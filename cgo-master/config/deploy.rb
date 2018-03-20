#$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                  # Load RVM's capistrano plugin.
set :rvm_ruby_string, '1.8.7@cgray'       # Or whatever env you want it to run in.
set :rvm_type, :system                    # Use system wide RVM on server.

require "bundler/capistrano"

# This is a sample Capistrano config file for EC2 on Rails.

set :application, 'cgonrails'
set :deploy_to, '/mnt/app'
set :repository, '.'
set :rails_env, "production"

# Git Setup
set :scm, "git"
set :branch, "master"
set :repository,  "git@github.com:fkattan/cgo.git"

set :user, "app"
set :use_sudo, false
ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa")]
default_run_options[:pty] = true

server 'maverick.corporategray.com', :web, :app, :db, :primary => true

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

after :setup, :roles => [:web] do
  run "mkdir #{shared_path}/tmp"
  run "mkdir #{shared_path}/data"
  run "mkdir #{shared_path}/data/paperclip"
end

after 'deploy:update_code', :roles => [:app] do
  run "ln -s /mnt/public/xml #{latest_release}/public/xml"
  run "ln -s /mnt/public/cgo #{latest_release}/public/cgo"
  #run "ln -s /mnt/app/config/backgroundrb.yml #{latest_release}/config/backgroundrb.yml"
  run "ln -nfs #{shared_path}/data/paperclip #{release_path}/paperclip"

  #run "ln -sf /mnt/incoming/CGnewsletter.pdf #{latest_release}/public/CGnewsletter.pdf"
  run "ln -sf /mnt/incoming/CGnewsletter.html #{latest_release}/public/CGnewsletter.html"
end


namespace :passenger do
  desc "Restart Passenger"
  task :restart, :roles => :app do
    run "touch #{latest_release}/tmp/restart.txt"
  end

  desc "Stop Passenger"
  task :stop, :roles => :app do
    run "touch /tmp/stop.txt"
  end

  desc "Start (or un-stop) Passenger"
  task :start, :roles => :app do
    run "rm -f /tmp/stop.txt"
  end
end


# this is depecated, see above passenger:[restart, start, stop]
# namespace :maintenance do
#   desc "Up maintenance page and disable website"
#   task :up, :roles => :app do
#     run "cp #{latest_release}/public/maintenance.html #{shared_path}/system"
#   end
# 
#   desc "Down maintenance page and enable website"
#   task :down, :roles => :app do
#     run "rm -f #{shared_path}/system/maintenance.html"
#   end
# end


#before "deploy:stop", "maintenance:up"
#before "deploy:restart", "maintenance:up"
#after  "deploy:start", "maintenance:down"
#after  "deploy:restart", "maintenance:down"


# namespace :backgroundrb do
#   desc "Start backgrounDRb"
#   task :start, :roles => :app do
#     run "cd #{latest_release}; ./script/backgroundrb start RAILS_ENV=production"
#   end
#   
#   desc "Stop backgrounDRb"
#   task :stop, :roles => :app do
#     run "cd #{latest_release}; ./script/backgroundrb stop RAILS_ENV=production"
#   end
# end

# after "deploy:start", "backgroundrb:start"
# after "deploy:stop", "backgroundrb:stop"


# add this to config/deploy.rb
namespace :delayed_job do
  desc "Start delayed_job process" 
  task :start, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job start " 
  end

  desc "Stop delayed_job process" 
  task :stop, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job stop " 
  end

  desc "Restart delayed_job process" 
  task :restart, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job stop " 
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job start " 
  end
end

#after "deploy:start", "delayed_job:start" 
#after "deploy:stop", "delayed_job:stop" 
#after "deploy:restart", "delayed_job:restart" 
