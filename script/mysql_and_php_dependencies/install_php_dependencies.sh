#!/bin/bash

LOG_SETUP_PHP="/var/log/log_setup_php.log"
if [ ! -f $LOG_SETUP_PHP ]
then
    touch $LOG_SETUP_PHP
fi
EXIT_CODE=0

sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
sed -i "/#\$nrconf{kernelhints} = -1;/s/.*/\$nrconf{kernelhints} = -1;/" /etc/needrestart/needrestart.conf
apt -o Apt::Get::Assume-Yes=true install php8.1 php8.1-{curl,common,igbinary,imagick,intl,mbstring,mysql,xml,zip,apcu,memcache,opcache,redis,bcmath,fpm} > /dev/nulls 2>&1
if [[ $? -eq 0 ]] 
then
    echo "$(date '+%d/%b/%Y:%T') Info: Install PHP Success" >> $LOG_SETUP_PHP 2>&1
else
    echo "$(date '+%d/%b/%Y:%T') Warning: Install PHP Failed" >> $LOG_SETUP_PHP 2>&1
    EXIT_CODE=1
    exit $EXIT_CODE
fi
sed -i "/\$nrconf{restart} = 'a';/s/.*/#\$nrconf{restart} = 'i';/" /etc/needrestart/needrestart.conf
sed -i "/\$nrconf{kernelhints} = -1;/s/.*/#\$nrconf{kernelhints} = -1;/" /etc/needrestart/needrestart.conf
