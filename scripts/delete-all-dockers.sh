#!/bin/bash

# Delete all containers
docker rm $(docker ps -a -q)

# Delete all images
docker rmi $(docker images -q)

# Should always return 0 - even if nothing was found to delete
exit 0
