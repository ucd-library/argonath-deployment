#! /bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/..

ENV_FILE="compose/local-dev/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Creating $ENV_FILE from .env.example"
    cp compose/local-dev/.env.example "$ENV_FILE"
else
    echo "$ENV_FILE already exists."
fi

if ! grep -q "SUPERSET_SECRET_KEY=.\+" "$ENV_FILE"; then
    echo "Generating SUPERSET_SECRET_KEY..."
    SECRET_KEY=$(openssl rand -base64 42)
    sed -i.bak "s|SUPERSET_SECRET_KEY=|SUPERSET_SECRET_KEY=$SECRET_KEY|" "$ENV_FILE" && rm "$ENV_FILE.bak"
else
    echo "SUPERSET_SECRET_KEY already set in $ENV_FILE"
fi

echo ""
echo "Still need to fill in by hand in $ENV_FILE:"
echo " - SAMWISE_API_KEY"
echo " - OIDC_CLIENT_SECRET"
echo " - JWT_SECRET"
echo " - IMAGE_ARGONATH_* image tags (no cork-build exists for argonath yet)"
