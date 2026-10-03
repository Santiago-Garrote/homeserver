{ lib, ... }:

{
  # Movie organizer — same role as Sonarr (./sonarr.nix) but for films,
  # moving completed downloads into /srv/media/movies. Reached via Caddy
  # on :8450; not opened directly.
  services.radarr = {
    enable = true;
    openFirewall = false;
    group = "jellyfin";
  };

  users.users.radarr.extraGroups = [ "jellyfin" ];
  # The servarr module sets its own UMask default (0022); force ours so
  # output stays group-writable for the rest of the pipeline.
  systemd.services.radarr.serviceConfig.UMask = lib.mkForce "0002";

  # /srv/media/movies doubles as Radarr's root folder and the folder
  # Jellyfin's "Movies" library watches — both set via their own Web UIs.
  systemd.tmpfiles.rules = [
    "d /srv/media/movies 2775 radarr jellyfin -"
  ];
}
