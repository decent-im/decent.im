#!/bin/bash
set -e

.  ./secret/env.sh

mysqldump -uprosody -p"$MYSQL_PROSODY_PASSWORD" --lock-tables prosody | xz -zce > ./secret/whole.sql.xz
