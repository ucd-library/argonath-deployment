# Local Development

## First-time setup

```sh
./cmds/init.sh
```

Creates `compose/local-dev/.env` from `.env.example` and generates a
`SUPERSET_SECRET_KEY`. You'll still need to fill in by hand:

- `SAMWISE_API_KEY` — Samwise AI platform key
- `OIDC_CLIENT_SECRET` / `JWT_SECRET` — ask a teammate, or generate your own
  dev-only values
- `IMAGE_ARGONATH_*` — argonath has no `.cork-build` yet, so there's no
  registry image to pull. Either build the underlying images yourself locally
  (`dagster`/`auth-gateway`/`superset` from
  [project-anduin](https://github.com/ucd-library/project-anduin), `cask`
  from [caskfs](https://github.com/ucd-library/caskfs)) and tag them to match,
  or point these vars at whatever sandbox tags you're already using.

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

## Superset

The `superset` container starts idle (`tail -f /dev/null`) — it needs a
one-time init before it'll actually serve anything:

```sh
./cmds/argonath-dc.sh exec superset superset db upgrade
./cmds/argonath-dc.sh exec superset superset fab create-admin
./cmds/argonath-dc.sh exec superset superset init
./cmds/argonath-dc.sh exec superset gunicorn -w 1 -b 0.0.0.0:8088 "superset.app:create_app()"
```

## Two postgres instances

`postgres` backs cask, the auth gateway, and superset. `dagster-postgres` is
a separate instance dedicated to dagster's run/event-log storage, since
dagster puts a heavy read/write load on it during pipeline execution — keeping
it isolated means a busy pipeline run can't starve the other services'
database connections.
