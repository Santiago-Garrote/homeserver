# This file wires together the per-concern modules in ./modules/ and keeps
# only the handful of settings that don't belong to any single one of them.
# To change a service, edit its module; to add or remove a service, edit
# the imports list below.

{ ... }:

{
  imports = [
    ./hardware-configuration.nix

    ./modules/system/boot.nix
    ./modules/system/nix-settings.nix
    ./modules/system/locale.nix
    ./modules/system/networking.nix
    ./modules/system/ssh.nix
    ./modules/system/users.nix
    ./modules/system/packages.nix
    ./modules/system/docker.nix

    ./modules/services/tailscale.nix
    ./modules/services/adguard.nix
    ./modules/services/monitoring.nix
    ./modules/services/grafana.nix
    ./modules/services/caddy.nix
    ./modules/services/syncthing.nix
    ./modules/services/jellyfin.nix
    ./modules/services/qbittorrent.nix
    ./modules/services/sonarr.nix
    ./modules/services/radarr.nix
    ./modules/services/prowlarr.nix
    ./modules/services/home-assistant.nix
    ./modules/services/homepage.nix
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
