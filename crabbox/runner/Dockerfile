FROM alpine:3.20

# crabbox POSIX host requirements: openssh, git, rsync, tar, sh (busybox ash is fine)
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
    # fnm from Alpine's own musl-built package (edge/testing) — skip if apk add nodejs/npm is enough
    && apk add --no-cache fnm --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing

# crabbox connects as a dedicated user, not root
RUN adduser -D -s /bin/bash crabbox \
    && mkdir -p /work/crabbox \
    && chown -R crabbox:crabbox /work/crabbox

# sshd setup
RUN ssh-keygen -A \
    && mkdir -p /home/crabbox/.ssh \
    && chown crabbox:crabbox /home/crabbox/.ssh \
    && chmod 700 /home/crabbox/.ssh

# inject your public key at build time or mount it at runtime instead
ARG SSH_PUBKEY
RUN echo "${SSH_PUBKEY}" > /home/crabbox/.ssh/authorized_keys \
    && chown crabbox:crabbox /home/crabbox/.ssh/authorized_keys \
    && chmod 600 /home/crabbox/.ssh/authorized_keys

USER crabbox
ENV SHELL=/bin/bash
RUN echo 'eval "$(fnm env --use-on-cd)"' >> /home/crabbox/.bashrc

USER root
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]
