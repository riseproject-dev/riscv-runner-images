FROM riscv64/debian:latest

RUN bash -eux -o pipefail <<EOF
    apt-get update -qq
    apt-get install -qq -y --no-install-recommends docker.io
    rm -rf /var/lib/apt/lists/*
EOF

COPY dockerd-entrypoint.sh /usr/local/bin/

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["/bin/bash", "-x", "/usr/local/bin/dockerd-entrypoint.sh"]
CMD []
