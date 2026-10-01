#!/usr/bin/env bash
# Pulls the live config from the server into this repo, in case it drifted
# (e.g. edited directly on the box). Run before making local changes if unsure.
# Set TAILSCALE=1 to connect over the tailnet instead of the LAN (e.g. when away from home).
set -euo pipefail

cd "$(dirname "$0")/.."
source .env.variables

HOST="$SERVER_HOST"
[[ "${TAILSCALE:-}" == "1" ]] && HOST="$SERVER_HOST_TAILSCALE"

scp "$HOST:/etc/nixos/configuration.nix" nixos/configuration.nix
scp "$HOST:/etc/nixos/hardware-configuration.nix" nixos/hardware-configuration.nix
scp "$HOST:/etc/nixos/flake.nix" nixos/flake.nix
scp "$HOST:/etc/nixos/flake.lock" nixos/flake.lock
