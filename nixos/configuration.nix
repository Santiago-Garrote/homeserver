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
  networking.firewall.allowedTCPPorts = [ 22 53 80 3000 3001 19999 8443 8444 8445 ];
  networking.firewall.allowedUDPPorts = [ 53 41641 ];

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

  # LAN-wide DNS ad-blocking + local DNS. Web UI moved to :80 after the
  # setup wizard (admin user + upstream DNS servers were chosen there) —
  # those choices are stored in mutable state on the box
  # (/var/lib/AdGuardHome), not in this file.
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
  };

  # Remote access + subnet router: lets any device on your tailnet reach
  # the whole home LAN (e.g. the router at 192.168.1.1) once connected,
  # not just this server. `useRoutingFeatures = "server"` sets the needed
  # ip_forward sysctls automatically.
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Resource monitoring: Netdata collects CPU/RAM/disk/network metrics
  # locally (not claimed to Netdata Cloud). Note: nixpkgs' netdata package
  # ships the GPL'd agent/API only — the :19999 web dashboard is NOT
  # bundled, since that frontend is closed-source and normally pulled live
  # from app.netdata.cloud. So the actual dashboard is Prometheus+Grafana
  # below, which scrape Netdata's local Prometheus-compatible endpoint
  # instead of using its web UI.
  services.netdata.enable = true;

  services.prometheus = {
    enable = true;
    scrapeConfigs = [
      {
        job_name = "netdata";
        metrics_path = "/api/v1/allmetrics";
        params.format = [ "prometheus" ];
        static_configs = [{ targets = [ "localhost:19999" ]; }];
      }
    ];
  };

  # Dashboard at :3001 (3000 is taken by AdGuard Home). Default admin/admin
  # login forces a password change on first visit — credentials are
  # mutable state on the box, not in this file.
  services.grafana = {
    enable = true;
    settings.server = {
      http_addr = "0.0.0.0";
      http_port = 3001;
    };
    # Generated on first boot into /var/lib/grafana (not the Nix store,
    # which is world-readable) and referenced via Grafana's file provider.
    settings.security.secret_key = "$__file{/var/lib/grafana/secret_key}";
    provision.datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://localhost:9090";
        isDefault = true;
      }
    ];
    # Dashboards are checked into this repo as JSON (nixos/grafana-dashboards/)
    # rather than built by hand in the UI, so they survive a reinstall.
    provision.dashboards.settings.providers = [
      {
        name = "default";
        options.path = ./grafana-dashboards;
      }
    ];
  };

  systemd.services.grafana.preStart = ''
    if [ ! -f /var/lib/grafana/secret_key ]; then
      ${pkgs.openssl}/bin/openssl rand -hex 32 > /var/lib/grafana/secret_key
      chmod 600 /var/lib/grafana/secret_key
    fi
  '';

  # Front door for self-hosted services (issue #22). Remote access already
  # goes through the tailnet, so TLS uses a Tailscale-issued cert for this
  # box's own MagicDNS name rather than public Let's Encrypt (no domain, no
  # port-forwarding needed). Each service gets its own port behind that one
  # cert — e.g. https://nixos.tail70aa47.ts.net:8443 — rather than sub-paths
  # or subdomains, so every app sees itself as running at "/" and nothing
  # needs reverse-proxy base-path config. The planned Homepage dashboard
  # (issue #27) is what actually hides the port numbers from day-to-day use.
  #
  # One-time manual step (can't be expressed declaratively — it's a setting
  # on Tailscale's hosted control plane, not this box): enable "HTTPS
  # Certificates" for this tailnet in the Tailscale admin console before
  # `tailscale cert` below will succeed.
  services.caddy = {
    enable = true;
    # We supply certs manually via `tls cert_file key_file` on each site
    # below, so Caddy's automatic-HTTPS machinery (which otherwise also
    # grabs port 80 for an HTTP->HTTPS redirect) isn't needed — and port 80
    # is already taken by AdGuard Home's web UI.
    globalConfig = ''
      auto_https off
    '';
    virtualHosts."nixos.tail70aa47.ts.net:8443" = {
      extraConfig = ''
        tls /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.crt /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.key
        reverse_proxy localhost:3001
      '';
    };
    virtualHosts."nixos.tail70aa47.ts.net:8444" = {
      extraConfig = ''
        tls /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.crt /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.key
        reverse_proxy localhost:80
      '';
    };
    virtualHosts."nixos.tail70aa47.ts.net:8445" = {
      extraConfig = ''
        tls /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.crt /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.key
        reverse_proxy localhost:8384
      '';
    };
  };

  # Caddy needs the cert to already exist on its first start.
  systemd.services.caddy = {
    after = [ "tailscale-cert.service" ];
    wants = [ "tailscale-cert.service" ];
  };

  systemd.services.tailscale-cert = {
    description = "Issue/renew the Tailscale TLS cert used by Caddy";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail
      mkdir -p /var/lib/tailscale-certs
      ${pkgs.tailscale}/bin/tailscale cert \
        --cert-file=/var/lib/tailscale-certs/nixos.tail70aa47.ts.net.crt \
        --key-file=/var/lib/tailscale-certs/nixos.tail70aa47.ts.net.key \
        nixos.tail70aa47.ts.net
      chown caddy:caddy /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.crt /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.key
      chmod 640 /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.crt /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.key
      systemctl try-reload-or-restart caddy.service
    '';
  };

  # Tailscale certs are short-lived; keep them renewed without hands-on-box.
  systemd.timers.tailscale-cert = {
    description = "Periodic renewal of the Tailscale TLS cert for Caddy";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "12h";
    };
  };

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
    file = ./secrets/syncthing-gui-password.age;
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
