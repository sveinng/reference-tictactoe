#!/bin/bash


# Exit on any error - no false positives
set -e

# Get current rundir (where script is executed from)
RUNDIR=$(dirname $0)

# If script is executed in the script directory - move up one level and work from project root
[ $RUNDIR = "." ] && cd ..


# Remove and recreate the dist directory
echo Cleaning...
rm -rf ./dist
mkdir -p dist/static

# If GIT_COMMIT environment variable is not set - get the HEAD revision from Github and remote origin and export as env variables
if [ -z "$GIT_COMMIT" ]; then
  export GIT_COMMIT=$(git rev-parse HEAD)
  export GIT_URL=$(git config --get remote.origin.url)
fi


# Not using https origin - so https url is created from git url
export GITHUB_URL=$(echo $GIT_URL awk -F\: '{print "https://github.com/" $2}' | rev | cut -c 5- | rev)



# Lets comment this out for now - builds are scripted through Jenkins
#
# Run the build script
#echo Building app
#npm run build

# If build script exit status is anything else than zero - assume build has failed and exit
#rc=$?
#if [[ $rc != 0 ]] ; then
#    echo "Npm build failed with exit code " $rc
#    exit $rc
#fi


# Write the git revision to a githash.txt file in the build directory
cat > ./build/githash.txt <<_EOF_
$GIT_COMMIT
_EOF_

# Create a version.html document containing links to the Git repo
cat > ./build/static/version.html << _EOF_
<!doctype html>
<head>
   <title>App version information</title>
</head>
<body>
   <span>Origin:</span> <span>$GITHUB_URL</span>
   <span>Revision:</span> <span>$GIT_COMMIT</span>
   <p>
   <div><a href="$GITHUB_URL/commits/$GIT_COMMIT">History of current version</a></div>
</body>
_EOF_


# Copy files to dist directory to create the distribution from
cp ./Dockerfile ./dist/
cp package.json ./dist/
cp -r ./build ./dist/

# Prepare Yarn - binary - lock and cache
# If yarn.lock or .yarn-cache.tgz do not exists - create empty ones
# If yarn-v0.17.9.tar.gz does not exists in the project root directory - wget version 0.17.9
[ ! -f yarn.lock ] && touch yarn.lock
[ ! -f .yarn-cache.tgz ] && tar cvzf .yarn-cache.tgz --files-from /dev/null
[ ! -f yarn-v0.17.9.tar.gz ] && wget https://github.com/yarnpkg/yarn/releases/download/v0.17.9/yarn-v0.17.9.tar.gz
# Copy these bad boys to dist directory as well
cp yarn.lock .yarn-cache.tgz yarn-v0.17.9.tar.gz ./dist/


cd dist
echo Building docker image

# Build docker image and tag it with the current git revision number
docker build -t sveinn/tictactoe:$GIT_COMMIT .
rc=$?
if [[ $rc != 0 ]] ; then
    echo "Docker build failed " $rc
    exit $rc
fi

# Push the newly successfully build image to hub.docker.com
docker push sveinn/tictactoe:$GIT_COMMIT
rc=$?
if [[ $rc != 0 ]] ; then
    echo "Docker push failed " $rc
    exit $rc
fi

# Check if the new image can be found on Docker hub
# Use curl to docker hub for portability - this way test can be run from anywhere
echo Verify Docker image is available on Docker hub

COUNT=0
curl -si https://registry.hub.docker.com/v2/repositories/sveinn/tictactoe/tags/$GIT_COMMIT/|grep "200 OK" > /dev/null 2>&1

if [ $? -ne 0 ] ; then
  echo Docker image not found on Docker hub after push
  if [ $COUNT -gt 5 ] ; then
    echo Giving up
    exit 1
  fi
  sleep 5
  let COUNT=$COUNT+1
  curl -si https://registry.hub.docker.com/v2/repositories/sveinn/tictactoe/tags/$GIT_COMMIT/|grep "200 OK" > /dev/null 2>&1
fi


echo Refreshing Yarn lock and cache
cd ../

# Extract yarn.lock from newly built image and compare to our current yarn.lock
# If yarn.lock has changed we use the most recent version from the docker image
# and refresh the yarn cache as well.

docker run --rm --entrypoint cat sveinn/tictactoe:$GIT_COMMIT /tmp/yarn.lock > /tmp/yarn.lock
if ! diff -q yarn.lock /tmp/yarn.lock > /dev/null  2>&1; then
  echo "Saving Yarn cache"
  docker run --rm --entrypoint tar sveinn/tictactoe:$GIT_COMMIT czf - /root/.cache/yarn/ > .yarn-cache.tgz
  echo "Saving yarn.lock"
  cp /tmp/yarn.lock yarn.lock
fi

# Create docker-compose file for this specific build and keep in the compose directory
echo Create docker-compose for $GIT_COMMIT
[ ! -d compose ] && mkdir compose
sed s/sveinn\\/tictactoe/sveinn\\/tictactoe:$GIT_COMMIT/g docker-compose.yaml > compose/docker-compose-$GIT_COMMIT.yaml

echo "Done"
