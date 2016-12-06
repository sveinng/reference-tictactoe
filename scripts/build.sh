#!/bin/bash
# 
# Install project node modules

# Exit on any error - no false positives
set -e

# Set the node path
export NODE_PATH=.


# Get current rundir (where script is executed from)
RUNDIR=$(dirname $0)

# If script is executed in the script directory - move up one level and work from project root
[ $RUNDIR = "." ] && cd ..

# Delete old build directory if it is lingering around
[ -d ./build ] && rm -r ./build

echo "*** Build dir cleaned"

# Re-create build dir
mkdir -p build/client/src

# Build client part
cd ./client
export NODE_PATH=./src/
node_modules/.bin/react-scripts build
cd ..

# Copy artifacts to build dir
mv client/build build/static
cp -R server build/server
cp -r client/src/common build/client/src
cp run.js build
cp runserver.sh build
