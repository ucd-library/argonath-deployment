#! /bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR
USERNAME=${1:-$(whoami)}

echo "Setting up local development environment for user: $USERNAME"

# Build the fulllocal development environment
# ./build.sh --all

# Start the local development environment
# ./up.sh

# schemas, ACLs, seed files and auto-path rules (non-interactive)
./init-services.sh $USERNAME || echo "WARNING: service init failed; are both the argonath and dc-showcase stacks up?"

# point your host cask CLI and digtk at the local stack (interactive login)
cask env set -t http -h  http://localhost:4000/cask -c dev argo-local-dev
cask env default argo-local-dev
cd ../../../argonath/exec
DIGTK_GATEWAY_URL=http://localhost:4000 uv run digtk auth login --cask-env argo-local-dev
cd $ROOT_DIR
