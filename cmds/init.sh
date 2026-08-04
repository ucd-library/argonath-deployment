#! /bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR

# Build the fulllocal development environment
./build-local-dev.sh --all

# Start the local development environment
./up.sh

# install the pg cask tables
./argonath-dc.sh exec cask cask init-pg

cask env set -t http -h  http://localhost:3001/cask -c dev argo-local-dev
cask env default argo-local-dev
cask auto-path load ../../argonath/cask/auto-path-rules.json