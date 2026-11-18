#! /bin/bash

set -e

# Usage: up.sh [worker-count] [--e2e]
#   --e2e  layer compose.e2e.yaml (fast sensors, public-showcase-dev tags)
WORKER_SCALE=2
COMPOSE_FILES="-f compose/local-dev/compose.yaml"
for arg in "$@"; do
  case $arg in
    --e2e) COMPOSE_FILES="$COMPOSE_FILES -f compose/local-dev/compose.e2e.yaml" ;;
    *) WORKER_SCALE=$arg ;;
  esac
done

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/../..

docker compose $COMPOSE_FILES -p ${ARGONATH_COMPOSE_PROJECT:-argonath} up -d --scale dagster-celery-worker=$WORKER_SCALE

echo "Argonath deployment (local-dev, project ${ARGONATH_COMPOSE_PROJECT:-argonath}) is up and running. Worker count: $WORKER_SCALE"
echo " - Auth Gateway URL : http://localhost:4000"
echo " - Dagster URL      : http://localhost:3000"
echo " - Cask URL         : http://localhost:3001"
echo " - Superset URL     : http://localhost:8088"
