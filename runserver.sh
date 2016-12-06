#!/bin/bash
# 
# Install project node modules

# Exit on any error - no false positives
set -e

# Set the node path
export NODE_PATH=.


# Get current rundir (where script is executed from)
RUNDIR=$(dirname $0)

# Make sure we run at project root level
[ ! $RUNDIR = "." ] && cd "$RUNDIR"

# Wait for database to open
sleep 5

# Run database migration for production environment
node_modules/.bin/db-migrate --config ./server/database.json --migrations-dir ./server/migrations up -e production

# Start the server with nodemon
nodemon run.js

exit 0

