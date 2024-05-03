#!/bin/bash

sed "s/^#\?Port 22$/Port 5522/g" /etc/ssh/sshd_config
if [[ $? -ne 0 ]]; then
    echo "Warning: change port failed!"
    exit 1
fi

systemctl restart sshd
exit 0