#!/bin/bash

#$! is DOMAIN_NAME

DOMAIN_NAME="$1"
pool_name=$(echo "$DOMAIN_NAME" | cut -d"." -f1)
doc_root=/usr/share/nginx/$DOMAIN_NAME

if [ -z "$pool_name" ]; then
    echo "$pool_name"
    echo "Warning: pool_name is empty or not defined!"
    exit 1
fi

if [ -z $doc_root ]; then
    echo "Warning: doc_root is empty or is not defined!"
    exit 1
fi

#Create user and group for fpm
# creating nginx group if he isn't already there
if ! getent group $pool_name >/dev/null; then
    groupadd --system $pool_name >/dev/null
fi

# creating nginx user if he isn't already there
if ! getent passwd $pool_name >/dev/null; then
    useradd \
    --system \
    --gid nginx \
    --no-create-home \
    --home /nonexistent \
    --shell /usr/sbin/nologin \
    $pool_name  >/dev/null
fi

cat <<EOF>"/etc/php/8.1/fpm/pool.d/$pool_name.conf"
[$pool_name]
user = $pool_name
group = $pool_name
listen = /var/run/php8.1-fpm-$pool_name.sock
listen.owner = nginx
listen.group = nginx
php_admin_value[disable_functions] = exec,passthru,shell_exec,system
php_admin_flag[allow_url_fopen] = off
pm = dynamic
pm.max_children = 500
pm.max_requests = 2000
pm.start_servers = 25
pm.min_spare_servers = 1
pm.max_spare_servers = 25
EOF

if [ -d "$doc_root" ]; then
    chown "$pool_name":"$pool_name" "$doc_root"
    chmod 755 "$doc_root"

    find "$doc_root" -type f -exec chmod 644 {} + > /dev/null
    find "$doc_root" -type d -exec chmod 755 {} + > /dev/null
else
    echo "Warning: $doc_root not found!"
    exit 1
fi

systemctl restart php8.1-fpm
if [[ $? -ne 0 ]]; then
    echo "Warning: restart php-fpm failed!"
    exit 1
fi

exit 0