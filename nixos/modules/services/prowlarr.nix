{ ... }:

{
  # Indexer manager — add a tracker here once and it syncs to Sonarr/Radarr
  # (./sonarr.nix, ./radarr.nix) automatically instead of configuring each
  # app separately. Which indexer(s) to add isn't declared here — same
  # mutable-state-via-first-run-UI pattern as everything else (Syncthing's
  # device pairing, Sonarr/Radarr's own indexer lists). Reached via Caddy
  # on :8451; not opened directly.
  services.prowlarr = {
    enable = true;
    openFirewall = false;
  };
}
