#! /bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/../..

docker compose -f compose/digtk-dev/compose.yaml --env-file compose/digtk-dev/.env.default -p digtk-dev down "$@"
