#!/bin/bash

#set -x

print_help() {
    echo ""
    echo "Setup WP"
    echo "Usage: $PROGNAME [-d|--domain-name <domain-name>] [-e|--email <email>]"
    echo ""
}
while test -n "$1"; do
    case "$1" in
        --help)
            print_help
            exit 0
            ;;
        -h)
            print_help
            exit 0
            ;;
        --domain-name)
            DOMAIN_NAME=$2
            shift
            ;;
        -d)
            DOMAIN_NAME=$2
            shift
            ;;
		--email)
			EMAIL=$2
			shift
			;;
		-e)
			EMAIL=$2
			shift
			;;
        *)
            echo "Unknown argument: $1"
            print_help
            exit 1
            ;;
    esac
    shift
done

if [ -z "$DOMAIN_NAME" ]; then
    echo "Warning: DOMAIN_NAME is not defined!"
    exit 1
fi


DOC_ROOT="/usr/share/nginx/$DOMAIN_NAME"
#create document root directory for vhost
if [ ! -d "$DOC_ROOT" ]; then
    mkdir "$DOC_ROOT"
fi

# setup wp secure for nginx
wp --path="$DOC_ROOT" secure block-access all --server=nginx --file-path=/etc/nginx/wp-secure.conf --allow-root
#wp --path="$DOC_ROOT" secure block-author-scanning --server=nginx --file-path=/etc/nginx/wp-secure.conf --allow-root
wp --path="$DOC_ROOT" secure block-php-execution all --server=nginx --file-path=/etc/nginx/wp-secure.conf --allow-root
#wp --path="$DOC_ROOT" secure disable-directory-browsing --server=nginx --file-path=/etc/nginx/wp-secure.conf --allow-root
chown root:root /etc/nginx/wp-secure.conf && chmod 644 /etc/nginx/wp-secure.conf

#create vhost conf with the specified domain in  sites-available before install ssl

poolname=$(echo "$DOMAIN_NAME" | cut -d"." -f1)

cat <<EOF>/etc/nginx/sites-available/"$DOMAIN_NAME.conf"
include /etc/nginx/define_fastcgi_cache.conf;
include /etc/nginx/map_webp.conf;
server {
	listen 80;
	#listen 443 ssl;
    #http2 on;


	server_name $DOMAIN_NAME;
	#include /etc/nginx/ssl_secure.conf;
	#ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
	#ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
	access_log /var/log/nginx/$DOMAIN_NAME.access.log;
	error_log /var/log/nginx/$DOMAIN_NAME.error.log;

	root /usr/share/nginx/$DOMAIN_NAME;
	index index.html index.htm index.php;
	include /etc/nginx/fastcgi_cache_rules.conf;
	include /etc/nginx/security_header.conf;
	location / {
		try_files \$uri \$uri/ /index.php\$args;  
		# disable directory indexing
		autoindex off;
		# block author scanning
		if (\$query_string ~ "author=\d+"){
        	return 403;
    	}
	}

	location ~ \.php\$ {
		try_files \$uri =404;

		include fastcgi_params;
		
		fastcgi_split_path_info ^(.+\\\\.php)(/.+)\$;
		fastcgi_pass unix:/var/run/php8.1-fpm-$poolname.sock;
		fastcgi_param SCRIPT_FILENAME \$document_root/\$fastcgi_script_name;
		#fastcgi_index index.php;
		fastcgi_cache_bypass \$skip_cache;
		fastcgi_no_cache \$skip_cache;
		fastcgi_cache WORDPRESS;
		fastcgi_cache_valid 60m;
		add_header X-Cache \$upstream_cache_status;
	
	}
	location ~ /purge(/.*) {
		fastcgi_cache_purge WORDPRESS "\$scheme\$request_method\$host\$1";
	}
    # WebP
	location ~* ^/.+\.(png|gif|jpe?g)\$ {
		#expires max;
		add_header Cache-Control "max-age=604800, must-revalidate";
		try_files \$uri\$webp_suffix \$uri =404;
		#add_header Alt-Svc 'h3=":443"; ma=86400';
	}

	location ~* (ogg|ogv|svg|svgz|eot|otf|woff|webp|mp4|ttf|css|rss|atom|js|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bpm|rtf)\$ {
		#expires max;
		add_header Cache-Control "max-age=604800, must-revalidate";

		#add_header Alt-Svc 'h3=":443"; ma=86400';
		log_not_found off;
		access_log off;
	}
	location = /robots.txt {

		access_log off;
		log_not_found off;
	}
	location ~ /\.well-known\/acme-challenge {
		allow all;
	}

    #include configuration of wp secure
    include /etc/nginx/wp-secure.conf;

	#CIS Benchmark Nginx: 2.5.4
	location ~ /\. {
		deny all;
		return 404;
	}
}
EOF

