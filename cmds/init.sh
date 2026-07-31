#! /bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR

# Build the fulllocal development environment
./build-local-dev.sh --all

# Start the local development environment
./up.sh

# install the pg cask tables
./argonath-dc.sh exec cask cask init-pg