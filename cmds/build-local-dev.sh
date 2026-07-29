
#! /bin/bash
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
cd $ROOT_DIR/..

ENV_FILE=./compose/local-dev/.env

if [[ "$ALL" == true ]]; then
  cork-kube build exec \
    -p project-anduin \
    -v main \
    -o sandbox \
    --depth ALL \
    --set-env $ENV_FILE

  cork-kube build exec \
    -p caskfs \
    -v main \
    -o sandbox \
    --set-env $ENV_FILE \
    --depth ALL
fi

cork-kube build exec \
  -p argonath \
  -v $VERSION \
  --set-env $ENV_FILE \
  -o sandbox