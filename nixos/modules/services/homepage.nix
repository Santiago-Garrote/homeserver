{ ... }:

{
  # Service launcher (issue #27) — last in the self-hosted set, since it's
  # only useful once the others exist. Reached via Caddy on the bare
  # hostname (standard :443, no port to type/remember) — the actual front
  # door the others' port numbers are hidden behind. `openFirewall` stays
  # false since direct access isn't needed. allowedHosts must match the
  # Host header browsers actually send — no port, since 443 is HTTPS's
  # default and browsers omit it from the Host header — or
  # homepage-dashboard 403s the request.
  services.homepage-dashboard = {
    enable = true;
    allowedHosts = "nixos.tail70aa47.ts.net";
    settings.title = "nixos";
    services = [
      {
        "Self-hosted" = [
          {
            "Grafana" = {
              icon = "grafana.png";
              href = "https://nixos.tail70aa47.ts.net:8443";
              description = "Metrics dashboard";
            };
          }
          {
            "AdGuard Home" = {
              icon = "adguard-home.png";
              href = "https://nixos.tail70aa47.ts.net:8444";
              description = "LAN DNS ad-blocking";
            };
          }
          {
            "Syncthing" = {
              icon = "syncthing.png";
              href = "https://nixos.tail70aa47.ts.net:8445";
              description = "File sync";
            };
          }
          {
            "Jellyfin" = {
              icon = "jellyfin.png";
              href = "https://nixos.tail70aa47.ts.net:8446";
              description = "Media server";
            };
          }
          {
            "Home Assistant" = {
              icon = "home-assistant.png";
              href = "https://nixos.tail70aa47.ts.net:8447";
              description = "Home automation";
            };
          }
        ];
      }
    ];
  };
}
