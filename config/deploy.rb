require "bundler/capistrano" #Running cap deploy or cap deploy:update will now automatically run bundle install on the remote server with deployment-friendly options.
require 'sidekiq/capistrano'

set :application, ENV!['APP_NAME']
set :server_name, "54.84.189.237"

role :web, server_name # Your HTTP server, Apache/etc
role :app, server_name # This may be the same as your `Web` server
role :db, server_name, :primary => true # This is where Rails migrations will run

set :user, 'mutalis'
set :deploy_to, "/home/#{user}/#{application}"
set :deploy_via, :copy
# set :deploy_via, :remote_cache
set :use_sudo, false
default_run_options[:pty] = true
ssh_options[:forward_agent] = true

set :scm, 'git'
set :repository, ENV!['GIT_URL']
set :branch, "master"
# As an alternative to the remote cache approach, Shallow cloning will do a clone
# each time, but will only get the top commit, not the entire repository history.
# Be warned, shallow clone won't work well with the set :branch option.
# set :git_shallow_clone, 0
set :git_enable_submodules, 1
set :keep_releases, 2

# Passenger mod_rails:
namespace :deploy do
  desc "Passenger module, it does nothing."
  task :start do ; end
  desc "Passenger module, it does nothing."
  task :stop do ; end
  desc "Restart Application"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
