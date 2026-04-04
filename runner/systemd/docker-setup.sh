#!/bin/bash
# Pre-start setup for dockerd (simplified from dind/dockerd-entrypoint.sh).
# Only handles: stale PID cleanup + iptables legacy/nf_tables detection.
set -eu

# Remove stale PID files from unclean shutdown
find /run /var/run -iname 'docker*.pid' -delete || :

# iptables legacy vs nf_tables detection
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
        if b="$(cat "$f")" && [ -n "$b" ]; then
            exit 0
        fi
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
iptables --version || true
