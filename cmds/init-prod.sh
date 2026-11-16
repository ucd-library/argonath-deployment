#! /bin/bash

# Initialize the prod k8s environment: PG schemas, ACL roles,
# dc-showcase seed data and cask auto-path rules. Run from a
# laptop; commands execute in the running pods via kubectl exec.
# All steps are idempotent and safe to re-run.

set -e

ENVIRONMENT="prod"
USERNAME=$1

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/..

NAMESPACE="argonath-prod"
RULES_FILE="$ROOT_DIR/../../argonath/cask/auto-path-rules.json"

if [[ -z "$USERNAME" ]]; then
  echo "Error: username (keycloak id) is required to grant admin role"
  echo "Usage: $0 <username>"
  exit 1
fi

if [[ ! -f "$RULES_FILE" ]]; then
  echo "Error: auto-path rules not found at $RULES_FILE"
  exit 1
fi

read -p "Run init against $ENVIRONMENT (namespace $NAMESPACE) with admin user $USERNAME? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "Aborted."
  exit 0
fi

cork-kube activate $ENVIRONMENT

# exec command in a deployment's service container
kexec() {
  kubectl -n "$NAMESPACE" exec -i "deploy/$1" -c service -- "${@:2}"
}

echo -e "\nInstalling cask pg tables"
kexec cask cask init-pg

echo -e "\nSetting cask admin roles"
for USER in "$USERNAME" dagster dcs-gateway; do
  kexec cask cask -i admin acl user-role-set "$USER" admin
done

# collection_registry and reporting schemas
echo -e "\nInstalling digtk pg schemas"
kexec dagster-daemon digtk state init-pg
kexec dagster-daemon digtk reporting init-db

# dc-showcase dcf schema and gold seed files
echo -e "\nInitializing dc-showcase"
kexec dcs-client node bin/init-db.js \
  && kexec dcs-client node bin/init-cask.js \
  || echo "WARNING: dc-showcase init failed; is dcs-client deployed?"

# copy rules into pod, then load
echo -e "\nLoading cask auto-path rules"
kexec cask sh -c 'cat > /tmp/auto-path-rules.json && cask -i admin auto-path load /tmp/auto-path-rules.json' < "$RULES_FILE"

echo ""
echo "Done initializing $ENVIRONMENT"
