namespace :deploy do
  
  after "deploy:update", "deploy:bundle_update"
  
  task :bundle_update do
    run [
      "cd #{current_path}/ws_app",
      "sudo bundle lock",
      "sudo bundle install",
      "cd #{current_path}/stream_app",
      "sudo bundle lock",
      "sudo bundle install"
      ].join(" && ")
  end
  
  task :restart do
    #to restart, send signal usr2
    run [
        "kill -USR2 `cat #{shared_path}/pids/live.unicorn.pid`",
        "kill -USR2 `cat #{shared_path}/pids/unicorn.pid`" 
    ].join(" && ")
  end
  
  task :start do
    run [
         "cd #{current_path}/stream_app",
        "sudo rainbows -c #{current_path}/config/server/app/live.jguimont.com.rb -E production -D",
        "cd #{current_path}/ws_app",
        "sudo unicorn_rails -c #{current_path}/config/server/app/ws.jguimont.com.rb -E production -D"
    ].join(" && ")
  end
  
end