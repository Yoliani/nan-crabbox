# nan-crabbox

Alpine-based runner image for crabbox — a remote execution harness that leases cloud machines, syncs your repo, and runs commands remotely while you keep the local edit-and-run loop.

## What's here

- `crabbox/runner/Dockerfile` — Alpine 3.20 image with SSH, git, rsync, Node.js, fnm, and a dedicated `crabbox` user.

## Building

**Docker:**

```bash
docker build \
  --build-arg SSH_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)" \
  -t nan-crabbox-runner \
  crabbox/runner/
```

**Kaniko (CI):**

When the build context is the repo root, point kaniko to the Dockerfile explicitly:

```bash
executor \
  --context="$(pwd)" \
  --dockerfile=crabbox/runner/Dockerfile \
  --build-arg SSH_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)" \
  --destination=your-registry/nan-crabbox-runner:latest
```

## Status

Early stage — the runner Dockerfile exists but the project has no commits yet.
