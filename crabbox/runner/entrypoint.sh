#!/bin/sh
set -e

# Persistent volume is mounted at /data on this platform (fixed path).
# Store tailscaled's state there so the machine key survives redeploys,
# keeping the same node identity, hostname, and IP.
mkdir -p /data/tailscale /var/run/tailscale

tailscaled --state=/data/tailscale/tailscaled.state \
           --socket=/var/run/tailscale/tailscaled.sock \
           --tun=userspace-networking &

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