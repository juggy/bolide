namespace :deploy do
  
  after "deploy:update", "deploy:bundle_update"
  after "deploy:update", "deploy:initd_update"
  
  task :bundle_update do
    run [
      "cd #{current_path}/feature_app",
      "bundle install",
      "cd #{current_path}/stream_app",
      "bundle install",
      "cd #{current_path}/helpers",
      "bundle install",
      "sudo chown -R www-data #{shared_path}/log",
      "sudo chown -R www-data #{shared_path}/pids",
      ].join(" && ")
  end
  
  task :initd_update do
    run [
      "sudo cp #{current_path}/config/server/services/bhost /etc/init.d/",
      "sudo cp #{current_path}/config/server/services/bstat /etc/init.d/",
      "sudo cp #{current_path}/config/server/services/bstream /etc/init.d/",
      "sudo cp #{current_path}/config/server/services/bfeature /etc/init.d/",
      "sudo chmod +x /etc/init.d/bhost",
      "sudo chmod +x /etc/init.d/bstat",
      "sudo chmod +x /etc/init.d/bstream",
      "sudo chmod +x /etc/init.d/bfeature"
      # "sudo update-rc.d -f bhost defaults 99",
      #       "sudo update-rc.d -f bstat defaults 99",
      #       "sudo update-rc.d -f bstream defaults 99",
      #       "sudo update-rc.d -f bfeature defaults 99"
      ].join(" && ")
  end
  
  task :restart do
    #to restart, send signal usr2
    run [
        'sudo god restart bdaemons'
        # "sudo /etc/init.d/bhost restart",
        #         "sudo /etc/init.d/bstat restart",
        #         "sudo /etc/init.d/bstream restart",
        #         "sudo /etc/init.d/bfeature restart"
    ].join(" && ")
  end
  
  task :start do
    run [
        'sudo god start bdaemons'
        # "sudo /etc/init.d/bhost start",
        #         "sudo /etc/init.d/bstat start",
        #         "sudo /etc/init.d/bstream start",
        #         "sudo /etc/init.d/bfeature start"
    ].join(" && ")
  end
  
end