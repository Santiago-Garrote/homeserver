{ ... }:

{
  # Resource monitoring: Netdata collects CPU/RAM/disk/network metrics
  # locally (not claimed to Netdata Cloud). Note: nixpkgs' netdata package
  # ships the GPL'd agent/API only — the :19999 web dashboard is NOT
  # bundled, since that frontend is closed-source and normally pulled live
  # from app.netdata.cloud. So the actual dashboard is Prometheus+Grafana
  # (./grafana.nix), which scrape Netdata's local Prometheus-compatible
  # endpoint instead of using its web UI.
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

  networking.firewall.allowedTCPPorts = [ 19999 ];
}
