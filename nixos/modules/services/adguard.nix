{ ... }:

{
  # LAN-wide DNS ad-blocking + local DNS. Web UI moved to :80 after the
  # setup wizard (admin user + upstream DNS servers were chosen there) —
  # those choices are stored in mutable state on the box
  # (/var/lib/AdGuardHome), not in this file.
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
  };

  # 53: DNS. 80: web UI (post-wizard). 3000: AdGuard's own pre-wizard setup port.
  networking.firewall.allowedTCPPorts = [ 53 80 3000 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
