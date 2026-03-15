# OpenClaw Deployment Toolkit

This repository contains the source code for a Docker-first OpenClaw deployment toolkit. It does not bundle a verified OpenClaw application implementation. Instead, it provides a conservative install/upgrade/uninstall framework that turns missing application facts into explicit configuration instead of hidden assumptions.

## What This Toolkit Does

- Installs or validates Docker and Docker Compose on mainstream Linux distributions.
- Creates a managed install layout under `/opt/openclaw` by default.
- Supports both deployment modes:
  - `image`: pull and run a prebuilt container image.
  - `build`: fetch source from Git or copy a local source tree, then build a container image.
- Generates a managed `compose.yaml`, `.env`, and `runtime.env`.
- Installs a systemd unit that manages the Compose stack when systemd is available.
- Supports repeatable install, upgrade, rollback, and three uninstall levels.

## Important Boundary

Because this repository is the deployment-source project itself, values such as the real application command, healthcheck endpoint, exposed port, required secrets, Git source, and image registry are configuration inputs. The defaults in `.env.example` are toolkit defaults only. They are not treated as proven OpenClaw runtime facts.

## File Layout

- `install_openclaw.sh`: install or repair a managed deployment.
- `upgrade_openclaw.sh`: back up the current state, pull/build a new image, and roll back on failure.
- `uninstall_openclaw.sh`: remove containers, images, or the full managed install tree.
- `compose.yaml`: reference Compose template. The installer writes a concrete version to the install directory.
- `Dockerfile`: generic Python-oriented build image for build mode.
- `.env.example`: deployment contract and conservative defaults.
- `scripts/lib/openclaw-common.sh`: shared shell library.

## Quick Start

Image mode:

```bash
./install_openclaw.sh \
  --mode image \
  --image registry.example.com/openclaw:latest \
  --run-cmd "python -m openclaw" \
  --port 8080 \
  --healthcheck-url "http://127.0.0.1:8080/healthz"
```

Build mode from Git:

```bash
./install_openclaw.sh \
  --mode build \
  --git-repo https://example.com/openclaw.git \
  --git-ref main \
  --run-cmd "python -m openclaw" \
  --port 8080 \
  --healthcheck-url "http://127.0.0.1:8080/healthz"
```

Upgrade:

```bash
./upgrade_openclaw.sh --dir /opt/openclaw --git-ref main
```

Uninstall containers only:

```bash
./uninstall_openclaw.sh --dir /opt/openclaw --mode containers
```

## Configuration Notes

- `OPENCLAW_RUN_CMD` is required for build mode because the generic Dockerfile uses a safe no-op default command.
- `OPENCLAW_REQUIRED_SECRETS` is a comma-separated list of secret keys that will be written into `runtime.env` with `0600` permissions.
- `DOCKER_REGISTRY_MIRROR_URL` is optional. The installer backs up and replaces `/etc/docker/daemon.json` only after explicit confirmation.
- The toolkit uses conservative thresholds:
  - Memory: `4096 MB`
  - Disk: `10240 MB`
  - Swap: `2048 MB`

## Validation

Run shell syntax checks locally:

```bash
bash -n install_openclaw.sh upgrade_openclaw.sh uninstall_openclaw.sh scripts/lib/openclaw-common.sh
```

After installation, use the summary commands printed by the installer to inspect status and logs.
