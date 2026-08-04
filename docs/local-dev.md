# Local Development

## First-time setup

See [prerequisites](prerequisites.md) for what you need installed.

1. Clone the repos this stack builds from, all repos should share a common parent directory with
   `argonath-deployment`:
   - [argonath](https://github.com/ucd-library/argonath) itself
   - [project-anduin](https://github.com/ucd-library/project-anduin) (dagster,
     superset, auth-gateway)
   - [caskfs](https://github.com/ucd-library/caskfs)

2. Register all three as local repos with cork-kube, so `cork-kube build`
   uses your local checkout instead of cloning from GitHub:
   ```sh
   cork-kube build register-local-repo /path/to/argonath
   cork-kube build register-local-repo /path/to/project-anduin
   cork-kube build register-local-repo /path/to/caskfs
   ```
   (Run `cork-kube build show-local-repos` to confirm what's already
   registered.)

3. Copy the env template:
   ```sh
   cp compose/local-dev/.env.example compose/local-dev/.env
   ```

4. Fill in the secrets `.env.example` leaves blank:
   - `OIDC_CLIENT_SECRET` — pull from GCP Secret Manager:
     ```sh
     gcloud secrets versions access latest \
       --secret=argonath-keycloak-client-secret \
       --project=digital-ucdavis-edu
     ```
   - `SAMWISE_API_KEY` — log into [Samwise](https://samwise.library.ucdavis.edu)
     (it's an Open WebUI instance) and generate an API key:
     - click your profile icon (bottom-left) → **Settings**
     - **Account** tab → **API Keys** section
     - **Create new secret key** (or **Show** if one already exists)
     - copy the value and paste it in
   - `JWT_SECRET` / `SUPERSET_SECRET_KEY` — any dev-only random value works
     (e.g. `openssl rand -base64 42`).

5. Run the init script:
   ```sh
   ./cmds/init.sh
   ```
   This does three things in order:
   1. `build-local-dev.sh --all` — builds every image the stack needs
      (project-anduin and caskfs, each with `--depth ALL` so their own
      dependencies get built too, then argonath itself), tagging them
      `sandbox` and writing the resulting `IMAGE_*` vars into
      `compose/local-dev/.env`.
   2. `up.sh` — brings the whole compose stack up.
   3. `argonath-dc.sh exec cask cask init-pg` — initializes the CaskFS schema
      in postgres.

   It's a one-time (or occasional full-rebuild) step — day to day you'll use
   `up.sh`/`down.sh` directly (below).

## Bring the stack up

```sh
./cmds/up.sh
```

| Service        | URL                     |
|----------------|--------------------------|
| Auth Gateway   | http://localhost:4000    |
| Dagster UI     | http://localhost:3000    |
| Cask           | http://localhost:3001    |
| Superset       | http://localhost:8088    |

`./cmds/down.sh` to tear it down.


## Interacting with the running stack

`./cmds/argonath-dc.sh` is a thin wrapper around `docker compose -p argonath`,
scoped to `compose/local-dev/compose.yaml` — any `docker compose` subcommand
works:

```sh
# open a shell in a service's container
./cmds/argonath-dc.sh exec dagster-celery-worker bash

# list running containers for this stack
./cmds/argonath-dc.sh ps

# tail logs for one service
./cmds/argonath-dc.sh logs -f dagster-daemon
```

Service names are the keys under `services:` in `compose/local-dev/compose.yaml`
(`postgres`, `dagster-ui`, `dagster-daemon`, `dagster-celery-worker`, `cask`,
`superset`, `anduin-gateway`, `rabbitmq`).

## Iterating on argonath code

Rebuild just the argonath image (not project-anduin/caskfs — those are built
once via `--all` and don't need rebuilding unless you're changing their
code too):

```sh
./cmds/build-local-dev.sh
./cmds/down.sh
./cmds/up.sh
```

`build-local-dev.sh` with no args runs `cork-kube build exec -p argonath`
against `main` (pass a branch/tag as the first arg to build something else),
`--depth 1` by default, so it only rebuilds argonath's own image(s) and
rewrites their `IMAGE_ARGONATH_*` tags in `.env`. `down.sh`/`up.sh` then
recreate containers against the new tag.

Note that most of argonath's own code doesn't actually require a rebuild to
pick up changes — `compose.yaml` bind-mounts `argonath/dagster/lib`,
`celery_config.yaml`, `workspace.yaml`, `dagster.yaml`, and `defs.py`
straight from your working copy into the `dagster-ui`/`dagster-daemon`/
`dagster-celery-worker` containers, and `argonath/exec/dc` into the celery
worker as well. Editing those files takes effect on container
restart (`down.sh` + `up.sh`), no rebuild needed. A rebuild is only required
when the Docker image itself changes — new dependencies, Dockerfile changes,
etc. project-anduin's and caskfs's own source (dagster/superset/auth-gateway
internals, caskfs) is not live-mounted, since those run from their built
images.


## Hard reset

To wipe everything — containers and named volumes (postgres data, caskfs
data, superset home, rabbitmq data) — and start from scratch:

```sh
./cmds/argonath-dc.sh down -v
```

You'll need to re-run the Superset one-time init and `cask init-pg` (either
by hand, or by re-running `./cmds/init.sh`) after this.

Note: `compose/local-dev/initdb/*.sql` (which creates the `dagster` and
`superset` databases, and the `auth_gateway` schema in the default `postgres`
database) only runs against a fresh, empty `pg_data` volume, so it only takes
effect after a hard reset like this — not on a plain `down.sh`/`up.sh`.
