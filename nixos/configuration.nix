# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Static networking (was DHCP via NetworkManager; pinned to the same
  # address it was already leasing so nothing else on the LAN needs to change)
  networking.useDHCP = false;
  networking.interfaces.enp3s0.ipv4.addresses = [{
    address = "192.168.1.29";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "192.168.1.1" ];

  # Setup networking
  networking.firewall.allowedTCPPorts = [ 22 53 3000 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  # Set your time zone.
  time.timeZone = "America/Argentina/Buenos_Aires";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_AR.UTF-8";
    LC_IDENTIFICATION = "es_AR.UTF-8";
    LC_MEASUREMENT = "es_AR.UTF-8";
    LC_MONETARY = "es_AR.UTF-8";
    LC_NAME = "es_AR.UTF-8";
    LC_NUMERIC = "es_AR.UTF-8";
    LC_PAPER = "es_AR.UTF-8";
    LC_TELEPHONE = "es_AR.UTF-8";
    LC_TIME = "es_AR.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "latam";
    variant = "nodeadkeys";
  };

  # Configure console keymap
  console.keyMap = "la-latin1";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.garro = {
    isNormalUser = true;
    description = "SantiagoGarrote";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # This system is managed via the flake in this same directory.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     git
     vim
     htop
     tmux
     curl
     lf
     chafa
     fbv
     file
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  # Setup OpenSSH
  services.openssh.settings = {
    PasswordAuthentication = true;
    ClientAliveInterval = 30;
    ClientAliveCountMax = 3;
  };

  # Enable docker daemon
  virtualisation.docker.enable = true;

  # LAN-wide DNS ad-blocking + local DNS. First run: visit
  # http://192.168.1.29:3000 to complete the setup wizard (admin user +
  # upstream DNS servers) — those choices are stored in mutable state on
  # the box (/var/lib/AdGuardHome), not in this file.
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
