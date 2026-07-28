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

See [docs/local-dev.md](docs/local-dev.md) to get a stack running locally, or
[docs/prod-cluster.md](docs/prod-cluster.md) for the libk8s deploy checklist.

## Notable deviations from convention

This is modeled on
[aggie-experts-deployment](https://github.com/ucd-library/aggie-experts-deployment),
with a few differences worth knowing:

- **Prod is libk8s, not a compose VM** — aggie-experts's anduin-platform prod
  runs via docker-compose on a VM, with libk8s used only for a dev
  environment. Argonath's prod runs directly on libk8s, so there's a `prod`
  kustomize overlay instead of `dev`.
- **Two postgres instances** — `postgres` (cask, auth gateway, superset) and
  a dedicated `dagster-postgres`, since dagster's run/event-log storage takes
  a heavy read/write hit during pipeline execution. aggie-experts shares one
  instance across everything.
- **No Celery** — argonath's `dagster.yaml` uses `DefaultRunLauncher` +
  `QueuedRunCoordinator`, so there's no `dagster-celery-worker` or `rabbitmq`
  here, unlike aggie-experts.
- **No `.cork-build` yet** — argonath doesn't have a custom bundled image the
  way aggie-experts's `harvest` image bundles app code + cask CLI on top of
  project-anduin's dagster image. The `IMAGE_ARGONATH_*` vars throughout this
  repo are placeholders anticipating that build; see
  [docs/prod-cluster.md](docs/prod-cluster.md).
