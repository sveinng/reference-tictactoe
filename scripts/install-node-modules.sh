#!/bin/bash
# 
# Install project node modules

# Exit on any error - no false positives
set -e

# Get current rundir (where script is executed from)
RUNDIR=$(dirname $0)

# If script is executed in the script directory - move up one level
[ $RUNDIR = "." ] && cd ..

#npm install
yarn install --production

cd client
npm install

echo "*** Node modules installed"
exit 0
