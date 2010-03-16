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
      "sudo cp #{current_path}/config/server/services/god /etc/init.d/",
      "sudo chmod +x /etc/init.d/bhost",
      "sudo chmod +x /etc/init.d/bstat",
      "sudo chmod +x /etc/init.d/bstream",
      "sudo chmod +x /etc/init.d/bfeature",
      "sudo chmod +x /etc/init.d/god",
      "sudo update-rc.d -f god defaults 99",
      "sudo sh -c \"echo 'GOD_CONFIG=#{current_path}/config/god.rb' > /etc/default/god\""
      
      ].join(" && ")
  end
  
  task :restart do
    #to restart, send signal usr2
    run [
        'sudo god restart bdaemons'
        'rm #{current_path}/feature_app/public/javascripts/cache/cache.js',
        'rm #{current_path}/feature_app/public/stylesheets/cache/cache.css'
    ].join(" && ")
  end
  
  task :start do
    run [
        'sudo god start bdaemons',
        'rm #{current_path}/feature_app/public/javascripts/cache/cache.js',
        'rm #{current_path}/feature_app/public/stylesheets/cache/cache.css'
    ].join(" && ")
  end
  
end