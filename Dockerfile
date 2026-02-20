ARG RUNNER_VERSION="unknown"
ARG RUNNER_CHECKSUM="unknown"
ARG RUNNER_USER="runner"

FROM debian:13

ARG RUNNER_VERSION
ARG RUNNER_CHECKSUM
ARG RUNNER_USER

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eu; \
    [ "${RUNNER_VERSION}" != "unknown" ] || { echo "ERROR: RUNNER_VERSION is not set"; exit 2; }; \
    [ "${RUNNER_CHECKSUM}" != "unknown" ] || { echo "ERROR: RUNNER_CHECKSUM is not set"; exit 2; }; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
    ansible \
    ca-certificates \
    curl \
    git \
    jq \
    libicu-dev \
    libicu76 \
    libssl-dev \
    make \
    openssh-client \
    shellcheck \
    sudo \
    unzip \
    && apt-get -y autoremove \
    && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# create non-root user
RUN useradd -m -s /bin/bash "${RUNNER_USER}" \
    && usermod -aG sudo "${RUNNER_USER}" \
    && echo "${RUNNER_USER} ALL=(ALL) NOPASSWD: /usr/bin/apt-get" > /etc/sudoers.d/10-runner-conf \
    && chmod 0440 /etc/sudoers.d/10-runner-conf

# install github actions runner as root
WORKDIR "/home/${RUNNER_USER}/actions-runner"

RUN curl -fsSL --retry 3 --retry-all-errors -o actions-runner.tar.gz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
    && printf '%s  actions-runner.tar.gz\n' "${RUNNER_CHECKSUM#sha256:}" | sha256sum -c - \
    && tar xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && ./bin/installdependencies.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
    && chown "${RUNNER_USER}":"${RUNNER_USER}" /entrypoint.sh \
    && chown -R "${RUNNER_USER}":"${RUNNER_USER}" "/home/${RUNNER_USER}/actions-runner"

USER "${RUNNER_USER}"
WORKDIR "/home/${RUNNER_USER}/actions-runner"

ENTRYPOINT ["/entrypoint.sh"]
