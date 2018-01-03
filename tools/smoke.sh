#!/bin/sh

docker images | grep mschout/perl-dzil-mschout | awk '{print $1 ":" $2}' | while read image
do
    docker run --rm -v $PWD:/app $image /app/tools/docker-test.sh
done
