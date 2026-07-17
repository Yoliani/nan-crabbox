# nan-crabbox

Alpine-based runner image for [crabbox](https://crabbox.sh) — a remote execution harness that leases cloud machines, syncs your repo, and runs commands remotely while you keep the local edit-and-run loop.

This repo is built to run as a **[NaN Cloud App](https://nan.builders/docs/apps)**: NaN builds the Dockerfile, gives the container a persistent `/data` volume, injects your secrets as environment variables, and keeps it running. The runner brings up Tailscale (for outbound-only connectivity) and an SSH server that crabbox connects to.

## What's here

- `crabbox/runner/Dockerfile` — Alpine 3.20 image with SSH, git, rsync, Tailscale, Node.js, fnm, and a dedicated non-root `crabbox` user.
- `crabbox/runner/entrypoint.sh` — starts `tailscaled` (state persisted to `/data`), runs `tailscale up`, then execs `sshd`.

## Deploying on NaN (nan.builders)

Follow the [NaN Apps guide](https://nan.builders/docs/apps):

1. **Create a Space** at [cloud.nan.builders/spaces](https://cloud.nan.builders/spaces) — an isolated environment with CPU/RAM/disk quotas.
2. **Create an App** in that Space and **connect this GitHub repo**.
3. **Configure the build:**
   - **Dockerfile path:** `crabbox/runner/Dockerfile`
   - **Build context:** repo root (`.`) — the `COPY` paths in the Dockerfile are relative to the repo root, not to the Dockerfile's own directory.
4. **Set environment variables** (see below).
5. **Add persistent storage** mounted at `/data` (see [Persistence](#persistence-data)).
6. **Exposed port:** `22` (SSH). This is a worker-style app — you connect over Tailscale/SSH, not over HTTP.
7. **Deploy.** Each push to the configured branch triggers a rebuild when auto-deploy is enabled.

## Environment variables

Set these in the NaN dashboard's **Environment variables** block. Some are build-time, some are runtime.

| Variable | When | Required | Description |
|----------|------|----------|-------------|
| `SSH_PUBKEY` | build | ✅ | Your SSH **public** key (e.g. `ssh-ed25519 AAAA... you@laptop`). Written to the `crabbox` user's `authorized_keys`. Never pass the private key. |
| `TS_AUTHKEY` | runtime | ✅ | Tailscale auth key. If unset, the container starts but skips `tailscale up` (SSH won't be reachable over the tailnet). Use a reusable/ephemeral key as appropriate. |
| `TS_HOSTNAME` | runtime | optional | Tailscale node hostname. Defaults to `nan-crabbox`. |

> **Secrets:** `TS_AUTHKEY` is sensitive — store it as a secret env var, not in the repo. `SSH_PUBKEY` is a public key and safe to expose, but it's a build arg so it must be present at build time.

## Persistence (`/data`)

NaN mounts a persistent volume at a fixed `/data` path (add it under the App's **Advanced / persistent storage** options). The entrypoint stores Tailscale's state there:

```sh
tailscaled --state=/data/tailscale/tailscaled.state ...
```

This keeps the **machine key** across redeploys, so the node keeps the **same identity, hostname, and Tailscale IP** every time the app rebuilds or restarts. Without a persistent `/data`, each deploy would register as a brand-new tailnet node.

Anything else you want to survive redeploys (repo checkouts, caches, artifacts) should also live under `/data`.

## Building locally

You don't need this to deploy on NaN, but for local testing:

**Docker:**

```bash
docker build \
  --build-arg SSH_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)" \
  -t nan-crabbox-runner \
  -f crabbox/runner/Dockerfile \
  .
```

Run it (mount a local dir as `/data`, pass the Tailscale key at runtime):

```bash
docker run --rm \
  -e TS_AUTHKEY="tskey-auth-..." \
  -e TS_HOSTNAME="nan-crabbox" \
  -v "$(pwd)/.data:/data" \
  -p 2222:22 \
  nan-crabbox-runner
```

**Kaniko (CI):** when the build context is the repo root, point kaniko at the Dockerfile explicitly:

```bash
executor \
  --context="$(pwd)" \
  --dockerfile=crabbox/runner/Dockerfile \
  --build-arg SSH_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)" \
  --destination=your-registry/nan-crabbox-runner:latest
```

## SSH details

- Connects as the non-root user **`crabbox`** on port **22**.
- **Public-key auth only** — `PasswordAuthentication no`, `PermitRootLogin no`.
- Working directory: `/work/crabbox`.
- Node.js is available via `fnm` (`eval "$(fnm env --use-on-cd)"` is set in `.bashrc`).

## Notes

- The Dockerfile currently contains a few `TEMP DEBUG` `RUN` steps (printing `authorized_keys` and `sshd_config`). Remove them once SSH auth is verified.
- `fnm` is pulled from Alpine's `edge/testing` repo, which has no stability guarantees. Drop that line if `nodejs`/`npm` alone is enough.
