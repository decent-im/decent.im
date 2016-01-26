#!/bin/bash

set -e

cd `dirname $0`

echo deb http://packages.prosody.im/debian `lsb_release -sc` main > /etc/apt/sources.list.d/prosody.list
wget https://prosody.im/files/prosody-debian-packages.key -O- | sudo apt-key add -
apt-get update
apt-get install -V -y prosody-0.10 lua-dbi-mysql lua-zlib libevent-2.0 lua-event

MYSQL_PROSODY_PASSWORD="`pwgen 16 1`"
source ./secret/env.sh || source ./secret_env.sh.sample
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
	prosody-modules/mod_csi \
	prosody-modules/mod_throttle_presence \
	prosody-modules/mod_filter_chatstates \
	prosody-modules/mod_smacks \
	/usr/lib/prosody/modules/

# deploy mod_turncredentials
apt-get install -V -y coturn
echo 'TURNSERVER_ENABLED=1' > /etc/default/coturn
service coturn restart
wget https://github.com/otalk/mod_turncredentials/raw/master/mod_turncredentials.lua \
	     -O /usr/lib/prosody/modules/mod_turncredentials.lua

# Create MySQL DB
echo "
mysql-server-5.6 mysql-server/root_password password $MYSQL_ROOT_PASSWORD
mysql-server-5.6 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD
" | debconf-set-selections
apt-get install -V -y mysql-server

if echo 'create database prosody;' | mysql -uroot -p"$MYSQL_ROOT_PASSWORD"
then
	echo '
	create user `prosody`@`localhost` identified by "'$MYSQL_PROSODY_PASSWORD'";
	grant all on `prosody`.* to `prosody`@`localhost`;
	' | mysql -uroot -p"$MYSQL_ROOT_PASSWORD"

	# Restore users, chat archives, etc
	./db_restore.sh
fi

# Deploy or issue certs
# Certs are deployed from secret/files/var/lib/prosody
# Alternatively, you can generate them manually and interactively by command
# prosodyctl cert generate $DOMAIN_NAME
# But Let's Encrypt is recommended
chown prosody.prosody /var/lib/prosody/*
chmod u=r,g=,o= /var/lib/prosody/*

service prosody restart

./deploy_site.sh

pushd /var/www/html
git clone https://github.com/jappix/jappix.git
mkdir jappix/store/conf
cp /etc/jabber/jappix/*.xml jappix/store/conf
cat /etc/jabber/jappix/hosts.xml.template | sed \
	-e "s/%%DOMAIN_NAME%%/$DOMAIN_NAME/g" \
	> jappix/store/conf/hosts.xml

git clone https://github.com/jsxc/jsxc.git
for x in `grep 'url:' jsxc/example -RnI -l`
do
	sed -i "$x" \
	-e "s|url: '/http-bind/'|url: 'https://$DOMAIN_NAME:5281/http-bind/'|" \
	-e "s|localhost|$DOMAIN_NAME|" \
	;
done

popd # /var/www/html

if [[ -e ./secret/jabber_backup.pub ]]
then
	gpg --import ./secret/jabber_backup.pub
	# Save MySQL password in easily parsable way for regular backup job
	env | egrep 'MYSQL_PROSODY_PASSWORD|BACKUP_PGP_KEYID' > /etc/jabber/backup.cfg
else
	# Disable backing up cleanly
	sed -i -e 's/^/#/' /etc/cron.d/jabber_backup
fi

apt-get install -y unattended-upgrades

./checks.sh
