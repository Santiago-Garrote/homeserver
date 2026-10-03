{ lib, ... }:

{
  # TV organizer: watches qBittorrent (./qbittorrent.nix) for completed
  # downloads, matches them to a series, renames/moves them into
  # /srv/media/shows in the layout Jellyfin expects. Reached via Caddy on
  # :8449; not opened directly.
  #
  # group = "jellyfin" (not the module's own default "sonarr") for the same
  # reason as qBittorrent — shares file access with the rest of the
  # pipeline without extra ACL plumbing.
  services.sonarr = {
    enable = true;
    openFirewall = false;
    group = "jellyfin";
  };

  users.users.sonarr.extraGroups = [ "jellyfin" ];
  # The servarr module sets its own UMask default (0022); force ours so
  # output stays group-writable for the rest of the pipeline.
  systemd.services.sonarr.serviceConfig.UMask = lib.mkForce "0002";

  # /srv/media/shows doubles as Sonarr's root folder (set via its own Web
  # UI) and the folder Jellyfin's "Shows" library (added via its own Web
  # UI) watches.
  systemd.tmpfiles.rules = [
    "d /srv/media/shows 2775 sonarr jellyfin -"
  ];
}
