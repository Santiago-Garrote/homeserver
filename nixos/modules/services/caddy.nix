{ pkgs, ... }:

{
  # Front door for self-hosted services (issue #22). Remote access already
  # goes through the tailnet, so TLS uses a Tailscale-issued cert for this
  # box's own MagicDNS name rather than public Let's Encrypt (no domain, no
  # port-forwarding needed). Each service gets its own port behind that one
  # cert — e.g. https://nixos.tail70aa47.ts.net:8443 — rather than sub-paths
  # or subdomains, so every app sees itself as running at "/" and nothing
  # needs reverse-proxy base-path config. The Homepage dashboard (see
  # ./homepage.nix, issue #27) sits on the bare hostname at the standard
  # HTTPS port instead, and is what actually hides the other services' port
  # numbers from day-to-day use.
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
    virtualHosts."nixos.tail70aa47.ts.net:8446" = {
      extraConfig = ''
        tls /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.crt /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.key
        reverse_proxy localhost:8096
      '';
    };
    virtualHosts."nixos.tail70aa47.ts.net:8447" = {
      extraConfig = ''
        tls /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.crt /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.key
        reverse_proxy localhost:8123
      '';
    };
    # No port here, unlike the others — this is the one address people
    # actually type (https://nixos.tail70aa47.ts.net with nothing after
    # it), so it gets the standard HTTPS port instead of a high one.
    virtualHosts."nixos.tail70aa47.ts.net" = {
      extraConfig = ''
        tls /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.crt /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.key
        reverse_proxy localhost:8082
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

  networking.firewall.allowedTCPPorts = [ 443 8443 8444 8445 8446 8447 ];
}
