# argonath-deployment

Deployment configuration for [argonath](https://github.com/ucd-library/argonath),
UC Davis Library's digital collections processing pipeline, which runs on top
of [Project Anduin](https://github.com/ucd-library/project-anduin) (Dagster +
Superset + CaskFS behind a shared Auth Gateway).

This repo covers the anduin-platform services argonath depends on:
Auth Gateway, CaskFS, Dagster, and Superset — plus the shared postgres/volumes
they need. It does not (yet) include argonath's own pipeline-runner
container (`dc`, from the argonath repo's `media/`) as a k8s workload; that's
still run ad hoc via compose for local dev.

## Structure

- `.cork-kube-config` — [cork-kube](https://github.com/ucd-library/cork-kube)
  project/environment/secrets/services definition
- `kustomize/` — per-service base + `overlays/prod` kustomize dirs, one prod
  libk8s environment, all scheduled onto nodes labeled
  `intended-for=argonath-prod-backend`
- `compose/local-dev/` — self-contained docker-compose stack for local dev
  (flattens argonath's own compose file together with project-anduin's)
- `cmds/` — helper scripts for local dev (`init.sh`, `up.sh`, `down.sh`,
  `argonath-dc.sh`)
- `docs/` — [prerequisites](docs/prerequisites.md),
  [local dev](docs/local-dev.md), [prod cluster](docs/prod-cluster.md)

## Docs

- [docs/prerequisites.md](docs/prerequisites.md) — what you need installed
  and how repos should be checked out before doing anything else
- [docs/local-dev.md](docs/local-dev.md) — first-time setup and day-to-day
  workflow for running the stack locally with docker compose
- [docs/prod-cluster.md](docs/prod-cluster.md) — first-deploy checklist for
  the libk8s prod environment
