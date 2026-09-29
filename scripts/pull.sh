#!/usr/bin/env bash
# Pulls the live config from the server into this repo, in case it drifted
# (e.g. edited directly on the box). Run before making local changes if unsure.
set -euo pipefail

HOST="homeserver"
cd "$(dirname "$0")/.."

scp "$HOST:/etc/nixos/configuration.nix" nixos/configuration.nix
scp "$HOST:/etc/nixos/hardware-configuration.nix" nixos/hardware-configuration.nix
