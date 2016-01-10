#!/bin/bash
set -e

source `dirname $0`/env.sh || source `dirname $0`/env.sh.sample

apt-get install -V -y nginx-light
cd /var/www/html
rm -rf *
wget --mirror https://$GITHUB_PAGES_URL || true
mv $GITHUB_PAGES_URL/* .
rmdir $GITHUB_PAGES_URL
