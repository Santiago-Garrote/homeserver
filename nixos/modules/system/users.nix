{ pkgs, ... }:

{
  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.garro = {
    isNormalUser = true;
    description = "SantiagoGarrote";
    # "jellyfin" lets garro scp/rsync media files into /srv/media without sudo.
    extraGroups = [ "networkmanager" "wheel" "jellyfin" ];
    packages = with pkgs; [];
  };

  # garro already has full root via wheel+sudo; this just lets deploys write
  # the new config into place without an extra interactive sudo prompt.
  systemd.tmpfiles.rules = [
    "d /etc/nixos 0755 garro users -"
  ];

  # Let garro run nixos-rebuild without a password (deploys from the
  # infra-as-code repo), but require it for everything else sudo-able.
  security.sudo.extraRules = [
    {
      users = [ "garro" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
