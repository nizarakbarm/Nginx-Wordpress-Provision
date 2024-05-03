#!/bin/bash

##set -x

LOG_INSTALL_MYSQL="/var/log/install_mysql.log"
if [ ! -f $LOG_INSTALL_MYSQL ]
then
    touch $LOG_INSTALL_MYSQL
fi

. ./basic_single_escape.sh

sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
sed -i "/#\$nrconf{kernelhints} = -1;/s/.*/\$nrconf{kernelhints} = -1;/" /etc/needrestart/needrestart.conf
apt -o Apt::Get::Assume-Yes=true install mysql-server > /dev/nulls 2>&1
if [[ $? -eq 0 ]] 
then
    echo "$(date '+%d/%b/%Y:%T') Info: Install MySQL Success" >> $LOG_INSTALL_MYSQL
else
    echo "$(date '+%d/%b/%Y:%T') Warning: Install MySQL Failed" >> $LOG_INSTALL_MYSQL
    EXIT_CODE=1
    exit $EXIT_CODE
fi
sed -i "/\$nrconf{restart} = 'a';/s/.*/#\$nrconf{restart} = 'i';/" /etc/needrestart/needrestart.conf
sed -i "/\$nrconf{kernelhints} = -1;/s/.*/#\$nrconf{kernelhints} = -1;/" /etc/needrestart/needrestart.conf

. ./mysqld_conf.sh

systemctl enable mysql && systemctl restart mysql > /dev/nulls 2>&1
if [[ $? -ne 0 ]]; then
    echo "Warning: restart MySQL failed!"
    EXIT_CODE=1
    exit $EXIT_CODE
fi

if [ -z "$root_pass" ]
then
    echo "Warning: root password is not defined!"
    print_help
    EXIT_CODE=1
    exit $EXIT_CODE
fi

# delete anonymous user
mysql -e "DELETE FROM mysql.user WHERE User='';" > /dev/nulls 2>&1
if [[ $? -eq 0 ]]
then
    echo "$(date '+%d/%b/%Y:%T') Info: Delete Anonymous User Success" >> $LOG_INSTALL_MYSQL
else
    echo "$(date '+%d/%b/%Y:%T') Warning: Delete Anonymous User Failed" >> $LOG_INSTALL_MYSQL
    EXIT_CODE=1
    exit $EXIT_CODE
fi
# delete remote root
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" > /dev/nulls 2>&1
# remove test database and it's privileges
if [ ! -z $(mysql -e "SHOW DATABASES LIKE 'test'") ]
then
    mysql -e "DROP DATABASE test;" > /dev/nulls 2>&1
    if [[ $? -eq 0 ]]
    then
        echo "$(date '+%d/%b/%Y:%T') Info: DROP Database Test Success" >> $LOG_INSTALL_MYSQL
    else
        echo "$(date '+%d/%b/%Y:%T') Warning: DROP Database Test Failed" >> $LOG_INSTALL_MYSQL
        EXIT_CODE=1
        exit $EXIT_CODE
    fi
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'" > /dev/nulls 2>&1
    if [[ $? -eq 0 ]]
    then
        echo "$(date '+%d/%b/%Y:%T') Info: Delete Privilege of Database Test Success" >> $LOG_INSTALL_MYSQL
    else
        echo "$(date '+%d/%b/%Y:%T') Warning: Delete Privilege of Database Test Failed" >> $LOG_INSTALL_MYSQL
        EXIT_CODE=1
        exit $EXIT_CODE
    fi
fi

# reload privileges
mysql -e "FLUSH PRIVILEGES;" > /dev/nulls 2>&1

esc_root_pass=$(basic_single_escape "$root_pass")
# Update root password
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$esc_root_pass';" > /dev/nulls 2>&1
if [[ $? -eq 0 ]]
then
    echo "$(date '+%d/%b/%Y:%T') Info: ALTER Root Password Success" >> $LOG_INSTALL_MYSQL
else
    echo "$(date '+%d/%b/%Y:%T') Warning: ALTER Root Password Failed" >> $LOG_INSTALL_MYSQL
    EXIT_CODE=1
    exit $EXIT_CODE
fi

EXIT_CODE=0