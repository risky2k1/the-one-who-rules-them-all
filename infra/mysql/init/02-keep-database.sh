#!/bin/sh
set -e

mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<-EOSQL
    CREATE DATABASE IF NOT EXISTS keep_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    GRANT ALL ON keep_db.* TO '$MYSQL_USER'@'%';
    FLUSH PRIVILEGES;
EOSQL
