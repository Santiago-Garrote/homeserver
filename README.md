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
- Secrets a *service* needs at runtime (a GUI password, an API key a NixOS
  module reads from a file) go through [agenix](https://github.com/ryantm/agenix)
  instead — encrypted and committed to `nixos/secrets/`, decrypted
  automatically on the server at `nixos-rebuild` time. See below.

## Secrets (agenix)

Recipients — who can decrypt — are listed in `nixos/secrets/secrets.nix`:
the server's own SSH host key (so `nixos-rebuild` can decrypt on deploy)
and your personal SSH key (so you can encrypt/edit from your own machine).
Both are plain SSH ed25519 *public* keys, safe to commit.

To add a new secret:

1. `cd nixos/secrets`
2. Add an entry to `secrets.nix`, e.g. `"some-password.age".publicKeys = allKeys;`
3. `agenix -e some-password.age` — opens `$EDITOR`, encrypts on save.
4. Reference it in `configuration.nix` via `age.secrets.some-password.file = ./secrets/some-password.age;`,
   then point whatever option needs it at `config.age.secrets.some-password.path`
   (resolves to `/run/agenix/some-password` on the deployed box — never
   written to the Nix store).
5. Commit the new `.age` file along with the config change.

To edit an existing secret: `agenix -e <name>.age` from `nixos/secrets`
(needs your personal SSH key to decrypt first). To add/remove a recipient
(e.g. a new admin's key), edit `secrets.nix` then `agenix -r` to
re-encrypt every secret for the updated recipient list.

Requires the `agenix` CLI on your workstation (not the server — the NixOS
module handles decryption there) — e.g. `nix shell github:ryantm/agenix`,
or install it some other way.

## SSH / sudo access

- Alias `homeserver` is configured in `~/.ssh/config` (key-based auth), pointed
  at the LAN IP. A second alias, `homeserver-ts`, connects over Tailscale
  instead (`nixos.tail70aa47.ts.net`) — useful when off the LAN. Both scripts
  and one-off `ssh`/`scp` commands can use either alias directly; `scripts/
  deploy.sh` and `scripts/pull.sh` also accept `TAILSCALE=1` to switch to the
  tailnet host without typing the alias out.
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
