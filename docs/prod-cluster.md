# Prod Cluster (libk8s)

Argonath's prod environment deploys directly to libk8s (unlike, e.g.,
aggie-experts, whose anduin-platform prod runs on a docker-compose VM) — see
`.cork-kube-config` for the namespace/secrets/services definition consumed by
[cork-kube](https://github.com/ucd-library/cork-kube).

All workloads in this repo schedule onto nodes labeled
`intended-for=argonath-prod-backend`.

## First deploy checklist

1. Create every GCSM secret listed under `secrets.prod` in `.cork-kube-config`.
2. Confirm the placeholder `storageClassName` values in
   `kustomize/*/overlays/prod/*.yaml` against what's actually available on
   the cluster (NFS-backed for `caskfs`/`dagster-storage`, hostPath-backed for
   both postgres instances) and fix them up.
3. Point the `IMAGE_ARGONATH_*` placeholders in each
   `kustomize/*/overlays/prod/deployment.yaml` (and the superset
   `statefulset.yaml`) at real images. Argonath has no `.cork-build` yet — the
   dagster image in particular needs one, since dagster's assets shell out to
   the `dc` CLI (see `dagster/lib/utils.py` in the argonath repo), meaning the
   real image has to bundle argonath's `dagster/` code + `dc` on top of
   project-anduin's upstream dagster image (same shape as aggie-experts's
   `harvest` image).
4. `cork-kube deploy -e prod` (see cork-kube's own docs for exact invocation).

## Initializing production

Once postgres is up, run the init Job. It uses the `argonath-worker` image
(which has the `cask` and `digtk` CLIs) and runs the `argonath-prod-init`
script baked into it (`cmds/prod-init.sh` in the argonath repo).

1. Create the `libk8s-argonath-prod-cask-admin-users` GCSM secret: a comma
   separated list of the users to grant the cask `admin` role
   (`dagster` and `dcs-gateway` are always granted it).
2. Deploy secrets: `cork-kube secrets deploy prod` (see cork-kube's own docs
   for exact invocation).
3. Run the job:

```bash
./cmds/prod-init.sh prod
```

The job creates the `superset` and `dcf` databases and the `auth_gateway`
schema, runs `cask init-pg`, grants the cask admin roles, installs digtk's
`state` and `reporting` schemas and loads the cask auto-path rules. Every step
is safe to re-run. `kustomize/init` is intentionally not listed under
`services` in `.cork-kube-config` (Jobs are immutable), so `cork-kube deploy`
never applies it; the script deletes any previous `init` Job before applying.

dc-showcase has its own init Job (the `dcf` schema and its cask gold seed
files). Run it afterwards, from dc-showcase-deployment, since it depends on
the `dcf` database, the cask tables and the `dcs-gateway` cask admin role
created above:

```bash
./cmds/prod-init.sh prod
```

## Updating a deployed image

```bash
./cmds/update-deployment.sh prod <argonath-version>
```

Resolves the `project-anduin`/`caskfs`/`postgres` versions pinned to
`<argonath-version>` in the
[cork-build-registry](https://github.com/ucd-library/cork-build-registry),
patches the corresponding image tags into `kustomize/*/overlays/prod`, and
prompts to commit and push the changes.
