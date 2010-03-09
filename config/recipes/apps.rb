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
      "bundle install"
      ].join(" && ")
  end
  
  task :initd_update do
    run [
      "sudo cp #{current_path}/config/server/services/bhelpers /etc/init.d/",
      "sudo cp #{current_path}/config/server/services/bolide /etc/init.d/",
      "sudo chmod +x /etc/init.d/bhelpers",
      "sudo chmod +x /etc/init.d/bolide",
      "sudo update-rc.d bhelpers defaults",
      "sudo update-rc.d bolide defaults"
      ].join(" && ")
  end
  
  task :restart do
    #to restart, send signal usr2
    run [
        "sudo /etc/init.d/bolide restart",
        "sudo /etc/init.d/bhelpers restart"
    ].join(" && ")
  end
  
  task :start do
    run [
        "sudo /etc/init.d/bolide start",
        "sudo /etc/init.d/bhelpers start"
    ].join(" && ")
  end
  
end