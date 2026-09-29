# homeserver

Config-as-code for my home NixOS server. See [SPECS.md](SPECS.md) for
hardware/OS details.

## How this works

- `nixos/` mirrors `/etc/nixos/` on the server: `configuration.nix` (the
  actual system config), `hardware-configuration.nix` (machine-specific,
  auto-generated, rarely touched), and `flake.nix`/`flake.lock` (pins the
  exact nixpkgs revision — the NixOS version is a committed fact here, not
  imperative state on the box).
- `scripts/deploy.sh [switch|test|boot|dry-build]` copies `nixos/*` to the
  server and runs `nixos-rebuild`. Fully non-interactive — no password
  needed (see below).
- `scripts/pull.sh` re-syncs from the server, in case something was changed
  directly on the box outside of this repo.
- For anything that isn't a persistent config change (checking logs, disk
  usage, restarting a service, debugging), just SSH in directly:
  `ssh homeserver '...'`. No need to route through this repo for one-offs.

## Config values

- `.env.variables` — non-sensitive, versioned (host alias, static IP, etc).
  Scripts `source` this.
- `.env.secrets` — gitignored, never committed. Copy `.env.secrets.sample`
  to create it once something actually needs a secret (API key, auth token).
  Nothing needs this yet.

## SSH / sudo access

- Alias `homeserver` is configured in `~/.ssh/config` (key-based auth).
- `garro` has scoped passwordless `sudo` for `nixos-rebuild` only
  (`security.sudo.extraRules` in `configuration.nix`) — everything else
  still prompts.
- `/etc/nixos` is owned by `garro` (`systemd.tmpfiles.rules`), so deploys
  can write the new config there without `sudo` at all.
- `garro` already has full root via `wheel` + interactive `sudo` regardless
  of the above — these just remove password friction for routine deploys,
  they don't grant new privilege.

## Adding a new service

1. Edit `nixos/configuration.nix` (e.g. add to `environment.systemPackages`,
   enable a `services.*` module, open a firewall port).
2. `git diff` to review.
3. `scripts/deploy.sh test` to try it without making it permanent across
   reboots, or `scripts/deploy.sh switch` to apply for real.
4. Commit once it's confirmed working.