nginx_test=$(nginx -t 2>&1)
if [[ $nginx_test =~ ok || $nginx_test =~ successful ]]; then
    echo "Info: The configuration is ok and Nginx test successful"
    # After know that test successfull, activate vhost
    [ ! -f "/etc/nginx/sites-available/$DOMAIN_NAME" ] && ln -s /etc/nginx/sites-available/$DOMAIN_NAME.conf /etc/nginx/sites-enabled
	sleep 3
	/usr/bin/systemctl start nginx
	sleep 3
else
    echo "Error: configuration error and nginx test is not successful! Check configuration again"
    exit 1
fi

if [ -z "$(s3cmd -c ~/.s3cfg_certificate_object ls s3://certbucket/$DOMAIN_NAME/fullchain.pem)" ] && [ -z  "$(s3cmd -c ~/.s3cfg_certificate_object ls s3://certbucket/$DOMAIN_NAME/privkey.pem)" ]; then
 ./install_ssl_certbot.sh "$DOMAIN_NAME" "$EMAIL" "$DOC_ROOT" ; exit_code_certbot=$?
 sleep 3
 s3cmd -c ~/.s3cfg_certificate_object put -r "/etc/letsencrypt/archive/$DOMAIN_NAME/" s3://certbucket/$DOMAIN_NAME/
else
 exit_code_certbot=0
 mkdir -p "/etc/letsencrypt/archive/$DOMAIN_NAME"
 s3cmd -c ~/.s3cfg_certificate_object get -r "s3://certbucket/$DOMAIN_NAME/" "/etc/letsencrypt/archive/$DOMAIN_NAME/"
 find /etc/letsencrypt/archive/$DOMAIN_NAME/ -type f -name "*chain*" -or -name "*cert*" -exec chmod 644 {} +
 find /etc/letsencrypt/archive/$DOMAIN_NAME/ -type f -name "*priv*" -exec chmod 600 {} +
 mkdir -p "/etc/letsencrypt/live/$DOMAIN_NAME"

 cert=$(basename $(find /etc/letsencrypt/archive/$DOMAIN_NAME/ -type f -name "cert*.pem" | tail -n 1))
 ln -s "/etc/letsencrypt/archive/$DOMAIN_NAME/$cert" "/etc/letsencrypt/live/$DOMAIN_NAME/$cert"

 chain=$(basename $(find /etc/letsencrypt/archive/$DOMAIN_NAME/ -type f -name "chain*.pem" | tail -n 1))
 ln -s "/etc/letsencrypt/archive/$DOMAIN_NAME/$chain" "/etc/letsencrypt/live/$DOMAIN_NAME/$chain"

 fullchain=$(basename $(find /etc/letsencrypt/archive/$DOMAIN_NAME/ -type f -name "fullchain*.pem" | tail -n 1))
 ln -s "/etc/letsencrypt/archive/$DOMAIN_NAME/$fullchain" "/etc/letsencrypt/live/$DOMAIN_NAME/$fullchain"

 privkey=$(basename $(find /etc/letsencrypt/archive/$DOMAIN_NAME/ -type f -name "privkey*.pem" | tail -n 1))
 ln -s "/etc/letsencrypt/archive/$DOMAIN_NAME/$privkey" "/etc/letsencrypt/live/$DOMAIN_NAME/$privkey"

fi
# if [[ $? -ne 0 ]]; then
# 	echo "Warning: install ssl certbot script fail!"
# 	exit 1
# fi

# if ssl installation is success, then define vhost with ssl
if [[ $exit_code_certbot -eq 0 ]]; then
	/usr/bin/systemctl stop nginx
	poolname=$(echo "$DOMAIN_NAME" | cut -d"." -f1)

	#create vhost conf with the specified domain in  sites-available
	cat <<EOF>/etc/nginx/sites-available/"$DOMAIN_NAME.conf"
