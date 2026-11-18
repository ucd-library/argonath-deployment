#! /bin/bash

# Non-interactive half of init.sh: schemas, ACLs, seed files and auto-path
# rules, all run inside the containers. Safe to re-run. Used directly by the
# dc-showcase e2e suite (dc-showcase-deployment/cmds/e2e/up.sh).
#
# Usage: init-services.sh [username]

set -e

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR
USERNAME=${1:-$(whoami)}

# install the pg cask tables and add the admin users
./dc.sh exec -T cask cask init-pg
./dc.sh exec -T cask cask -i admin acl user-role-set $USERNAME admin
./dc.sh exec -T cask cask -i admin acl user-role-set dagster admin
./dc.sh exec -T cask cask -i admin acl user-role-set dcs-gateway admin

# install digtk's pg schemas: collection_registry (collection registrations,
# the queue/results store Dagster's item jobs use) and the reporting schema
# every derivative step writes to (--reporting-job-id). Run in dagster-daemon,
# which has digtk and its DIGTK_POSTGRES_* / DIGTK_REPORTING_PG_* env.
./dc.sh exec -T dagster-daemon digtk state init-pg
./dc.sh exec -T dagster-daemon digtk reporting init-db

# cask partition-key rules, loaded inside the cask container
./dc.sh cp "$ROOT_DIR/../../../argonath/cask/auto-path-rules.json" cask:/tmp/auto-path-rules.json
./dc.sh exec -T cask cask -i admin auto-path load /tmp/auto-path-rules.json

# install dc-showcase's dcf schema and gold seed files (hero banner, browse
# by images; existing files are kept). Needs the dc-showcase stack up
# (dc-showcase-deployment/cmds/local-dev/up.sh); dc.sh has no -f, so run it
# from dc-showcase's compose dir. dc-showcase-deployment is a sibling of
# argonath-deployment, three levels up from here.
DCS_DEPLOY_DIR="$ROOT_DIR/../../../dc-showcase-deployment"
(
  cd "$DCS_DEPLOY_DIR/compose/local-dev" || exit 1
  "$DCS_DEPLOY_DIR/cmds/local-dev/dc.sh" exec -T client node bin/init-db.js
  "$DCS_DEPLOY_DIR/cmds/local-dev/dc.sh" exec -T client node bin/init-cask.js
)
