#!/bin/bash

docker build --tag grayles-modpack-update:latest .
docker run --rm -v $(pwd)/mods:/mods -ti grayles-modpack-update