#!/bin/bash

docker build --tag grayles-modpack-update:latest .
ex=$(docker ps -a | grep grayles-plus-update)
if [ "$ex" == "" ]; then
    docker run -v $(pwd)/mods:/mods -ti --name grayles-plus-update grayles-modpack-update perl ./load-mods.pl
else
    docker start -ai grayles-plus-update
fi
