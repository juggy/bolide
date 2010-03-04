namespace :deploy do
  
  after "deploy:update", "deploy:bundle_update"
  
  task :bundle_update do
    run [
      "cd #{current_path}/feature_app",
      "sudo bundle install",
      "cd #{current_path}/stream_app",
      "sudo bundle install",
      "cd #{current_path}/helpers/vhost",
      "sudo bundle install"
      ].join(" && ")
  end
  
  task :restart do
    #to restart, send signal usr2
    run [
        "sudo kill -USR2 `cat #{shared_path}/pids/live.unicorn.pid`",
        "sudo kill -USR2 `cat #{shared_path}/pids/unicorn.pid`",
        "cd #{current_path}/helpers/vhost",
        "sudo ruby vhost.rb restart"
    ].join(" && ")
  end
  
  task :start do
    run [
         "cd #{current_path}/stream_app",
        "sudo rainbows -c #{current_path}/config/server/app/live.bolideapp.com.rb -E production -D",
        "cd #{current_path}/feature_app",
        "sudo unicorn_rails -c #{current_path}/config/server/app/www.bolideapp.com.rb -E production -D",
        "cd #{current_path}/helpers/vhost",
        "sudo ruby vhost.rb start "
    ].join(" && ")
  end
  
end