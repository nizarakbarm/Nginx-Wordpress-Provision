#!/bin/bash

EXIT_CODE=0
ERROR_MESSAGE="Failed to"

print_help() {
    echo ""
    echo "Provision Nginx, php-fpm, and wordpress"
    echo "Usage: $PROGNAME [-d|--domain-name <domain-name>] [-r|rooot-password <root-password>] [-ud|--user_db <user_db>] [-db|--dbname <db_name>] [-t|--title <title>] [-u|--admin_user <admin_user>] [-p|--admin_pass <admin_pass>] [-e|--admin_email <admin_email>] [-t|--github-token <github-token>]"
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
        --domain-name)
            DOMAIN_NAME="$2"
            shift
            ;;
        -d)
            DOMAIN_NAME="$2"
            shift
            ;;
        --root-password)
            ROOT_PASSWORD="$2"
            shift
            ;;
        -r)
            ROOT_PASSWORD="$2"
            shift
            ;;
        --user_db)
            USERNAME_DB="$2"
            shift
            ;;
        -ud)
            USERNAME_DB="$2"
            shift
            ;;
        --dbname)
            DB_NAME="$2"
            shift
            ;;
        -db)
            DB_NAME="$2"
            shift
            ;;
        --title)
            TITLE="$2"
            shift
            ;;
        -t)
            TITLE="$2"
            shift
            ;;
        --admin_user)
            USERNAME="$2"
            shift
            ;;
        -u)
            USERNAME="$2"
            shift
            ;;
        --admin_pass)
            PASSWORD="$2"
            shift
            ;;
        -p)
            PASSWORD="$2"
            shift
            ;;
        --admin_email)
            EMAIL="$2"
            shift
            ;;
        -e)
            EMAIL="$2"
            shift
            ;;
        --github-token)
            GITHUB_TOKEN="$2"
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

if [ -z "$USERNAME_DB" ]; then
    echo "Warning: USERNAME_DB is not defined!"
    exit 1
fi

if [ -z "$DB_NAME" ]; then
    echo "Warning: DB_NAME is not defined!"
    exit 1
fi

if [ -z "$USERNAME" ]; then
    echo "Warning: USERNAME is not defined!"
    exit 1
fi

if [ -z "$PASSWORD" ]; then
    echo "Warning: PASSWORD is not defined!"
    exit 1
fi

if [ -z "$EMAIL" ]; then
    echo "Warning: EMAIL is not defined!"
    exit 1
fi

if [ -z "$TITLE" ]; then
    echo "Warning: TITLE is not defined!"
    exit 1
fi

if [ -z "$DOMAIN_NAME" ]; then
    echo "Warning: $DOMAIN_NAME is not defined!"
    exit 1
fi

if [ -z "$ROOT_PASSWORD" ]; then
    echo "Warning: ROOT_PASSWORD is not defined!"
    exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Warning: GITHUB_TOKEN is not defined!"
    exit 1
fi

if [[  ! $PWD =~ "/root/script$" ]]; then
    cd /root/script
fi

# cd ./ubuntu-22-04-cis-hardening
# ./entrypoint.sh
# cd ..

./install_nginx/install_nginx.sh
[[ $? -ne 0 ]] && EXIT_CODE=1 && ERROR_MESSAGE+=" [Install Nginx] "

PASSWORD_DB="$(./mysql_and_php_dependencies/mysql_and_php.sh -u "$USERNAME_DB" -d "$DB_NAME" -r "$ROOT_PASSWORD")"
# [[ $? -ne 0 ]] && EXIT_CODE=1 && ERROR_MESSAGE+=" [Install PHP, MySQL, and Setup MySQL] "

#install wp cli
./setup_site/install-wp-cli.sh
[[ $? -ne 0 ]] && EXIT_CODE=1 && ERROR_MESSAGE+=" [Install wp-cli] "

./setup_site/setup-wp.sh -d "$DOMAIN_NAME" --url "https://$DOMAIN_NAME" -ud "$USERNAME_DB" -pd "$PASSWORD_DB" -db "$DB_NAME" -t "$TITLE" -u "$USERNAME" -p "$PASSWORD" -e "$EMAIL" --github-token "$GITHUB_TOKEN"
[[ $? -ne 0 ]] && EXIT_CODE=1 && ERROR_MESSAGE+=" [Setup WP using wp-cli] "


./config_nginx/conf_nginx.sh -s "$DOMAIN_NAME" -e "$EMAIL"
[[ $? -ne 0 ]] && EXIT_CODE=1 && ERROR_MESSAGE+=" [Config NGINX] "

./conf_php_fpm/setup_pool_conf.sh "$DOMAIN_NAME"
[[ $? -ne 0 ]] && EXIT_CODE=1 && ERROR_MESSAGE+=" [Setup FPM Pool] "


if [[ $EXIT_CODE -ne 0 ]]; then
    echo "Warning: $ERROR_MESSAGE"
    echo "Doing Cleanup"
    systemctl stop nginx
    apt purge mysql-server* -y; rm -rf /var/lib/mysql /usr/sbin/nginx /var/cache/nginx /usr/local/bin/wp /root/.my.cnf /etc/systemd/system/nginx.service /usr/share/nginx > /dev/null 2>&1
    systemctl daemon-reload
    echo "Doing Cleanup Done"
    exit 1
fi

exit 0