upstream live_server {
	server unix:/u/apps/bolide/current/stream_app/tmp/sockets/live.sock;
}

server {
	listen   80;
	server_name  live.bolideapp.com;

	access_log  /u/apps/bolide/current/stream_app/log/nginx.live.access.log;
	error_log /u/apps/bolide/current/stream_app/log/nginx.live.error.log;
	
	keepalive_timeout 5;

	location / {
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header Host $http_host;
		proxy_redirect off;
		if (!-f $request_filename){
			proxy_pass http://live_server;
			break;
		}
	}
}
