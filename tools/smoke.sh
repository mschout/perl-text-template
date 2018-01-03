#!/bin/sh

docker images | grep mschout/perl-dzil-mschout | awk '{print $1 ":" $2}' | sort | \
while read image
do
    echo
    echo "********** Testing in $image **********"
    echo

    docker run --rm -v $PWD:/app $image /app/tools/docker-test.sh

    if [ $? -ne 0 ]; then
        echo "********** Failed in $image **********"
        exit 1
    fi
done
