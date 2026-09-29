#!/usr/bin/env bash
# Deploys nixos/*.nix to the server and rebuilds.
# Usage: scripts/deploy.sh [switch|test|boot|dry-build]   (default: switch)
set -euo pipefail

HOST="homeserver"
ACTION="${1:-switch}"

cd "$(dirname "$0")/.."

scp nixos/configuration.nix "$HOST:/tmp/configuration.nix"
scp nixos/hardware-configuration.nix "$HOST:/tmp/hardware-configuration.nix"

ssh -t "$HOST" "
  sudo cp /tmp/configuration.nix /etc/nixos/configuration.nix &&
  sudo cp /tmp/hardware-configuration.nix /etc/nixos/hardware-configuration.nix &&
  sudo nixos-rebuild $ACTION
"
