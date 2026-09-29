#!/usr/bin/env bash
# Deploys nixos/* to the server and rebuilds from the flake.
# Usage: scripts/deploy.sh [switch|test|boot|dry-build]   (default: switch)
set -euo pipefail

HOST="homeserver"
ACTION="${1:-switch}"

cd "$(dirname "$0")/.."

scp nixos/configuration.nix nixos/hardware-configuration.nix nixos/flake.nix nixos/flake.lock \
  "$HOST:/tmp/"

ssh -t "$HOST" "
  sudo cp /tmp/configuration.nix /tmp/hardware-configuration.nix /tmp/flake.nix /tmp/flake.lock /etc/nixos/ &&
  sudo nixos-rebuild $ACTION --flake /etc/nixos#nixos --option experimental-features 'nix-command flakes'
"
