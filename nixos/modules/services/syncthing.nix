{ config, ... }:

{
  # File sync across devices (issue #24). GUI is reachable via Caddy on
  # :8445 (see guiAddress note below for why not also directly on :8384).
  # Which devices/folders to sync isn't declared here — pair them through
  # the GUI on first use, same mutable-state pattern as AdGuard/Grafana;
  # overrideDevices/overrideFolders = false keeps nixos-rebuild from
  # wiping that pairing on every deploy.
  # owner must match the "syncthing" service user (default agenix owner is
  # root:root 0400, which the syncthing-init script — running as the
  # syncthing user — couldn't read).
  age.secrets.syncthing-gui-password = {
    file = ../../secrets/syncthing-gui-password.age;
    owner = "syncthing";
    group = "syncthing";
  };

  services.syncthing = {
    enable = true;
    # Loopback-only, unlike Grafana/AdGuard's 0.0.0.0 — the module's own
    # guiPasswordFile-applying script calls Syncthing's API using whatever
    # guiAddress is set to, literally; "0.0.0.0" isn't a connectable
    # destination, so binding it externally broke that script (silently:
    # the password never actually got applied). Caddy still reaches this
    # fine over localhost, so :8445 is the only way to the GUI now.
    guiAddress = "127.0.0.1:8384";
    openDefaultPorts = true; # sync (22000 tcp/udp) + local discovery (21027 udp)
    overrideDevices = false;
    overrideFolders = false;
    # Password is agenix-managed: encrypted at nixos/secrets/syncthing-gui-password.age,
    # decrypted on deploy to /run/agenix/syncthing-gui-password (tmpfs, never
    # written to the Nix store). See README.md's "Secrets (agenix)" section.
    guiPasswordFile = config.age.secrets.syncthing-gui-password.path;
    settings.gui = {
      user = "garro";
      # Reached via Caddy on a hostname Syncthing didn't issue itself,
      # which its anti-DNS-rebinding Host-header check would otherwise
      # reject.
      insecureSkipHostcheck = true;
    };
  };

  # The one-shot config-updater that hashes guiPasswordFile in isn't
  # otherwise retriggered just because the secret's *content* changes
  # (e.g. a future password rotation) — only a change to the unit itself
  # normally causes a restart. Tie it to the secret explicitly.
  systemd.services.syncthing-init.restartTriggers = [
    config.age.secrets.syncthing-gui-password.file
  ];
}
