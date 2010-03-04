upstream www_server {
	server unix:/u/apps/bolide/current/feature_app/tmp/sockets/www.sock;
}
server {
	listen   80;
	server_name  jguimont.com;
	rewrite ^/(.*) http://www.jguimont.com/$1 permanent;
}

server {
	listen   80;
	server_name  www.jguimont.com;

	access_log  /u/apps/bolide/current/feature_app/log/nginx.www.access.log;
	error_log /u/apps/bolide/current/feature_app/log/nginx.www.error.log;

	keepalive_timeout 5;
	
	# doc root
	root /u/apps/bolide/current/feature_app/public;

	location / {
		
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header Host $http_host;
		proxy_redirect off;
		
		if (-f $request_filename) {
			break;
		}
		
		if (!-f $request_filename){
			proxy_pass http://www_server;
			break;
		}
	}
}
