#! /bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR
USERNAME=${1:-$(whoami)}

echo "Setting up local development environment for user: $USERNAME"

# Build the fulllocal development environment
# ./build-local-dev.sh --all

# Start the local development environment
# ./up.sh

# install the pg cask tables and add yourself as an admin user
./argonath-dc.sh exec cask cask init-pg
./argonath-dc.sh exec cask cask -i admin  acl user-role-set $USERNAME admin
./argonath-dc.sh exec cask cask -i admin  acl user-role-set dagster admin
./argonath-dc.sh exec cask cask -i admin  acl user-role-set dcs-gateway admin

# install digtk's pg schemas: the collection registry (argonath schema), the
# collection_state queue/results store Dagster's item jobs use, and the
# reporting schema every derivative step writes to (--reporting-job-id). All
# are safe to re-run. Run in dagster-daemon, which has digtk and its
# DIGTK_POSTGRES_* / DIGTK_REPORTING_PG_* env.
./argonath-dc.sh exec dagster-daemon digtk collection init-pg
./argonath-dc.sh exec dagster-daemon digtk state init-pg
./argonath-dc.sh exec dagster-daemon digtk reporting init-db

# install dc-showcase's dcf schema and gold seed files (hero banner, browse
# by images; existing files are kept). Safe to re-run. Needs the dc-showcase
# stack up (dc-showcase-deployment/cmds/local-dev/up.sh); dc.sh has no -f,
# so run it from dc-showcase's compose dir.
cd ../../dc-showcase-deployment/compose/local-dev
../../cmds/local-dev/dc.sh exec client node bin/init-db.js
../../cmds/local-dev/dc.sh exec client node bin/init-cask.js
cd $ROOT_DIR

cask env set -t http -h  http://localhost:4000/cask -c dev argo-local-dev
cask env default argo-local-dev
cd ../../argonath/exec
DIGTK_GATEWAY_URL=http://localhost:4000 uv run digtk auth login --cask-env argo-local-dev
cd $ROOT_DIR
cask auto-path load ../../argonath/cask/auto-path-rules.json