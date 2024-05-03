#!/bin/bash

##set -x

print_help() {
    echo ""
    echo "Create username for database at MySQL/MariaDB"
    echo "Usage: $PROGNAME [-u|--username  <username>] [-d|--database <database>] [-r|--root-pass <root-password-mysql>]"
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
        --username)
            username=$2
            shift
            ;;
        -u)
            username=$2
            shift
            ;;
        --database)
            database_name=$2
            shift
            ;;
        -d)
            database_name=$2
            shift
            ;;
        --root-pass)
            root_pass="$2"
            shift
            ;;
        -r)
            root_pass="$2"
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

if [[ ! $PWD =~ "/root/script/mysql_and_php_dependencies$" ]]; then
    cd /root/script/mysql_and_php_dependencies
fi

EXIT_CODE=0

create_random_string() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9!#\$%&()*+,-./:;<=>?@[\]^_\{|}\~' | fold -w 12 | head -n 1
}

password="$(create_random_string)"
echo "$password"

#root_pass=$ROOT_PASS
#install mysql by using ROOT_PASS defined at environment variables
. ./install_mysql.sh

#install php and it's dependencies
. ./install_php_dependencies.sh

#create username database, database, and grant the privilege
. ./create_user_database.sh

#cd
#echo "EXIT CODE is $EXIT_CODE"
exit $EXIT_CODE

