#!/bin/bash
set -e

function user_add() {
	NAME="$1"
	PW="$2"
	DOMAIN=${3:="decent.im"}
	echo -e "$PW\n$PW" | prosodyctl adduser ${NAME}@$DOMAIN > /dev/null
}

user_add "$@"
