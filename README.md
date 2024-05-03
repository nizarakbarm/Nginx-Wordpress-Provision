# Nginx-Wordpress-AWS-Provider
Terraform code and bash script that can be used for Nginx-Wordpres-PHP provision in any VM

The content of this repository is:
- bash script


script is used for Nginx-Wordpress-PHP-MySQL provision in any VM. Nginx-Wordpress-PHP-Mysql provision inside script is following security best practice, which is:

- CIS Benchmark for Nginx https://www.cisecurity.org/benchmark/nginx

- Drop database test, delete privilege of database test, delete anonymous user, and change root password to stronger password.

- Using wp-cli/secure-command to add security configuration for wordpress, which is:

    - disable file editor
    
    - Block access to XMLRPC

    - Block author scanning

    - Block PHP Access to plugins directory

    - Block PHP Access in uploads directory

    - Block PHP Access in wp-includes diectory

    - Block PHP Access in themes directory

    - Block Directory Browsing

- Using Nginx 1.25.3 Release which has Bug Fix for HTTP/2 Rapid Reset DDOS Attack Vulnerability

Other than security best practice, the configuration is also optimized for perfomance, which is:

- For MySQL:

    - innodb_flush_method set to O_DIRECT to avoid double write buffering

    - max_write_lock_count is decreased to 16 to reduce bottleneck of read operation caused by its excessively high value

    - join_buffer_size set to 1M to reduce join operation not buffered

    - skip-name-resolve is set to ON to prevent MySQL from resolving hostname by using DNS

    - thread_cache_size set to 55 so 55 connection can be satisfied by cache from thread

    - max_connections reduced to 50 to reduce memory consumption. You can change this if you need more connection.

- For Nginx:

    - Using static cache by using header Cached-Control with max-age and must-revalidate for static file

    - Using dynamic cache by fastcgi-cache, this can be combined with Nginx Helper plugin in Wordpress too

    - Using gzip compression

    - Using quic or http3 to reduce initial connection time because TCP 3-Way Handshake


# Table of Contents
- [Requirement](#Requirement)
- [Installation](#Installation)
- [Usage](#Usage)

# Requirement
Technology stack needed for this:
- Terraform >= 1.6.0
- Bash == 5.x


# Installation


- Download provision script from script by using this command:

    - First Login to your VM by using SSH

    - Then run this command:

        ```
        sudo su # if you are not in root
        cd /root
        curl -o Nginx-Wordpress-Provision-v0.1.tar.gz https://github.com/nizarakbarm/Nginx-Wordpress-AWS-Provision/archive/refs/tags/v0.1.tar.gz
        tar xvfz Nginx-Wordpress-Provision-v0.1.tar.gz
        sudo mv Nginx-Wordpress-Provision-v0.1/script /root
        sudo chown root:root script -R
        sudo find /root/script -type f -exec chmod 755 {} +
        ```

# Usage


## Provision Nginx-Wordpress-PHP with Bash Script from Directory script

Run this command:

```
/root/script/main.sh \
-d [DOMAIN_NAME] -r [ROOT_PASSWORD] \
-ud [USERNAME_DB] -db "$DB_NAME" \
-t [TITLE] -u [USERNAME] \

-p [PASSWORD] -e [EMAIL]
--github-token [GITHUB_TOKEN] > /root/log_installation 2>&1
```
  with some argument:
  - [DOMAIN_NAME] : Domain Name for Wordpress
  - [ROOT_PASSWORD] : Root Password of MySQL
  - [USERNAME_DB] : Username DB for Wordpress
  - [DB_NAME] : DB Name for Wordpress
  - [TITLE]: Title for Wordpress
  - [USERNAME]: Username admin for Wordpress
  - [PASSWORD]: Admin password for Wordpress
  - [EMAIL]: Email password for Wordpress
  - [GITHUB_TOKEN]: GITHUB_TOKEN needed for wp package install


# Provision by Using GitHub Action

If you want to provision Nginx-Wordpress-PHP by using github action you can check my github action inside .github/workflows/ci-provision.yml.

To use my workflow, there are some variables and secrets that need to be defined


## Variable

You need to define variable inside your repo settings > Secrets and variables > Actions > choose Variables tab > New repository variable.

All the variable that will be created are:

DOMAIN_NAME: Variable for domain name that will be used by script/main.sh

TITLE: Title that will be used by script/main.sh

PUBLIC_IPS: All IP of the VM

S3_ALLOWED_IPS: All allowed IP for S3


## Secrets

You need to define variable inside your repo settings > Secrets and variables > Actions > choose Secrets tab > New repository Secret.

All the secrets that will be created are:

DB_NAME: secret for database name that will be used by script/main.sh for wordpress

EMAIL: secret for email address that will be used by script/main.sh for wordpress

PASSWORD: secret for password that will be used by script/main.sh for wordpress

PORT_SSH: secret for ssh port that of ec2 that will be used for rsync inside workflow

USERNAME_VM: username vm that used for login to SSH

ROOT_PASSWORD: secret for root password database that will be used by script/main.sh

S_KEY: secret for private key that will be used for ssh-agent inside workflow

USERNAME: secret for username wordpress that will be used by script/main.sh

USERNAME_DB: secret for USERNAME_DB that will be used by script/main.sh

SECRET_KEY: secret key of s3

ACCESS_KEY: access key of s3

S3_HOST: s3 host endpoint



## Triggers of workflow

To use this workflow, you need to develop something inside the develop branch, then create a pull request because my workflow uses a trigger on pull requests.








