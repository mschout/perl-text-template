#!/bin/sh

git config --global user.name "TravisCI"
git config --global user.email $HOSTNAME":not-for-mail@travis-ci.org"

cd /app

dzil test
