#! /bin/bash

set -e

ALL=false
VERSION="main"

for arg in "$@"; do
  case $arg in
    --all)
      ALL=true
      ;;
    *)
      VERSION=$arg
      ;;
  esac
done

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/../..

TARGET_REGISTRY=us-west1-docker.pkg.dev/argonath-508815/argo-dev
TARGET_TAG=dev

TMP_ENV="$(mktemp)"
trap 'rm -f "$TMP_ENV"' EXIT

cork-kube build exec \
  -p project-anduin \
  -v main \
  -o dev \
  --local-dev-registry ${TARGET_REGISTRY} \
  --depth ALL \
  --set-env $TMP_ENV

cork-kube build exec \
  -p caskfs \
  -v main \
  -o dev \
  --local-dev-registry ${TARGET_REGISTRY} \
  --set-env $TMP_ENV \
  --depth ALL

cork-kube build exec \
  -p argonath \
  -v $VERSION \
  --local-dev-registry ${TARGET_REGISTRY} \
  --set-env $TMP_ENV \
  -o dev

# cork-kube build exec's dev build only tags images locally, it doesn't push -
# re-tag and push each freshly-built image to the shared argo-dev dev registry
# so other digtk developers can pull it with update.sh.
echo ""
echo "Pushing built images to $TARGET_REGISTRY ..."

while IFS='=' read -r VAR_NAME LOCAL_IMAGE; do
  [[ "$VAR_NAME" == IMAGE_* ]] || continue
  [[ -z "$LOCAL_IMAGE" ]] && continue

  IMAGE_NAME="$(basename "$LOCAL_IMAGE" | cut -d: -f1)"
  TARGET_IMAGE="$TARGET_REGISTRY/$IMAGE_NAME:$TARGET_TAG"

  echo " - $LOCAL_IMAGE -> $TARGET_IMAGE"
  docker tag "$LOCAL_IMAGE" "$TARGET_IMAGE"
  docker push "$TARGET_IMAGE"
done < "$TMP_ENV"

echo "Done."
