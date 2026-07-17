#!/bin/sh
set -e
mkdir -p /var/lib/tailscale /var/run/tailscale
tailscaled --state=/var/lib/tailscale/tailscaled.state \
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
exec /usr/sbin/sshd -D -e -o LogLevel=DEBUG3
