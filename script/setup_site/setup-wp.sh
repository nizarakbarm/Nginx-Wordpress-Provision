#!/bin/bash

print_help() {
    echo ""
    echo "Setup WP"
    echo "Usage: $PROGNAME [-d|--domain-name <domain-name>] [--url <url>] [-ud|--user_db <user_db>] [-pd|--pass_db <pass_db>] [-db|--dbname <db_name>] [-t|--title <title>] [-u|--admin_user <admin_user>] [-p|--admin_pass <admin_pass>] [e|--admin_email <admin_email>] [t|--github-token <github-token>]"
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
            domain_name="$2"
            shift
            ;;
        -d)
            domain_name="$2"
            shift
            ;;
        --url)
            url="$2"
            shift
            ;;
        --user_db)
            db_user="$2"
            shift
            ;;
        -ud)
            db_user="$2"
            shift
            ;;
        --pass_db)
            db_pass="$2"
            shift
            ;;
        -pd)
            db_pass="$2"
            shift
            ;;
        --dbname)
            db_name="$2"
            shift
            ;;
        -db)
            db_name="$2"
            shift
            ;;
        --title)
            title="$2"
            shift
            ;;
        -t)
            title="$2"
            shift
            ;;
        --admin_user)
            admin_user="$2"
            shift
            ;;
        -u)
            admin_user="$2"
            shift
            ;;
        --admin_pass)
            admin_pass="$2"
            shift
            ;;
        -p)
            admin_pass="$2"
            shift
            ;;
        --admin_email)
            admin_email="$2"
            shift
            ;;
        -e)
            admin_email="$2"
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

# Check if domain name have been defined
if [ -z "$domain_name" ]
then
    echo "Warning: domain name is not defined!"
    exit 1
fi

# Create vhost directory
WP_DIR="/usr/share/nginx/$domain_name"
if [ ! -d "$WP_DIR" ]; then
    mkdir "$WP_DIR"
    chmod 755 "$WP_DIR"
fi

#Download and configure wp
wp --path="$WP_DIR" core download --allow-root
if [[ $? -ne 0 ]]; then
    echo "Warning: wp core download failed!"
    exit 1
fi

# Generate config file
wp --path="$WP_DIR" config create --dbname="$db_name" --dbuser="$db_user" --dbpass="$db_pass" --dbprefix="wp" --allow-root
if [[ $? -ne 0 ]]; then
    echo "Warning: wp config create failed!"
    exit 1
fi

# Install wordpress
wp --path="$WP_DIR" core install --url=$url --title="$title" --admin_user="$admin_user" --admin_password="$admin_pass" --admin_email="$admin_email" --allow-root
if [[ $? -ne 0 ]]; then
    echo "Warning: wp core install failed!"
    exit 1
fi

export COMPOSER_ALLOW_SUPERUSER=1
/usr/local/bin/composer config -n -g github-oauth.github.com $GITHUB_TOKEN
# install  wp-cli-secure and disable-file-editor using wp-secure
wp --path="$WP_DIR" package install https://github.com/igorhrcek/wp-cli-secure-command.git --allow-root
/usr/local/bin/composer config -n -g --unset github-oauth.github.com
unset COMPOSER_ALLOW_SUPERUSER
wp --path="$WP_DIR" secure disable-file-editor --allow-root

#chown www-data:www-data $WP_DIR -R

exit 0