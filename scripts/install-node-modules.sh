#!/bin/bash
# 
# Install project node modules

# Exit on any error - no false positives
set -e

# Get current rundir (where script is executed from)
RUNDIR=$(dirname $0)

# If script is executed in the script directory - move up one level
[ $RUNDIR = "." ] && cd ..

npm install
#yarn install

cd client
# NPM uses way to much ram and cpu - lets limit for our tiny CI server
/usr/bin/node \
  --max_semi_space_size=1 \
  --max_old_space_size=198 \
  --max_executable_size=148 \
  /usr/bin/npm install

echo "*** Node modules installed"
exit 0
