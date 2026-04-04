#!/bin/bash
set -eu
mkdir -p /etc/github-runner
# Parse null-delimited /proc/1/environ, split on FIRST = only
while IFS= read -r -d '' line; do
    key="${line%%=*}"
    value="${line#*=}"
    systemctl set-environment "$key=$value" 2>/dev/null || true
    printf '%s=%s\n' "$key" "$value" >> /etc/github-runner/env
done < /proc/1/environ
