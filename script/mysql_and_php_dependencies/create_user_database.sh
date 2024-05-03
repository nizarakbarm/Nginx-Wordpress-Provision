#!/bin/bash

##set -x
EXIT_CODE=0
LOG_SETUP_DATABASE="/var/log/log_setup_mysql.log"
if [ ! -f $LOG_SETUP_DATABASE ]
then
    touch $LOG_SETUP_DATABASE
fi

. ./basic_single_escape.sh


root_pass=$(basic_single_escape "$root_pass")
echo -e "[mysql]\nuser=root\npassword='"$root_pass"'" > /root/.my.cnf

username=$(basic_single_escape "$username")
password=$(basic_single_escape "$password")
database_name=$(basic_single_escape "$database_name")
# Create username and database
mysql -u root -e "CREATE DATABASE $database_name;" > /dev/nulls 2>&1
if [[ $? -eq 0 ]]
then
    echo "$(date '+%d/%b/%Y:%T') Info: Create Database Success" >> $LOG_SETUP_DATABASE 2>&1
else
    echo "$(date '+%d/%b/%Y:%T') Warning: Create Database Failed" >> $LOG_SETUP_DATABASE 2>&1
    EXIT_CODE=1
    exit $EXIT_CODE
fi
mysql -u root -e "CREATE USER '$username'@'localhost' IDENTIFIED BY '"$password"';" > /dev/nulls 2>&1
if [[ $? -eq 0 ]]
then
    echo "$(date '+%d/%b/%Y:%T') Info: Create Username Success" >> $LOG_SETUP_DATABASE 2>&1
else
    echo "$(date '+%d/%b/%Y:%T') Warning: Create Username Failed" >> $LOG_SETUP_DATABASE 2>&1
    EXIT_CODE=1
    exit $EXIT_CODE
fi
mysql -u root -e "GRANT ALL PRIVILEGES ON $database_name.* TO '$username'@'localhost';" > /dev/nulls 2>&1
if [[ $? -eq 0 ]]
then
    echo "$(date '+%d/%b/%Y:%T') Info: Grant Privileges Success" >> $LOG_SETUP_DATABASE 2>&1
    EXIT_CODE=1
    exit $EXIT_CODE
else
    echo "$(date '+%d/%b/%Y:%T') Warning: Grant Privileges Failed" >> $LOG_SETUP_DATABASE 2>&1
    EXIT_CODE=1
    exit $EXIT_CODE
fi
mysql -u root -e "FLUSH PRIVILEGES;" > /dev/nulls 2>&1

# Delete ~/.my.cnf
rm -f ~/.my.cnf

