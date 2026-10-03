{ lib, ... }:

{
  # BitTorrent client — front end of the download/organize pipeline that
  # feeds Jellyfin (./jellyfin.nix). Reached via Caddy on :8448, same
  # pattern as the other services; not opened directly.
  #
  # group = "jellyfin" (not the module's own default "qbittorrent") so
  # downloaded files land in the same group Sonarr/Radarr/Jellyfin all
  # share — see the UMask note below for why that's not enough on its own.
  services.qbittorrent = {
    enable = true;
    openFirewall = false;
    group = "jellyfin";
    webuiPort = 8080;
    # Caddy forwards the original Host header (the tailnet hostname:8448),
    # which doesn't match what qBittorrent expects from a direct
    # localhost:8080 visitor — its anti-DNS-rebinding check rejects that
    # with a bare 401 before auth even runs. Same issue as Syncthing's
    # insecureSkipHostcheck (./syncthing.nix), just qBittorrent's spelling.
    serverConfig.Preferences.WebUI.HostHeaderValidation = false;
  };

  users.users.qbittorrent.extraGroups = [ "jellyfin" ];

  # Primary group alone only controls new files' *group ownership*, not
  # whether that group can write to them — qBittorrent's default umask
  # (022) still drops the group-write bit, which is what Sonarr/Radarr need
  # to later move/rename completed downloads out of this folder.
  systemd.services.qbittorrent.serviceConfig.UMask = lib.mkForce "0002";

  # /srv/media/downloads: qBittorrent's save path (set once via its own
  # Web UI on first login — see README/chat notes, not expressible here).
  # Setgid + shared group, same as /srv/media itself (./jellyfin.nix).
  systemd.tmpfiles.rules = [
    "d /srv/media/downloads 2775 qbittorrent jellyfin -"
  ];
}
