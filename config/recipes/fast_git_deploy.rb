current_dir = File.expand_path(File.dirname(__FILE__))

load File.join(current_dir, "fast_git_deploy", "setup.rb")
load File.join(current_dir, "fast_git_deploy", "rollback.rb")

set :scm,            "git"
set :scm_command,    "git"
set(:revision_log)   { "#{deploy_to}/revisions.log" }
set(:version_file)   { "#{current_path}/REVISION" }
set :migrate_target, :current
set :release_name,   'current'
set :releases,       ['current']
set(:releases_path)  { File.join(deploy_to) }

namespace :deploy do
  desc <<-DESC
    Deploy a "cold" application (deploy the app for the first time).
  DESC
  task :cold do
    fast_git_setup.cold
  end

  desc <<-DESC
    Deploy a "warm" application - one which is already running, but was
    setup with deploy:cold provided by capistrano's default tasks
  DESC
  task :warm do
    fast_git_setup.warm
  end

  desc <<-DESC
    Deploy and run pending migrations. This will work similarly to the
    `deploy' task, but will also run any pending migrations (via the
    `deploy:migrate' task) prior to updating the symlink. Note that the
    update in this case it is not atomic, and transactions are not used,
    because migrations are not guaranteed to be reversible.
  DESC
  task :migrations do
    set :migrate_target, :current
    update_code
    symlink
    migrate
    restart
  end

  desc "Just like deploy:migrations, but puts up the maintenance page while migrating"
  task :long do
    set :migrate_target, :current
    deploy.web.disable
    update_code
    symlink
    migrate
    restart
    deploy.web.enable
  end

  desc "Updates code in the repos by fetching and resetting to the latest in the branch"
  task :update_code, :except => { :no_release => true } do
    run [
      "cd #{current_path}",
      "#{scm_command} fetch",
      "#{scm_command} reset --hard origin/#{branch}"
    ].join(" && ")

    finalize_update
  end

  desc <<-DESC
    [internal] Touches up the released code. This is called by update_code
    after the basic deploy finishes. It assumes a Rails project was deployed,
    so if you are deploying something else, you may want to override this
    task with your own environment's requirements.

    This will touch all assets in public/images,
    public/stylesheets, and public/javascripts so that the times are
    consistent (so that asset timestamping works).  This touch process
    is only carried out if the :normalize_asset_timestamps variable is
    set to true, which is the default.
  DESC
  task :finalize_update, :except => { :no_release => true } do
    
  end

  desc "Symlink system files & set revision info"
  task :symlink, :except => { :no_release => true } do
    symlink_system_files
    set_revisions
  end

  desc "Symlink system files"
  task :symlink_system_files, :except => { :no_release => true } do
    run [
      "rm -rf #{current_path}/feature_app/log #{current_path}/feature_app/public/system #{current_path}/feature_app/tmp/pids #{current_path}/feature_app/tmp/sockets #{current_path}/stream_app/tmp/sockets #{current_path}/stream_app/tmp/pids #{current_path}/stream_app/log #{current_path}/helpers/vhost/tmp/pids #{current_path}/helpers/log",
      "mkdir -p #{current_path}/feature_app/tmp",
      "mkdir -p #{current_path}/stream_app/tmp",
      "mkdir -p #{current_path}/helpers/tmp",
      "sudo mkdir -p #{shared_path}/sockets",
      
      "ln -s #{shared_path}/log    #{current_path}/feature_app/log",
      "ln -s #{shared_path}/system #{current_path}/feature_app/public/system",
      "ln -s #{shared_path}/pids   #{current_path}/feature_app/tmp/pids",
      "ln -s #{shared_path}/sockets   #{current_path}/feature_app/tmp/sockets",
      "ln -s #{shared_path}/log    #{current_path}/stream_app/log",
      "ln -s #{shared_path}/pids   #{current_path}/stream_app/tmp/pids",
      "ln -s #{shared_path}/sockets   #{current_path}/stream_app/tmp/sockets",
      "ln -s #{shared_path}/log    #{current_path}/helpers/log"
    ].join(" && ")
  end

  desc "Set the revisions file.  This allows us to go back to previous versions."
  task :set_revisions, :except => { :no_release => true } do
    set_version_file
    update_revisions_log
  end

  task :set_version_file, :except => { :no_release => true } do
    run [
      "cd #{current_path}",
      "#{scm_command} rev-list origin/#{branch} | head -n 1 > #{version_file}"
    ].join(" && ")
  end

  task :update_revisions_log, :except => { :no_release => true } do
    run "echo `date +\"%Y-%m-%d %H:%M:%S\"` $USER $(cat #{version_file}) >> #{deploy_to}/revisions.log"
  end

  desc "Run git gc"
  task :cleanup do
    run "cd #{current_path} && git gc"
  end

  desc <<-DESC
    Prepares one or more servers for deployment. Before you can use any \
    of the Capistrano deployment tasks with your project, you will need to \
    make sure all of your servers have been prepared with `cap deploy:setup'. When \
    you add a new server to your cluster, you can easily run the setup task \
    on just that server by specifying the HOSTS environment variable:

      $ cap HOSTS=new.server.com deploy:setup

    It is safe to run this task on servers that have already been set up; it \
    will not destroy any deployed revisions or data.
  DESC
  task :setup, :except => { :no_release => true } do
    dirs = [deploy_to, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
  end
end
