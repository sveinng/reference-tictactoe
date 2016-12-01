#!/bin/bash

#
# Compose image from current git revision and start
#

cd /home/ubuntu/
export GIT_COMMIT=$(git ls-remote https://github.com/sveinng/reference-tictactoe HEAD | cut -f 1)

docker-compose -f docker-compose-env.yaml stop

