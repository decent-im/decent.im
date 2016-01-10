#!/bin/bash
set -e

source /etc/jabber/backup.cfg

# Take backup of prosody table (main) - users, rosters etc.
# Encrypt it with dedicated OpenPGP key (only public key is deployed)
mysqldump -uprosody -p"$MYSQL_PROSODY_PASSWORD" prosody prosody \
	| xz -zce \
	| gpg --encrypt --recipient $BACKUP_PGP_KEYID \
	> /root/prosody.sql.xz.gpg

# Send to admin
# TODO FIXME Gmail doesn't take it from `mail`
