FROM debian:stable-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl ca-certificates git jq \
    && rm -rf /var/lib/apt/lists/*

ARG RUNNER_VERSION=2.319.1
WORKDIR /runner

RUN curl -L -o actions-runner.tar.gz \
      https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && ./bin/installdependencies.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /runner
ENTRYPOINT ["/entrypoint.sh"]
