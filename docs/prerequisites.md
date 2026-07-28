# Prerequisites

## Local dev

- Docker + Docker Compose
- This repo checked out as a sibling of `argonath`:
  ```
  library/
    ai/
      argonath/
      argonath-deployment/
    project-anduin/
  ```
  `compose/local-dev/compose.yaml` mounts code from both sibling repos by
  relative path (`../../../argonath/...`, `../../../../project-anduin/...`).
  If your checkout layout differs, adjust those paths.
- `openssl` (used by `cmds/init.sh` to generate `SUPERSET_SECRET_KEY`)

## Prod (libk8s)

- [cork-kube](https://github.com/ucd-library/cork-kube) installed and
  authenticated against the libk8s cluster
- The `argonath-prod` namespace's deployer kubeconfig secret
  (`libk8s-argonath-prod-deployer`) provisioned in GCP Secret Manager
- All GCSM secrets referenced in `.cork-kube-config` created ahead of first
  deploy (see the `secrets.prod` list there for exact names)
- An NFS-backed StorageClass on the target nodes for the `caskfs` and
  `dagster-storage` PVCs, and a hostPath-backed StorageClass for the two
  postgres StatefulSets — the `storageClassName` values currently in
  `kustomize/*/overlays/prod/*.yaml` are placeholders (`nfs-client` /
  `local-hostpath`); confirm the real class names on the cluster and fix them
  up before applying
- Nodes labeled `intended-for=argonath-prod-backend` for every workload in
  this repo to schedule onto
