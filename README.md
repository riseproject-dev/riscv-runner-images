# RISC-V Runner Images

Container images for running GitHub Actions self-hosted runners on RISC-V (`linux/riscv64`).

Images are built with QEMU cross-compilation via Docker Buildx and pushed to the Scaleway Container Registry.

## Images

### Runner (`runner/Dockerfile.ubuntu`)

GitHub Actions self-hosted runner based on Ubuntu. Available variants:

| Tag | Base |
|-----|------|
| `riscv-runner:ubuntu-24.04-<version>` | Ubuntu 24.04 |
| `riscv-runner:ubuntu-26.04-<version>` | Ubuntu 26.04 |

The runner image includes:
- [GitHub Actions Runner for RISC-V](https://github.com/alitariq4589/github-runner-riscv) (built with .NET 8)
- Docker CLI, Docker Buildx, Docker Compose
- git, curl, sudo

We are aiming to match packages installed in the [official GitHub Actions runner images](https://github.com/actions/runner-images/blob/ubuntu24/20260302.42/images/ubuntu/Ubuntu2404-Readme.md). **Let us know if any package you depend on is missing!**

Build args:
- `UBUNTU_VERSION` — Ubuntu base image version (default: `latest`)
- `RUNNER_VERSION` — GitHub Actions runner version (default: `2.331.0`)

### Docker-in-Docker (`dind/Dockerfile`)

A minimal Docker-in-Docker sidecar image based on Debian (`riscv64/debian:latest`).

| Tag | Base |
|-----|------|
| `riscv-runner:dind` | Debian |

Runs `dockerd` via the bundled `dockerd-entrypoint.sh` (sourced from the [official Docker library](https://github.com/docker-library/docker)). Supports TLS certificate generation out of the box.

## Project Structure

```
.
├── .github/workflows/
│   └── release.yml          # CI: builds and pushes all images in parallel
├── runner/
│   └── Dockerfile.ubuntu    # GitHub Actions runner image
├── dind/
│   ├── Dockerfile           # Docker-in-Docker sidecar image
│   └── dockerd-entrypoint.sh
└── LICENSE
```

## CI/CD

The GitHub Actions workflow (`.github/workflows/release.yml`) triggers on pushes to `main` and manual dispatch. It runs three parallel jobs:

- `build-runner-ubuntu-24_04`
- `build-runner-ubuntu-26_04`
- `build-dind`

Each job uses QEMU + Docker Buildx to cross-compile for `linux/riscv64` and pushes to the Scaleway registry. GitHub Actions cache (`type=gha`) is used to speed up builds. A concurrency group ensures only the latest run per branch executes.

## Building Locally

```bash
# Runner image (e.g. Ubuntu 24.04)
docker buildx build \
  --platform linux/riscv64 \
  --file runner/Dockerfile.ubuntu \
  --build-arg UBUNTU_VERSION=24.04 \
  --build-arg RUNNER_VERSION=2.331.0 \
  --tag riscv-runner:ubuntu-24.04 \
  runner

# DinD image
docker buildx build \
  --platform linux/riscv64 \
  --file dind/Dockerfile \
  --tag riscv-runner:dind \
  dind
```

Requires Docker with QEMU user-static registered (`docker run --rm --privileged multiarch/qemu-user-static --reset -p yes`).

## License

MIT
