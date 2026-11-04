#! /bin/bash

set -e

WORKER_SCALE=${1:-2}

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/../..

docker compose -f compose/local-dev/compose.yaml -p argonath up -d --scale dagster-celery-worker=$WORKER_SCALE

echo "Argonath deployment (local-dev) is up and running. Worker count: $WORKER_SCALE"
echo " - Auth Gateway URL : http://localhost:4000"
echo " - Dagster URL      : http://localhost:3000"
echo " - Cask URL         : http://localhost:3001"
echo " - Superset URL     : http://localhost:8088"
