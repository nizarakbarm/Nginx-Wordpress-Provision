#!/bin/bash

openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048 > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "Warning: create dhparam failed!"
    EXIT_CODE=1
    exit $EXIT_CODE
fi
chmod 400 /etc/nginx/ssl/dhparam.pem