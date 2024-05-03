#!/bin/bash

#define fastcgi cache path
cat <<EOF>/etc/nginx/define_fastcgi_cache.conf
fastcgi_cache_path /var/run/nginx-cache levels=1:2 keys_zone=WORDPRESS:100m inactive=60m;
fastcgi_cache_key "\$scheme\$request_method\$host\$request_uri";
EOF

#define fastcgi cache rules
cat <<EOF>/etc/nginx/fastcgi_cache_rules.conf
set \$skip_cache 0;

# POST requests and URLs with a query string should always go to PHP
if (\$request_method = POST) {
	set \$skip_cache 1;
}

if (\$query_string != "") {
	set \$skip_cache 1;
}

#Don't cache URIs containing the following segments
if (\$request_uri ~* "wp-admin/|/xmlrpc.php|wp-*.php|/feed/index.php|sitemap(_index)?.xml") {
	set \$skip_cache 1;
}

#Don't use the cache for logged-in users or recent commenters
if (\$http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") {
	set \$skip_cache 1;
}
EOF