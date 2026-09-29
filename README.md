# server

Config-as-code for my home NixOS server (`homeserver` / 192.168.1.29).

## How this works

- `nixos/configuration.nix` and `nixos/hardware-configuration.nix` mirror
  `/etc/nixos/` on the server. Edit them here, review the diff, then deploy.
- `scripts/deploy.sh [switch|test|boot|dry-build]` copies the files over and
  runs `nixos-rebuild`. Needs your sudo password on the server, so run it
  yourself in a terminal (it won't work non-interactively).
- `scripts/pull.sh` re-syncs from the server, in case something was changed
  directly on the box outside of this repo.
- For anything that isn't a persistent config change (checking logs, disk
  usage, restarting a service, debugging), just SSH in directly:
  `ssh homeserver '...'`. No need to route through this repo for one-offs.

## SSH access

Alias `homeserver` is configured in `~/.ssh/config` (key-based auth, no
password needed for login itself — only `sudo` on the box still prompts).

## Adding a new service

1. Edit `nixos/configuration.nix` (e.g. add to `environment.systemPackages`,
   enable a `services.*` module, open a firewall port).
2. `git diff` to review.
3. `./scripts/deploy.sh test` to try it without making it permanent across
   reboots, or `./scripts/deploy.sh switch` to apply for real.
4. Commit once it's confirmed working.
