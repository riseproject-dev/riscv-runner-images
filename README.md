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
- Bundled `dockerd` + `containerd` (unified Docker-in-Docker — no sidecar required)
- git, curl, wget, jq, sudo, and many more CLI tools

We are aiming to match packages installed in the [official GitHub Actions runner images](https://github.com/actions/runner-images/blob/ubuntu24/20260302.42/images/ubuntu/Ubuntu2404-Readme.md). **Let us know if any package you depend on is missing!**

The entrypoint (`runner/riscv-runner-entrypoint.sh`) uses `docker-init` (tini) as PID 1, starts `containerd` and `dockerd` in the background (unix socket, no TLS), then drops to the `runner` user to execute `./run.sh --jitconfig $RUNNER_JITCONFIG`. Because `dockerd` and the runner share the same filesystem, Docker bind mounts from inside jobs (e.g. `-v /home/runner/_work:/work`) work as expected.

Build args:
- `OS_VERSION` — Ubuntu base image version (default: `latest`)

## Project Structure

```
.
├── .github/workflows/
│   └── release.yml                    # CI: builds and pushes the runner image
├── runner/
│   ├── Dockerfile.ubuntu              # GitHub Actions runner image (unified DinD)
│   └── riscv-runner-entrypoint.sh     # PID-1 entrypoint: starts containerd+dockerd, execs runner
└── LICENSE
```

## CI/CD

The GitHub Actions workflow (`.github/workflows/release.yml`) triggers on pushes to `main`, on a daily schedule, and manual dispatch. A single `build-runner` job builds Ubuntu 24.04 and 26.04 runner images via a matrix.

The Ubuntu 24.04 runner builds natively on `ubuntu-24.04-riscv` self-hosted runners. The Ubuntu 26.04 runner builds with QEMU cross-compilation on `ubuntu-latest`. Images are pushed to the Scaleway Container Registry. GitHub Actions cache (`type=gha`) is used to speed up builds. A concurrency group ensures only the latest run per branch executes.

## Building Locally

```bash
# Runner image (e.g. Ubuntu 24.04)
docker buildx build \
  --platform linux/riscv64 \
  --file runner/Dockerfile.ubuntu \
  --build-arg OS_VERSION=24.04 \
  --build-arg RUNNER_VERSION=2.333.1 \
  --tag riscv-runner:ubuntu-24.04 \
  runner
```

When cross-compiling, requires Docker with QEMU user-static registered (`docker run --rm --privileged multiarch/qemu-user-static --reset -p yes`).

## License

MIT
