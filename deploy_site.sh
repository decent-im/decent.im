#!/bin/bash
set -e

apt-get install -V -y nginx-light
cd /var/www/html
rm -rf *
wget --mirror https://decent-im.github.io || true
mv decent-im.github.io/* .
rmdir decent-im.github.io
