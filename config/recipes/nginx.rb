namespace :deploy do
  task :restart do
    run [
      "sudo cp #{current_path}/config/server/nginx/ws.jguimont.com /etc/nginx/sites-enabled/ws.jguimont.com",
      "sudo cp #{current_path}/config/server/nginx/live.jguimont.com /etc/nginx/sites-enabled/live.jguimont.com",
      "sudo /etc/init.d/nginx restart"
      ].join(" && ")
  end
end