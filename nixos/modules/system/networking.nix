{ ... }:

{
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

  # Base firewall: just SSH. Each service module below opens the ports it
  # actually needs (NixOS merges these allowedTCPPorts/allowedUDPPorts lists
  # across all the imported modules).
  networking.firewall.allowedTCPPorts = [ 22 ];
}
