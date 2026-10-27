#!/bin/sh
set -e

mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<-EOSQL
    CREATE DATABASE IF NOT EXISTS cms_test;
    GRANT ALL ON cms_test.* TO '$MYSQL_USER'@'%';
    FLUSH PRIVILEGES;
EOSQL

