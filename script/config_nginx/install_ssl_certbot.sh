#!/bin/bash

#set -x

# $1 is domain_name
# $2 is email
domain="$1"
email="$2"
docroot="$3"

if [ -n "$(pgrep -f nginx)" ]; then
    systemctl stop nginx
fi

if [ ! -f "/usr/local/bin/certbot" ]; then
    if [ -f pip ]; then 
        pip --no-cache-dir install certbot
    elif [ -f pip3 ]; then
        pip3 --no-cache-dir install certbot
    else
        if [ -f $(which python3) ]; then
            wget https://bootstrap.pypa.io/get-pip.py
            python3 get-pip.py
            rm -f get-pip.py
        elif [ -f $(which python) ]; then
            wget https://bootstrap.pypa.io/get-pip.py
            python get-pip.py
            rm -f get-pip.py
        else
            echo "Warning: python is not installed!"
            exit 1
        fi
        pip --no-cache-dir install certbot
    fi
fi
/usr/local/bin/certbot certonly --webroot -w "$docroot" -d "$domain" -n --no-autorenew --agree-tos --email "$email" > /var/log/certbot.log 2>&1; exitcode=$?

if [[ "$exitcode" -eq 1 ]]; then
    exit 1
else
    exit 0
fi