include /etc/nginx/define_fastcgi_cache.conf;
include /etc/nginx/map_webp.conf;
server {
	listen 80;
	server_name $DOMAIN_NAME;
	access_log /var/log/nginx/$DOMAIN_NAME.access.log;

	return 301 https://$DOMAIN_NAME\$request_uri;
}
server {
	listen 443 quic reuseport;
	listen 443 ssl;
	http2 on;


	server_name $DOMAIN_NAME;
	include /etc/nginx/ssl_secure.conf;
	ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
	access_log /var/log/nginx/$DOMAIN_NAME-ssl.access.log;
	error_log /var/log/nginx/$DOMAIN_NAME-ssl.error.log;

	root /usr/share/nginx/$DOMAIN_NAME;
	index index.html index.htm index.php;
	include /etc/nginx/fastcgi_cache_rules.conf;
	include /etc/nginx/security_header.conf;
	location / {
		try_files \$uri \$uri/ /index.php\$args;  

		# so browsers can redirect them to quic port
		add_header alt-svc 'quic=":443"';
		
		add_header Alt-Svc 'h3=":443"; ma=86400';

		# disable directory indexing
		autoindex off;
		# block author scanning
		if (\$query_string ~ "author=\d+"){
			return 403;
		}
	}

	location ~ \.php\$ {
		try_files \$uri =404;

		include fastcgi_params;
		
		fastcgi_split_path_info ^(.+\\\\.php)(/.+)\$;
		fastcgi_pass unix:/var/run/php8.1-fpm-$poolname.sock;
		fastcgi_param SCRIPT_FILENAME \$document_root/\$fastcgi_script_name;
		#fastcgi_index index.php;
		fastcgi_cache_bypass \$skip_cache;
		fastcgi_no_cache \$skip_cache;
		fastcgi_cache WORDPRESS;
		fastcgi_cache_valid 60m;
		add_header X-Cache \$upstream_cache_status;
		add_header alt-svc 'quic=":443"';
		
		add_header Alt-Svc 'h3=":443"; ma=86400';
	
	}
	location ~ /purge(/.*) {
		add_header Alt-Svc 'h3=":443"; ma=86400';
		fastcgi_cache_purge WORDPRESS "\$scheme\$request_method\$host\$1";
	}
	# WebP
	location ~* ^/.+\.(png|gif|jpe?g)\$ {
		#expires max;
		add_header Cache-Control "max-age=604800, must-revalidate";
		try_files \$uri\$webp_suffix \$uri =404;
		#add_header Alt-Svc 'h3=":443"; ma=86400';
	}

	location ~* (ogg|ogv|svg|svgz|eot|otf|woff|webp|mp4|ttf|css|rss|atom|js|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bpm|rtf)\$ {
		#expires max;
		add_header Cache-Control "max-age=604800, must-revalidate";

		#add_header Alt-Svc 'h3=":443"; ma=86400';
		log_not_found off;
		access_log off;
	}
	location = /robots.txt {
		add_header alt-svc 'quic=":443"';
		add_header Alt-Svc 'h3=":443"; ma=86400';

		access_log off;
		log_not_found off;
	}
	location ~ /\.well-known\/acme-challenge {
		allow all;
	}

	#include configuration of wp secure
	include /etc/nginx/wp-secure.conf;

	#CIS Benchmark Nginx: 2.5.4
	location ~ /\. {
		deny all;
		return 404;
	}
}
EOF

	nginx_test=$(nginx -t 2>&1)
	if [[ $nginx_test =~ ok || $nginx_test =~ successful ]]; then
		echo "Info: The configuration is ok and Nginx test successful"
		# After know that test successfull, activate vhost
		ln -s /etc/nginx/sites-available/$DOMAIN_NAME.conf /etc/nginx/sites-enabled
	else
		echo "Error: configuration error and nginx test is not successful! Check configuration again"
		exit 1
	fi
fi

if [ ! -d "/etc/letsencrypt/live/$DOMAIN_NAME" ]; then
	echo "Warning: SSL still not installed for $DOMAIN_NAME"
	exit 1
fi