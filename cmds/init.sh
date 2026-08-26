#! /bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR
USERNAME=${1:-$(whoami)}

echo "Setting up local development environment for user: $USERNAME"

# Build the fulllocal development environment
# ./build-local-dev.sh --all

# Start the local development environment
./up.sh

# install the pg cask tables and add yourself as an admin user
./argonath-dc.sh exec cask cask init-pg
./argonath-dc.sh exec cask cask -i admin  acl user-role-set $USERNAME admin

cask env set -t http -h  http://localhost:4000/cask -c dev argo-local-dev
cask env default argo-local-dev
cd ../../argonath/exec
uv run digtk auth login --cask-env argo-local-dev
cd $ROOT_DIR
cask auto-path load ../../argonath/cask/auto-path-rules.json