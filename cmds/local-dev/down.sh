#! /bin/bash

OPTION=${1:-''}

docker compose -f compose/local-dev/compose.yaml -p argonath down $OPTION
