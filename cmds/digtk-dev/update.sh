#! /bin/bash

set -e

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/../..

echo "Pulling argonath-deployment..."
git pull

echo "Pulling .env from digtk-dev-dot-env secret..."
gcloud secrets versions access latest \
  --secret=digtk-dev-dot-env \
  --project=argonath-508815 \
  > compose/digtk-dev/.env

echo "Pulling images..."
docker compose -f compose/digtk-dev/compose.yaml -p digtk-dev pull

echo "Starting stack so schema/cask init can run..."
docker compose -f compose/digtk-dev/compose.yaml -p digtk-dev up -d

cd $ROOT_DIR

USERNAME=$(whoami)

# install the pg cask tables and add yourself as an admin user - safe to re-run
./dc.sh exec cask cask init-pg
./dc.sh exec cask cask -i admin acl user-role-set $USERNAME admin
./dc.sh exec cask cask -i admin acl user-role-set dagster admin

# install digtk's pg schemas: the collection registry (argonath schema), the
# collection_state queue/results store Dagster's item jobs use, and the
# reporting schema every derivative step writes to (--reporting-job-id). All
# are safe to re-run. Run in dagster-daemon, which has digtk and its
# DIGTK_POSTGRES_* / DIGTK_REPORTING_PG_* env.
./dc.sh exec dagster-daemon digtk collection init-pg
./dc.sh exec dagster-daemon digtk state init-pg
./dc.sh exec dagster-daemon digtk reporting init-db

echo "digtk-dev is up to date."
