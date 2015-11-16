#!/bin/bash
set -e

.  ./secret/env.sh

mysqldump -uprosody -p"$MYSQL_PROSODY_PASSWORD" prosody prosody > ./secret/prosody.sql
mysqldump -uprosody -p"$MYSQL_PROSODY_PASSWORD" prosody prosodyarchive | xz -zce > ./secret/prosodyarchive.sql.xz
