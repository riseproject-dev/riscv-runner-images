# Build dockerd + docker-proxy from moby/moby source
FROM golang:1.24-trixie AS moby-build

ARG MOBY_VERSION=28.0.4
RUN bash -eux -o pipefail <<'EOF'
    apt-get update -qq
    apt-get install -qq -y --no-install-recommends \
        btrfs-progs \
        libdevmapper-dev \
        libseccomp-dev \
     && true

    rm -rf /var/lib/apt/lists/*

    git clone --depth 1 --branch "v${MOBY_VERSION}" https://github.com/moby/moby.git /moby
    pushd /moby

    # hack/make.sh reads these env vars to embed version info and select features.
    # DOCKER_BUILDTAGS controls which build tags get passed to go build — seccomp
    # is the main one you want for DinD.
    export VERSION="${MOBY_VERSION}"
    export DOCKER_BUILDTAGS="seccomp"
    export DOCKER_GITCOMMIT=$(git rev-parse HEAD)

    # This produces:
    #   bundles/binary-daemon/dockerd
    #   bundles/binary-daemon/docker-proxy
    ./hack/make.sh binary
EOF


# Build docker-init (tini) — PID 1 for the entrypoint
FROM debian:trixie-slim AS tini-build

ARG TINI_VERSION=0.19.0
RUN bash -eux -o pipefail <<'EOF'
    apt-get update -qq
    apt-get install -qq -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        make \
        gcc \
        git \
        libc-dev \
     && true

    rm -rf /var/lib/apt/lists/*

    git clone --depth 1 --branch "v${TINI_VERSION}" https://github.com/krallin/tini.git /tini
    pushd /tini

    cmake .
    make tini-static
EOF

# Build DinD image
FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN bash -eux -o pipefail <<'EOF'
    apt-get update -qq
    apt-get install -qq -y --no-install-recommends \
        ca-certificates \
        containerd \
        iptables \
        openssl \
        runc \
     && true

    rm -rf /var/lib/apt/lists/*
EOF

# moby binaries (replaces Debian's docker.io)
COPY --from=moby-build /moby/bundles/binary-daemon/dockerd /usr/local/bin/dockerd
COPY --from=moby-build /moby/bundles/binary-daemon/docker-proxy /usr/local/bin/docker-proxy

# tini as docker-init (used by the entrypoint as PID 1)
COPY --from=tini-build /tini/tini-static /usr/local/bin/docker-init

COPY dockerd-entrypoint.sh /usr/local/bin/

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["/bin/bash", "-x", "/usr/local/bin/dockerd-entrypoint.sh"]
