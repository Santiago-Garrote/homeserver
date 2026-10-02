{ ... }:

{
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  # Setup OpenSSH
  services.openssh.settings = {
    PasswordAuthentication = true;
    ClientAliveInterval = 30;
    ClientAliveCountMax = 3;
  };
}
