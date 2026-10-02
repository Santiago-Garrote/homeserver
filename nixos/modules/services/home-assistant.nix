{ ... }:

{
  # Home automation (issue #26). GUI reached via Caddy on :8447, same pattern
  # as Syncthing/Jellyfin. `openFirewall` is left at its default (false)
  # since direct access isn't needed, only via Caddy.
  #
  # `config` only declares what's needed for that reverse-proxy setup to
  # work at all: Home Assistant's http component 400s on requests carrying
  # an X-Forwarded-For header from a proxy it doesn't trust (confirmed by
  # testing through Caddy without this). `default_config = {}` restores the
  # same default integration set Home Assistant would otherwise bootstrap
  # into configuration.yaml itself on first run. None of this touches the
  # onboarding wizard (admin user, location, etc.) — that lives in
  # `.storage/`, not configuration.yaml, so it still runs normally on first
  # visit, same "mutable state via web UI" pattern as AdGuard/Grafana.
  services.home-assistant = {
    enable = true;
    config = {
      default_config = { };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [ "127.0.0.1" "::1" ];
      };
    };
  };
}
