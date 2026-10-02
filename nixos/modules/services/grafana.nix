{ pkgs, ... }:

{
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
        options.path = ../../grafana-dashboards;
      }
    ];
  };

  systemd.services.grafana.preStart = ''
    if [ ! -f /var/lib/grafana/secret_key ]; then
      ${pkgs.openssl}/bin/openssl rand -hex 32 > /var/lib/grafana/secret_key
      chmod 600 /var/lib/grafana/secret_key
    fi
  '';

  networking.firewall.allowedTCPPorts = [ 3001 ];
}
