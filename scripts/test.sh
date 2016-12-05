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

node ./node_modules/.bin/jest
