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

## Updating a deployed image

```bash
./cmds/update-deployment.sh prod <argonath-version>
```

Resolves the `project-anduin`/`caskfs`/`postgres` versions pinned to
`<argonath-version>` in the
[cork-build-registry](https://github.com/ucd-library/cork-build-registry),
patches the corresponding image tags into `kustomize/*/overlays/prod`, and
prompts to commit and push the changes.
