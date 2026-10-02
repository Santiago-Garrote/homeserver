{ ... }:

{
  # Remote access + subnet router: lets any device on your tailnet reach
  # the whole home LAN (e.g. the router at 192.168.1.1) once connected,
  # not just this server. `useRoutingFeatures = "server"` sets the needed
  # ip_forward sysctls automatically.
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.firewall.allowedUDPPorts = [ 41641 ];
}
