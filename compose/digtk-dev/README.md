# digtk-dev

A self-contained docker-compose stack for developers working on
[digtk](https://github.com/ucd-library/argonath/tree/main/exec/digtk) (the
`argonath/exec/digtk` CLI/library). Unlike `compose/local-dev/`, this stack has
**no source bind-mounts** - every image is a pre-built, pushed `:dev` tag from
`us-west1-docker.pkg.dev/argonath-508815/argo-dev`, hardcoded in
`compose.yaml`. It doesn't depend on, or share a network with,
`compose/local-dev/` - it runs entirely on its own.

## Requires

A sibling checkout of [argonath](https://github.com/ucd-library/argonath) at
the same level as `argonath-deployment`'s parent dir (used by
`cmds/digtk-dev/start.sh` to run `uv run digtk auth login`).

## Dev loop

```sh
./cmds/digtk-dev/build.sh    # build your digtk changes and push a fresh :dev image (requires gcloud auth, app devs only)
./cmds/digtk-dev/update.sh   # pull repo + images + .env secret, re-apply db schema
./cmds/digtk-dev/start.sh    # bring the stack up, log in the digtk/cask CLIs
./cmds/digtk-dev/stop.sh     # tear it down
```

`./cmds/digtk-dev/dc.sh` is a thin wrapper around `docker compose -p digtk-dev`
for ad hoc use (`exec`, `ps`, `logs -f`, etc).

Once up:

| Service        | URL                     |
|----------------|--------------------------|
| Auth Gateway   | http://localhost:4000    |
| Dagster UI     | http://localhost:3000    |
| Cask           | http://localhost:3001    |
| Superset       | http://localhost:8088    |

## Notes

- `.env` in this directory is managed entirely by `update.sh` (pulled fresh
  from the `digtk-dev-dot-env` secret in GCP Secret Manager, project
  `argonath-508815`) - see `.env.example` for the fields it contains. It is
  gitignored; there's no manual copy-and-fill step.
- This stack does not include dc-showcase/elasticsearch integration - the
  `digtk showcase ...` subcommands aren't initialized here.
