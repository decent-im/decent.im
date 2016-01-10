#!/bin/bash

set -e

cd `dirname $0`

source ./env.sh || source ./env.sh.sample

for x in `egrep -o '([a-z0-9]+[.]%%DOMAIN_NAME%%)' files/etc/prosody/prosody.cfg.lua.template | sed "s/%%DOMAIN_NAME%%/$DOMAIN_NAME/"`
do
	if ! ping -c 1 -W 1 $x
	then
		echo "[ERROR] $x is not reachable"
	fi
done
