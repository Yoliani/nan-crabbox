FROM alpine:3.20

# crabbox POSIX host requirements: openssh, git, rsync, tar, sh (busybox ash is fine)
# tailscale: outbound-only connectivity, avoids needing an inbound TCP port on the PaaS
# nodejs/npm: musl-native from Alpine's own repo (reliable)
# fnm: pulled from Alpine's edge/testing repo — musl-built, but edge/testing has no
#      stability guarantees. Drop this line if apk add nodejs/npm is enough for you.
RUN apk add --no-cache \
    openssh \
    git \
    rsync \
    tar \
    bash \
    curl \
    ca-certificates \
    nodejs \
    npm \
    tailscale \
    && apk add --no-cache fnm --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing

# crabbox connects as a dedicated non-root user
RUN adduser -D -s /bin/bash crabbox \
    && mkdir -p /work/crabbox \
    && chown -R crabbox:crabbox /work/crabbox

# sshd host keys + authorized_keys dir
RUN ssh-keygen -A \
    && mkdir -p /home/crabbox/.ssh \
    && chown crabbox:crabbox /home/crabbox/.ssh \
    && chmod 700 /home/crabbox/.ssh

# Public key only. Never bake the private key into the image.
# Pass at build time: --build-arg SSH_PUBKEY="ssh-ed25519 AAAA... you@laptop"
ARG SSH_PUBKEY
RUN echo "${SSH_PUBKEY}" > /home/crabbox/.ssh/authorized_keys \
    && chown crabbox:crabbox /home/crabbox/.ssh/authorized_keys \
    && chmod 600 /home/crabbox/.ssh/authorized_keys

# --- TEMP DEBUG: remove after diagnosing ---
RUN echo "=== authorized_keys content ===" \
    && cat /home/crabbox/.ssh/authorized_keys \
    && echo "=== permissions ===" \
    && ls -la /home/crabbox /home/crabbox/.ssh
# --- END TEMP DEBUG ---

RUN sed -i \
      -e 's/^#*\s*PubkeyAuthentication.*/PubkeyAuthentication yes/' \
      -e 's/^#*\s*AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' \
      -e 's/^#*\s*PasswordAuthentication.*/PasswordAuthentication no/' \
      -e 's/^#*\s*PermitRootLogin.*/PermitRootLogin no/' \
      /etc/ssh/sshd_config \
    && for directive in PubkeyAuthentication AuthorizedKeysFile PasswordAuthentication PermitRootLogin; do \
         grep -q "^${directive}" /etc/ssh/sshd_config || echo "${directive} $( [ "$directive" = "AuthorizedKeysFile" ] && echo '.ssh/authorized_keys' || echo 'yes' )" >> /etc/ssh/sshd_config; \
       done
RUN echo "=== sshd_config AFTER our changes ===" \
    && grep -inE '^(PubkeyAuthentication|AuthorizedKeysFile|PasswordAuthentication|PermitRootLogin)' /etc/ssh/sshd_config

USER crabbox
ENV SHELL=/bin/bash
RUN echo 'eval "$(fnm env --use-on-cd)"' >> /home/crabbox/.bashrc
USER root

# Build context is the repo root ('.' in the New App form), and this Dockerfile
# lives at crabbox/runner/Dockerfile — so COPY paths are relative to the repo root,
# not to this file's own directory.
COPY crabbox/runner/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
