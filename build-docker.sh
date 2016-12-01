#!/bin/bash

echo Cleaning...
rm -rf ./dist
mkdir -p dist/static

if [ -z "$GIT_COMMIT" ]; then
  export GIT_COMMIT=$(git rev-parse HEAD)
  export GIT_URL=$(git config --get remote.origin.url)
fi

# Remove .git from url in order to get https link to repo (assumes https url for GitHub)
#export GITHUB_URL=$(echo $GIT_URL | rev | cut -c 5- | rev)

# Not using https origin - so diffrent fix
export GITHUB_URL=$(echo $GIT_URL awk -F\: '{print "https://github.com/" $2}' | rev | cut -c 5- | rev)



echo Building app
npm run build

rc=$?
if [[ $rc != 0 ]] ; then
    echo "Npm build failed with exit code " $rc
    exit $rc
fi


cat > ./build/githash.txt <<_EOF_
$GIT_COMMIT
_EOF_

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


cp ./Dockerfile ./dist/
cp package.json ./dist/
cp -r ./build ./dist/

# Prepare Yarn - binary - lock and cache
[ ! -f yarn.lock ] && touch yarn.lock
[ ! -f .yarn-cache.tgz ] && tar cvzf .yarn-cache.tgz --files-from /dev/null
[ ! -f yarn-v0.17.9.tar.gz ] && wget https://github.com/yarnpkg/yarn/releases/download/v0.17.9/yarn-v0.17.9.tar.gz
cp yarn.lock .yarn-cache.tgz yarn-v0.17.9.tar.gz ./dist/

cd dist
echo Building docker image

docker build -t sveinn/tictactoe:$GIT_COMMIT .
rc=$?
if [[ $rc != 0 ]] ; then
    echo "Docker build failed " $rc
    exit $rc
fi

docker push sveinn/tictactoe:$GIT_COMMIT
rc=$?
if [[ $rc != 0 ]] ; then
    echo "Docker push failed " $rc
    exit $rc
fi


echo Refreshing Yarn lock and cache
cd ../
docker run --rm --entrypoint cat sveinn/tictactoe:$GIT_COMMIT /tmp/yarn.lock > /tmp/yarn.lock
if ! diff -q yarn.lock /tmp/yarn.lock > /dev/null  2>&1; then
  echo "Saving Yarn cache"
  docker run --rm --entrypoint tar sveinn/tictactoe:$GIT_COMMIT czf - /root/.cache/yarn/ > .yarn-cache.tgz
  echo "Saving yarn.lock"
  cp /tmp/yarn.lock yarn.lock
fi

# Create docker-compose settings for this specific build
echo Create docker-compose for $GIT_COMMIT
[ ! -d compose ] && mkdir compose
sed s/sveinn\\/tictactoe/sveinn\\/tictactoe:$GIT_COMMIT/g docker-compose.yaml > compose/docker-compose-$GIT_COMMIT.yaml

# Update AWS bootstrap GIT revision tag
echo Update aws_bootstrap to include current git revision tag
sed s/GIT_COMMIT_PLACEHOLDER/$GIT_COMMIT/g provisioning/aws_bootstrap.template > provisioning/aws_bootstrap.sh

echo "Done"
