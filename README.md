# RISC-V Runner Images

Container images for running GitHub Actions runners on RISC-V (`linux/riscv64`).

Built natively on RISC-V hardware and pushed to the Scaleway Container Registry.

## Images

### Runner (`runner/Dockerfile.ubuntu`)

Single unified GitHub Actions runner image based on Ubuntu, with `dockerd` and `containerd` bundled in (no separate Docker-in-Docker sidecar). Available variants:

| Tag | Base |
|-----|------|
| `riscv-runner:ubuntu-24.04-<suffix>` | Ubuntu 24.04 |
| `riscv-runner:ubuntu-26.04-<suffix>` | Ubuntu 26.04 |

`<suffix>` is `latest` for builds from `main` and the branch slug otherwise (e.g. `staging`).

The runner image includes:
- [GitHub Actions Runner for RISC-V](https://github.com/alitariq4589/github-runner-riscv) (built with .NET 8)
- Java (Adoptium Temurin)
- Python (including free-threaded variants)
- Node.js, Go, Rust
- Apache Ant, Gradle, Apache Maven
- Docker CLI, Docker Buildx, Docker Compose
- Bundled `dockerd` + `containerd` (unified Docker-in-Docker, no sidecar required)
- git, curl, wget, jq, sudo, and many more CLI tools

Pinned versions for every tool above live in [`versions-map.json`](versions-map.json) and are kept in sync with upstream by [`scripts/update-versions.py`](scripts/update-versions.py).

The image aims to match the packages installed in the [official GitHub Actions runner images](https://github.com/actions/runner-images). **Let us know if any package you depend on is missing!**

The entrypoint (`runner/riscv-runner-entrypoint.sh`) uses `docker-init` (tini) as PID 1, starts `containerd` and `dockerd` in the background (unix socket, no TLS), then drops to the `runner` user to execute `./run.sh --jitconfig $RUNNER_JITCONFIG`. Because `dockerd` and the runner share the same filesystem, Docker bind mounts from inside jobs (e.g. `-v /home/runner/_work:/work`) work as expected.

Build args:
- `OS_VERSION` — Ubuntu base image version (default: `latest`)

## Project Structure

```
.
├── .github/workflows/
│   └── release.yml                    # CI: builds and pushes the runner image
├── runner/
│   ├── Dockerfile.ubuntu              # Unified runner image (with bundled dockerd + containerd)
│   └── riscv-runner-entrypoint.sh     # PID-1 entrypoint: starts containerd+dockerd, execs runner
├── scripts/
│   └── update-versions.py             # Syncs pinned versions from upstream
├── versions-map.json                  # Pinned versions for all bundled tools
└── LICENSE
```

## CI/CD

The GitHub Actions workflow (`.github/workflows/release.yml`) triggers on pushes to `main` and `staging`, on a daily schedule, and via manual dispatch. A single `build-runner` job builds the runner image natively on `ubuntu-24.04-riscv` self-hosted RISC-V runners. Images are pushed to the Scaleway Container Registry. GitHub Actions cache (`type=gha`) is used to speed up builds. A concurrency group ensures only the latest run per branch executes.

## Building Locally

```bash
# Runner image (e.g. Ubuntu 24.04)
docker buildx build \
  --platform linux/riscv64 \
  --file runner/Dockerfile.ubuntu \
  --build-arg OS_VERSION=24.04 \
  --tag riscv-runner:ubuntu-24.04 \
  runner
```

Best run on a RISC-V host (`linux/riscv64`) so the build does not need any emulation.

## License

MIT
