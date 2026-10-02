{ pkgs, ... }:

{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     git
     vim
     htop
     tmux
     curl
     lf
     chafa
     fbv
     file
  ];
}
