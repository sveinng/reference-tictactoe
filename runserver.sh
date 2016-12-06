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

# Wait for database to open
sleep 5

# Run database migration for production environment
db-migrate --config ./server/database.json --migrations-dir ./server/migrations up -e production

# Start the server with nodemon
nodemon run.js

exit 0

