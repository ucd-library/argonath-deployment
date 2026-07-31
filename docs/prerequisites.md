# Prerequisites

## Local dev

Needed to just run the stack via `docker compose`:

- **[Docker](https://docs.docker.com/get-docker/)** (includes Compose v2) —
  runs every service as a container; this is all you need if you're not
  editing code on the host.
- **[git](https://git-scm.com/downloads)** — clone this repo and its 3
  sibling repos (`argonath`, `project-anduin`, `caskfs`).
- **[cork-kube](https://github.com/ucd-library/cork-kube)** — builds/registers
  the local images (`cmds/build-local-dev.sh`, `cmds/init.sh`).
- **[gcloud CLI](https://cloud.google.com/sdk/docs/install)** — pulls
  `OIDC_CLIENT_SECRET` from GCP Secret Manager during first-time setup.
- **[openssl](https://openssl-library.org/source/)** — generates dev-only
  `JWT_SECRET`/`SUPERSET_SECRET_KEY` values (ships with macOS and most Linux
  distros already).

Only needed if you're coding on the host machine instead of only running
the stack (e.g. editing argonath's `exec/`/`ops/` code, which is live-mounted
into the containers — see [local-dev.md](local-dev.md)):

- **[Python 3.11+](https://www.python.org/downloads/)** — argonath's `exec/`
  (`digtk`/`dc` CLI) requires Python ≥3.11.
- **[uv](https://docs.astral.sh/uv/getting-started/installation/)** — package
  manager used to install `digtk`'s Python deps.
- **[Node.js 20+](https://nodejs.org/en/download)** (npm ships with it) —
  required by caskfs (18+) and project-anduin's auth-gateway; also used by
  argonath's `ops/` CLI.
- **[ImageMagick](https://imagemagick.org/script/download.php)** — argonath's
  `digtk image` commands (thumbnail/convert/deskew/prep-ocr) shell out to
  `convert`.
- **[Tesseract OCR](https://tesseract-ocr.github.io/tessdoc/Installation.html)**
  — backs `digtk ocr tesseract`.
- **[Ghostscript](https://www.ghostscript.com/releases/gsdnld.html)** — used
  by ImageMagick under the hood for PDF read/write.
- **[ffmpeg](https://ffmpeg.org/download.html)** — audio/video transcoding
  and inspection (`ffprobe`).
- **[whisper](https://github.com/openai/whisper)** — speech-to-text
  transcription (`pip install -U openai-whisper`; needs ffmpeg on `PATH`
  too).
- **poppler-utils** — PDF utilities (`pdftoppm`, `pdftotext`, `pdfinfo`).
  Install via package manager: `brew install poppler` (macOS) or
  `apt install poppler-utils` (Debian/Ubuntu) — see
  [poppler.freedesktop.org](https://poppler.freedesktop.org/) for other
  platforms.
- **[exiftool](https://exiftool.org/install.html)** — reads/writes file
  metadata.

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
