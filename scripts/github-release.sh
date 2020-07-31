#!/bin/bash

LATEST_RELEASE="v20.07.0"

update_latest_release() {
  response=$(curl --write-out "%{http_code}" --silent --output /tmp/latest-release.txt \
  https://api.github.com/repos/dgraph-io/dgraph/releases/tags/$LATEST_RELEASE)

  if [ "$response" == "200" ]; then
    mv /tmp/latest-release.txt latest-release.txt
  else
    echo -e "Got error from Github API"
  fi
}

while true;
do
  echo -e "$(date) Getting latest release information from Github."
  update_latest_release
  sleep 120
done;
