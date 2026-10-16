#! /bin/bash

set -e

ENVIRONMENT=$1
ARGONATH_VERSION=$2

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/..

ALLOWED_ENVIRONMENTS=("prod")

REGISTRY="us-west1-docker.pkg.dev/digital-ucdavis-edu/pub"
ARGONATH_BUILD_REGISTRY_URL="https://raw.githubusercontent.com/ucd-library/cork-build-registry/refs/heads/main/repositories/argonath.json"
PROJECT_ANDUIN_BUILD_REGISTRY_URL="https://raw.githubusercontent.com/ucd-library/cork-build-registry/refs/heads/main/repositories/project-anduin.json"

if [[ ! " ${ALLOWED_ENVIRONMENTS[@]} " =~ " ${ENVIRONMENT} " ]]; then
  echo "Error: Invalid environment. Allowed environments are: ${ALLOWED_ENVIRONMENTS[@]}"
  echo "Usage: $0 <environment> <version>"
  exit 1
fi

if [[ -z "$ARGONATH_VERSION" ]]; then
  echo "Usage: $0 <environment> <version>"
  exit 1
fi

edit() {
  ROOT=$1
  RESOURCE_TYPE=$2
  IMAGE=$3
  CONTAINER=$4
  OVERLAY=$5

  echo "Updating $ROOT resource=$RESOURCE_TYPE container=$CONTAINER image=$IMAGE overlay=$OVERLAY"

  cork-kube edit -o $OVERLAY \
    -f $RESOURCE_TYPE \
    -e "\$.spec.template.spec.containers[?(@.name==\"$CONTAINER\")].image=$IMAGE" \
    --replace \
    -- kustomize/$ROOT
}

JSON_DATA=$(curl -s $ARGONATH_BUILD_REGISTRY_URL)
ANDUIN_VERSION=$(echo $JSON_DATA | jq -r ".builds[\"$ARGONATH_VERSION\"][\"project-anduin\"]")
CASKFS_VERSION=$(echo $JSON_DATA | jq -r ".builds[\"$ARGONATH_VERSION\"][\"caskfs\"]")
JSON_DATA=$(curl -s $PROJECT_ANDUIN_BUILD_REGISTRY_URL)
POSTGRES_VERSION=$(echo $JSON_DATA | jq -r ".builds[\"$ANDUIN_VERSION\"].postgres")

echo "Updating Argonath to version: $ARGONATH_VERSION (Anduin: $ANDUIN_VERSION, CaskFS: $CASKFS_VERSION, Postgres: $POSTGRES_VERSION)"

edit anduin-gateway deployment "$REGISTRY/argonath-gateway:$ARGONATH_VERSION" service $ENVIRONMENT
edit cask deployment "$REGISTRY/argonath-cask:$ARGONATH_VERSION" service $ENVIRONMENT
edit dagster/dagster-ui deployment "$REGISTRY/argonath-dagster:$ARGONATH_VERSION" service $ENVIRONMENT
edit dagster/dagster-daemon deployment "$REGISTRY/argonath-dagster:$ARGONATH_VERSION" service $ENVIRONMENT
edit dagster/dagster-celery-worker deployment "$REGISTRY/argonath-dagster:$ARGONATH_VERSION" service $ENVIRONMENT
edit superset statefulset "$REGISTRY/argonath-superset:$ARGONATH_VERSION" service $ENVIRONMENT
edit postgres statefulset "$REGISTRY/anduin-pg:$POSTGRES_VERSION" database $ENVIRONMENT
edit dagster-postgres statefulset "$REGISTRY/anduin-pg:$POSTGRES_VERSION" database $ENVIRONMENT

echo ""
read -p "Would you like to commit the changes to git? (y/n): " COMMIT_CHANGES

if [[ "$COMMIT_CHANGES" == "y" ]]; then
  echo -e "\nCommitting changes to git"

  git add --all
  git commit -m "Updated $ENVIRONMENT to version $ARGONATH_VERSION (Anduin: $ANDUIN_VERSION, CaskFS: $CASKFS_VERSION, Postgres: $POSTGRES_VERSION)"
  git pull
  git push
else
  echo ""
  echo "Changes not committed to git."
fi

echo ""
echo "Done updating deployment $ENVIRONMENT to version $ARGONATH_VERSION"
