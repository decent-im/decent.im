#!/bin/bash

set -e

cd `dirname $0`

echo deb http://packages.prosody.im/debian `lsb_release -sc` main > /etc/apt/sources.list.d/prosody.list
wget https://prosody.im/files/prosody-debian-packages.key -O- | sudo apt-key add -
apt-get update
apt-get install -V -y prosody-0.10 lua-dbi-mysql lua-zlib libevent-2.0 lua-event

source ./secret/env.sh || source ./secret_env.sh.sample
# TODO random MYSQL_PROSODY_PASSWORD

source ./env.sh || source ./env.sh.sample

echo "$DOMAIN_NAME" > /etc/hostname

# Deploy all tracked files
rsync -av ./files/ /
# Deploy all tracked files from secret repository
rsync -av ./secret/files/ / || true

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

# TODO Don't drop&recreate if exists
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

if [[ -e ./secret/jabber_backup.pub ]]
then
	gpg --import ./secret/jabber_backup.pub
	# Save MySQL password in easily parsable way for regular backup job
	env | egrep 'MYSQL_PROSODY_PASSWORD|BACKUP_PGP_KEYID' > /etc/jabber/backup.cfg
else
	# Disable backing up cleanly
	sed -i -e 's/^/#/' /etc/cron.d/jabber_backup
fi
