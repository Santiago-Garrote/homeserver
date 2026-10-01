#!/usr/bin/env bash
# Deploys nixos/* to the server and rebuilds from the flake.
# Usage: scripts/deploy.sh [switch|test|boot|dry-build]   (default: switch)
# Set TAILSCALE=1 to connect over the tailnet instead of the LAN (e.g. when away from home).
set -euo pipefail

cd "$(dirname "$0")/.."
source .env.variables

ACTION="${1:-switch}"
HOST="$SERVER_HOST"
[[ "${TAILSCALE:-}" == "1" ]] && HOST="$SERVER_HOST_TAILSCALE"

rsync -a --delete --exclude result nixos/ "$HOST:/etc/nixos/"

ssh "$HOST" \
  "sudo nixos-rebuild $ACTION --flake /etc/nixos#nixos --option experimental-features 'nix-command flakes'"
