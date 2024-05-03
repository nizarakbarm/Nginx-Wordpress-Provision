#!/bin/bash

#Overwrite nginx conf with secured nginx conf based on CIS Benchmark Nginx
cat <<EOF >/etc/nginx/nginx.conf
# load modules
load_module modules/ngx_http_cache_purge_module.so;

user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status $body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;
    
    #CIS Benchmark Nginx: 2.4.3
    keepalive_timeout  10;
    #CIS Benchmark Nginx: 2.4.4
    send_timeout 10;
    #CIS Benchmark Nginx: 5.2.1
    client_body_timeout 12;
    client_header_timeout 12;
    #CIS Benchmark Nginx: 5.2.2
    # Set large to accomodate wordpress upload
    client_max_body_size 128m;
    # CIS Benchmark Nginx: 5.2.3
    large_client_header_buffers 4 4k;

    gzip  on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;
    gzip_min_length 10240;
    gzip_comp_level 5;
    gzip_proxied any;

    #CIS Benchmark Nginx: 2.5.1
    server_tokens off;

    #enable http3
    http3 on;
    http3_hq on;
    quic_retry on;
    #include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*.conf;
}
EOF
