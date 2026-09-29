#!/usr/bin/env bash
# Deploys nixos/* to the server and rebuilds from the flake.
# Usage: scripts/deploy.sh [switch|test|boot|dry-build]   (default: switch)
set -euo pipefail

cd "$(dirname "$0")/.."
source .env.variables

ACTION="${1:-switch}"

scp nixos/configuration.nix nixos/hardware-configuration.nix nixos/flake.nix nixos/flake.lock \
  "$SERVER_HOST:/etc/nixos/"

ssh "$SERVER_HOST" \
  "sudo nixos-rebuild $ACTION --flake /etc/nixos#nixos --option experimental-features 'nix-command flakes'"
