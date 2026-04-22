#!/bin/bash
set -eu

cleanup() {
    echo "Shutting down..."
    [ -n "${DOCKERD_PID:-}" ] && kill "$DOCKERD_PID" 2>/dev/null && wait "$DOCKERD_PID" 2>/dev/null || true
    [ -n "${CONTAINERD_PID:-}" ] && kill "$CONTAINERD_PID" 2>/dev/null && wait "$CONTAINERD_PID" 2>/dev/null || true
}
trap cleanup EXIT

# --- PID cleanup ---
find /run /var/run -iname 'docker*.pid' -delete || :

# --- iptables legacy vs nf_tables detection ---
# (ported from dind/dockerd-entrypoint.sh)
iptablesLegacy=
if [ -n "${DOCKER_IPTABLES_LEGACY+x}" ]; then
    iptablesLegacy="$DOCKER_IPTABLES_LEGACY"
    if [ -n "$iptablesLegacy" ]; then
        modprobe ip_tables || :
        modprobe ip6_tables || :
    else
        modprobe nf_tables || :
    fi
elif (
    for f in /proc/net/ip_tables_names /proc/net/ip6_tables_names /proc/net/arp_tables_names; do
        if b="$(cat "$f")" && [ -n "$b" ]; then exit 0; fi
    done
    exit 1
); then
    iptablesLegacy=1
elif ! iptables -nL > /dev/null 2>&1; then
    modprobe nf_tables || :
    if ! iptables -nL > /dev/null 2>&1; then
        modprobe ip_tables || :
        modprobe ip6_tables || :
        if /usr/local/sbin/.iptables-legacy/iptables -nL > /dev/null 2>&1; then
            iptablesLegacy=1
        fi
    fi
fi
if [ -n "$iptablesLegacy" ]; then
    export PATH="/usr/local/sbin/.iptables-legacy:$PATH"
fi

# --- Start containerd ---
containerd &>/var/log/containerd.log &
CONTAINERD_PID=$!

# --- Start dockerd ---
dockerd \
    --host=unix:///var/run/docker.sock \
    --containerd=/run/containerd/containerd.sock \
    --mtu=1450 \
    &>/var/log/dockerd.log &
DOCKERD_PID=$!

# --- Run GitHub runner ---
# RUNNER_WAIT_FOR_DOCKER_IN_SECONDS (set by the k8s pod spec) makes run-helper.sh
# poll `docker ps` until dockerd is ready before launching Runner.Listener.
test -n "${RUNNER_VERSION+x}" || (echo "RUNNER_VERSION is not defined"; exit 1)
test -n "${RUNNER_JITCONFIG+x}" || (echo "RUNNER_JITCONFIG is not defined"; exit 1)
su --shell /bin/bash --login runner -- /home/runner/actions-runner/cached/${RUNNER_VERSION}/run.sh --jitconfig --jitconfig "${RUNNER_JITCONFIG}" &
RUNNER_PID=$!

# tini only signals its direct child (this bash), so forward SIGTERM to the runner.
trap 'kill $RUNNER_PID 2>/dev/null' TERM

wait $RUNNER_PID || true
