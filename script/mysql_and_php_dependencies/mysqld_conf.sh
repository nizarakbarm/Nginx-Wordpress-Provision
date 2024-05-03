#!/bin/bash

#configure mysqld
cat <<EOF>/etc/mysql/mysql.conf.d/mysqld.cnf
[mysqld]
user		= mysql

bind-address		= 127.0.0.1
mysqlx-bind-address	= 127.0.0.1
skip-name-resolve=ON
key_buffer_size		= 16M
innodb_buffer_pool_size = 64M
join_buffer_size= 1M
innodb_redo_log_capacity= 32M

myisam-recover-options  = BACKUP

innodb_flush_method = O_DIRECT
max_write_lock_count      = 16
thread_cache_size         = 55

max_connections        = 50

log_error = /var/log/mysql/error.log
max_binlog_size   = 100M
EOF