#!/bin/sh
set -e

mkdir -p /var/lib/tailscale /var/run/tailscale

# --tun=userspace-networking: works without /dev/net/tun or NET_ADMIN, which most
# PaaS/Kubernetes environments don't grant to app containers. Slower than kernel
# mode, but it's the safe default here. Drop the flag if your platform confirms
# it grants NET_ADMIN + TUN access.
tailscaled --state=/var/lib/tailscale/tailscaled.state \
           --socket=/var/run/tailscale/tailscaled.sock \
           --tun=userspace-networking &

# give tailscaled a moment to start listening on its socket before "tailscale up"
sleep 2

if [ -z "${TS_AUTHKEY}" ]; then
  echo "WARNING: TS_AUTHKEY is not set — skipping tailscale up." >&2
else
  tailscale up \
    --authkey="${TS_AUTHKEY}" \
    --hostname="${TS_HOSTNAME:-nan-crabbox}" \
    --accept-routes
fi

exec /usr/sbin/sshd -D -e
