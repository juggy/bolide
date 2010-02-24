namespace :deploy do
  task :restart do
    run [
      "cp #{current_path}/server/nginx/ws.jguimont.com /etc/nginx/sites-enabled/ws.jguimont.com",
      "cp #{current_path}/server/nginx/live.jguimont.com /etc/nginx/sites-enabled/live.jguimont.com",
      "/etc/init.d/nginx restart"
      ].join(" && ")
  end
end