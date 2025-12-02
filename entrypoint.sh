#!/usr/bin/env bash
set -euo pipefail

: "${GH_RUNNER_URL:?need GH_RUNNER_URL}"
: "${GH_RUNNER_TOKEN:?need GH_RUNNER_TOKEN}"

: "${GH_RUNNER_LABELS:=self-hosted,ephemeral}"
: "${GH_RUNNER_NAME:=ephemeral-$(hostname)-$RANDOM}"

./config.sh \
  --url "${GH_RUNNER_URL}" \
  --token "${GH_RUNNER_TOKEN}" \
  --name "${GH_RUNNER_NAME}" \
  --labels "${GH_RUNNER_LABELS}" \
  --ephemeral \
  --unattended \
  --disableupdate \
  --replace

./run.sh
