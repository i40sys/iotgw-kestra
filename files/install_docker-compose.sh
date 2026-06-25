#!/usr/bin/env bash

opkg update
opkg install jq curl wget

DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
FILENAME=$DOCKER_CONFIG/cli-plugins/docker-compose
#VERSION=$(curl -sL https://api.github.com/repos/docker/compose/releases/latest | jq -r ".tag_name")
VERSION=v2.29.2
URL=https://github.com/docker/compose/releases/download/$VERSION/docker-compose-linux-x86_64

mkdir -p $DOCKER_CONFIG/cli-plugins
wget $URL -O $TARGET/$FILENAME
chmod 755 $TARGET/$FILENAME
docker compose version
