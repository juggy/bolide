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
      "sudo cp #{current_path}/config/server/services/bhost /etc/init.d/",
      "sudo cp #{current_path}/config/server/services/bstat /etc/init.d/",
      "sudo cp #{current_path}/config/server/services/bstream /etc/init.d/",
      "sudo cp #{current_path}/config/server/services/bfeature /etc/init.d/",
      "sudo chmod +x /etc/init.d/bhost",
      "sudo chmod +x /etc/init.d/bstat",
      "sudo chmod +x /etc/init.d/bstream",
      "sudo chmod +x /etc/init.d/bfeature",
      "sudo update-rc.d bhost start 51 S .",
      "sudo update-rc.d bstat start 51 S .",
      "sudo update-rc.d bstream start 51 S .",
      "sudo update-rc.d bfeature start 51 S ."
      ].join(" && ")
  end
  
  task :restart do
    #to restart, send signal usr2
    run [
        "sudo /etc/init.d/bhost restart",
        "sudo /etc/init.d/bstat restart",
        "sudo /etc/init.d/bstream restart",
        "sudo /etc/init.d/bfeature restart"
    ].join(" && ")
  end
  
  task :start do
    run [
        "sudo /etc/init.d/bhost start",
        "sudo /etc/init.d/bstat start",
        "sudo /etc/init.d/bstream start",
        "sudo /etc/init.d/bfeature start"
    ].join(" && ")
  end
  
end