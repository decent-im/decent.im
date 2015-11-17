#!/bin/bash

set -e

echo "decent.im" > /etc/hostname

echo deb http://packages.prosody.im/debian vivid main > /etc/apt/sources.list.d/prosody.list
wget https://prosody.im/files/prosody-debian-packages.key -O- | sudo apt-key add -
apt-get update
apt-get install -V -y prosody-0.10 lua-dbi-mysql lua-zlib libevent-2.0 lua-event

. ./secret/env.sh

cp /etc/prosody/prosody.cfg.lua{,.bkp}
cat ./prosody.cfg.lua | sed "s/%%MYSQL_PROSODY_PASSWORD%%/$MYSQL_PROSODY_PASSWORD/" > /etc/prosody/prosody.cfg.lua

# deploy mod_mam
apt-get install -V -y mercurial
hg clone http://hg.prosody.im/prosody-modules/ || true
cp -r \
	prosody-modules/mod_mam \
	prosody-modules/mod_http_upload \
	/usr/lib/prosody/modules/

# Create MySQL DB
echo "
mysql-server-5.6 mysql-server/root_password password $MYSQL_ROOT_PASSWORD
mysql-server-5.6 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD
" | debconf-set-selections
apt-get install -V -y mysql-server
echo 'drop database prosody;' | mysql -uroot -p"$MYSQL_ROOT_PASSWORD" || true
echo '
create database prosody;
create user `prosody`@`localhost` identified by "'$MYSQL_PROSODY_PASSWORD'";
grant all on `prosody`.* to `prosody`@`localhost`;
' | mysql -uroot -p"$MYSQL_ROOT_PASSWORD"

# Deploy or issue certs
# prosodyctl cert generate decent.im  # interactive, requires manual actions
cp secret/decent.im.{cnf,crt,key} /var/lib/prosody/
chown prosody.prosody /var/lib/prosody/decent.im.*
chmod u=r,g=,o= /var/lib/prosody/decent.im.*

# Restore users, chat archives, etc
./db_restore.sh

service prosody restart

