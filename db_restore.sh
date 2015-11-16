#!/bin/bash
set -e

.  ./secret/env.sh

for x in ./secret/*.sql
do
	cat $x | mysql -uprosody -p"$MYSQL_PROSODY_PASSWORD"
done

for x in ./secret/*.sql.gz
do
	gunzip -c $x | mysql -uprosody -p"$MYSQL_PROSODY_PASSWORD"
done

for x in ./secret/*.sql.xz
do
	xz -dc $x | mysql -uprosody -p"$MYSQL_PROSODY_PASSWORD"
done
