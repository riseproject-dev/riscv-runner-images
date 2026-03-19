# RISC-V Runner Images

Container images for running GitHub Actions runners on RISC-V (`linux/riscv64`).

Images are built with QEMU cross-compilation via Docker Buildx and pushed to the Scaleway Container Registry.

## Images

### Runner (`runner/Dockerfile.ubuntu`)

GitHub Actions runner based on Ubuntu. Available variants:

| Tag | Base |
|-----|------|
| `riscv-runner:ubuntu-24.04-<version>` | Ubuntu 24.04 |
| `riscv-runner:ubuntu-26.04-<version>` | Ubuntu 26.04 |

The runner image includes:
- [GitHub Actions Runner for RISC-V](https://github.com/alitariq4589/github-runner-riscv) (built with .NET 8)
- Java 17, 21, 25 (default), from [Adoptium Temurin](https://adoptium.net/)
- Python 3.10, 3.11, 3.12 (default), 3.13, 3.13t (free threaded), 3.14, 3.14t (free threaded)
- Apache Ant 1.10.14, Gradle 9.3.1, Apache Maven 3.9.12
- Docker CLI, Docker Buildx, Docker Compose
- git, curl, wget, jq, sudo, and many more CLI tools

We are aiming to match packages installed in the [official GitHub Actions runner images](https://github.com/actions/runner-images/blob/ubuntu24/20260302.42/images/ubuntu/Ubuntu2404-Readme.md). **Let us know if any package you depend on is missing!**

Build args:
- `OS_VERSION` — Ubuntu base image version (default: `latest`)
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

The GitHub Actions workflow (`.github/workflows/release.yml`) triggers on pushes to `main`, on a daily schedule, and manual dispatch. It uses a matrix strategy with two jobs:

- `build-runner` — builds Ubuntu 24.04 and 26.04 runner images (via matrix)
- `build-dind` — builds the Docker-in-Docker sidecar image

The Ubuntu 24.04 runner builds natively on `ubuntu-24.04-riscv` self-hosted runners. The Ubuntu 26.04 runner builds with QEMU cross-compilation on `ubuntu-latest`. All images are pushed to the Scaleway Container Registry. GitHub Actions cache (`type=gha`) is used to speed up builds. A concurrency group ensures only the latest run per branch executes.

## Building Locally

```bash
# Runner image (e.g. Ubuntu 24.04)
docker buildx build \
  --platform linux/riscv64 \
  --file runner/Dockerfile.ubuntu \
  --build-arg OS_VERSION=24.04 \
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

When cross-compiling, requires Docker with QEMU user-static registered (`docker run --rm --privileged multiarch/qemu-user-static --reset -p yes`).

## License

MIT
