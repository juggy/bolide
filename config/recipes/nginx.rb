namespace :deploy do
  
  after "deploy:start", "deploy:nginx_restart"
  after "deploy:restart", "deploy:nginx_restart"
  
  task :nginx_restart do
    run [
      "sudo cp #{current_path}/config/server/nginx/www.jguimont.com /etc/nginx/sites-enabled/www.jguimont.com",
      "sudo cp #{current_path}/config/server/nginx/live.jguimont.com /etc/nginx/sites-enabled/live.jguimont.com",
      "sudo /etc/init.d/nginx restart"
      ].join(" && ")
  end

end