#! /bin/bash

set -e

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO_ROOT="$ROOT_DIR/../.."
SIBLING_ARGONATH="$REPO_ROOT/../argonath"

cd "$REPO_ROOT"

docker compose -f compose/digtk-dev/compose.yaml -p digtk-dev up -d

echo "digtk-dev deployment is up and running."
echo " - Auth Gateway URL : http://localhost:4000"

cask env set -t http -h http://localhost:4000/cask -c dev digtk-dev
cask env default digtk-dev

cd "$SIBLING_ARGONATH/exec"
DIGTK_GATEWAY_URL=http://localhost:4000 uv run digtk auth login --cask-env digtk-dev
