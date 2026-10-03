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
    #
    # default_sni: browsers never send a TLS SNI value when connecting to a
    # literal IP (RFC 6066 disallows it), but :443 is shared by multiple
    # sites here and Caddy normally relies on SNI to pick which one's cert
    # to present. Without this, the IP-literal site below fails the TLS
    # handshake outright. This tells Caddy to serve that site's cert when
    # no SNI is given.
    globalConfig = ''
      auto_https off
      default_sni 192.168.1.29
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
    virtualHosts."nixos.tail70aa47.ts.net:8448" = {
      extraConfig = ''
        tls /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.crt /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.key
        reverse_proxy localhost:8080
      '';
    };
    virtualHosts."nixos.tail70aa47.ts.net:8449" = {
      extraConfig = ''
        tls /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.crt /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.key
        reverse_proxy localhost:8989
      '';
    };
    virtualHosts."nixos.tail70aa47.ts.net:8450" = {
      extraConfig = ''
        tls /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.crt /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.key
        reverse_proxy localhost:7878
      '';
    };
    virtualHosts."nixos.tail70aa47.ts.net:8451" = {
      extraConfig = ''
        tls /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.crt /var/lib/tailscale-certs/nixos.tail70aa47.ts.net.key
        reverse_proxy localhost:9696
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
    # Same dashboard, reachable by typing the LAN IP directly — no
    # Tailscale/MagicDNS needed when already at home. The Tailscale cert
    # above only covers the tailnet hostname, not this LAN IP, so this site
    # gets its own self-signed cert (see lan-cert.service below); browsers
    # will flag it as self-signed on first visit from the LAN, which is
    # expected.
    #
    # Deliberately not `tls internal` (Caddy's built-in self-signed-cert
    # issuer): in this unprivileged deployment it tries and fails to
    # install its local CA into the OS trust store, and that failure
    # breaks certificate issuance for the site entirely (TLS handshake
    # fails with "internal error") — a known upstream Caddy bug where
    # `skip_install_trust` doesn't actually suppress the attempt
    # (caddyserver/caddy#7211). A plain self-signed cert via `tls
    # cert_file key_file` sidesteps that code path altogether.
    virtualHosts."192.168.1.29" = {
      extraConfig = ''
        tls /var/lib/caddy-lan-cert/lan.crt /var/lib/caddy-lan-cert/lan.key
        reverse_proxy localhost:8082
      '';
    };
    # Same dashboard again, this time by a memorable local name instead of
    # the raw IP. Resolving server.home -> 192.168.1.29 is handled by
    # AdGuard Home's DNS rewrites (its own mutable config, same as the
    # rest of that service — see ./adguard.nix), not anything here. Unlike
    # the IP site above, a hostname means browsers DO send SNI, so this
    # needs its own explicit site (the lan.crt below covers both via SAN).
    virtualHosts."server.home" = {
      extraConfig = ''
        tls /var/lib/caddy-lan-cert/lan.crt /var/lib/caddy-lan-cert/lan.key
        reverse_proxy localhost:8082
      '';
    };
  };

  # Caddy needs the certs to already exist on its first start.
  systemd.services.caddy = {
    after = [ "tailscale-cert.service" "lan-cert.service" ];
    wants = [ "tailscale-cert.service" "lan-cert.service" ];
  };

  # One-time self-signed cert covering both ways of reaching the dashboard
  # from the LAN (raw IP and the server.home name) — see the two
  # virtualHosts above. Generated once and left alone — it's for
  # LAN-only convenience, not a security boundary, so a long validity
  # window beats the complexity of a renewal timer.
  systemd.services.lan-cert = {
    description = "Generate a self-signed TLS cert for LAN access to Caddy";
    after = [ "network.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail
      mkdir -p /var/lib/caddy-lan-cert
      if [ ! -f /var/lib/caddy-lan-cert/lan.crt ]; then
        ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:2048 -nodes \
          -keyout /var/lib/caddy-lan-cert/lan.key \
          -out /var/lib/caddy-lan-cert/lan.crt \
          -days 3650 \
          -subj "/CN=server.home" \
          -addext "subjectAltName=DNS:server.home,IP:192.168.1.29"
      fi
      chown caddy:caddy /var/lib/caddy-lan-cert/lan.crt /var/lib/caddy-lan-cert/lan.key
      chmod 640 /var/lib/caddy-lan-cert/lan.key
    '';
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

  networking.firewall.allowedTCPPorts = [ 443 8443 8444 8445 8446 8447 8448 8449 8450 8451 ];
}
