upstream ws_server {
	server unix:/u/apps/bolide/current/ws_app/tmp/sockets/ws.sock fail_timeout=0;
}

server {
	listen   80;
	server_name  ws.jguimont.com;

	access_log  /u/apps/bolide/current/ws_app/log/nginx.ws.access.log;
	error_log /u/apps/bolide/current/ws_app/log/nginx.ws.error.log;

	keepalive_timeout 5;

	location / {
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header Host $http_host;
		proxy_redirect off;
		if (!-f $request_filename){
			proxy_pass http://ws_server;
			break;
		}
	}
}
