#!/bin/bash

EXIT_CODE=0
if [[ ! $PWD =~ "/root/script/install_nginx$" ]]; then
    cd /root/script/install_nginx
fi

. ./nginx.preinst

. ./compile_nginx

if [ -n "$(nginx -V 2>&1)" ]; then
. ./configure_systemd_nginx.sh
. ./nginx.postinst configure
  if [ -n "$(pgrep -f nginx)" ]; then
    pkill -9 -f nginx
    systemctl daemon-reload
    systemctl enable nginx
    systemctl restart nginx
    if [[ $? -ne 0 ]]; then
      echo "Warning: restart NGINX failed!"
      exit 1
    fi
  else
    systemctl daemon-reload
    systemctl enable nginx
    systemctl restart nginx
    if [[ $? -ne 0 ]]; then
      echo "Warning: restart NGINX failed!"
      exit 1
    fi
  fi
else
    echo "Error: binary nginx not found and  nginx compilation failed!"
    exit 1
fi

cd ..

exit 0