#!/bin/bash

set -e

echo deb http://packages.prosody.im/debian `lsb_release -sc` main > /etc/apt/sources.list.d/prosody.list
wget https://prosody.im/files/prosody-debian-packages.key -O- | sudo apt-key add -
apt-get update
apt-get install -V -y prosody-0.10 lua-dbi-mysql lua-zlib libevent-2.0 lua-event

source `dirname $0`/secret/env.sh || source `dirname $0`/secret_env.sh.sample

source `dirname $0`/env.sh || source `dirname $0`/env.sh.sample

echo "$DOMAIN_NAME" > /etc/hostname

# Deploy all tracked files
rsync -av `dirname $0`/files/ /
# Deploy all tracked files from secret repository
rsync -av `dirname $0`/secret/files/ / || true

cat /etc/prosody/prosody.cfg.lua.template | sed \
	-e "s/%%MYSQL_PROSODY_PASSWORD%%/$MYSQL_PROSODY_PASSWORD/g" \
	-e "s/%%ADMIN_JID%%/$ADMIN_JID/g" \
	-e "s/%%DOMAIN_NAME%%/$DOMAIN_NAME/g" \
	> /etc/prosody/prosody.cfg.lua

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
# Certs are deployed from secret/files/var/lib/prosody
# Alternatively, you can generate them manually and interactively by command
# prosodyctl cert generate $DOMAIN_NAME
# But Let's Encrypt is recommended
chown prosody.prosody /var/lib/prosody/*
chmod u=r,g=,o= /var/lib/prosody/*

# Restore users, chat archives, etc
./db_restore.sh

service prosody restart

./deploy_site.sh
