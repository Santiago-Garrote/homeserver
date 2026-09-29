#!/usr/bin/env bash
# Pulls the live config from the server into this repo, in case it drifted
# (e.g. edited directly on the box). Run before making local changes if unsure.
set -euo pipefail

cd "$(dirname "$0")/.."
source .env.variables

scp "$SERVER_HOST:/etc/nixos/configuration.nix" nixos/configuration.nix
scp "$SERVER_HOST:/etc/nixos/hardware-configuration.nix" nixos/hardware-configuration.nix
scp "$SERVER_HOST:/etc/nixos/flake.nix" nixos/flake.nix
scp "$SERVER_HOST:/etc/nixos/flake.lock" nixos/flake.lock
