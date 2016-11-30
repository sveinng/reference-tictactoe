#!/bin/bash

#
# Compose image from current git revision and start
#

export GIT_COMMIT=$(git rev-parse HEAD)
docker-compose -f docker-compose-env.yaml pull
docker-compose -f docker-compose-env.yaml up -d
