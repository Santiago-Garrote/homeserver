{ ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # This system is managed via the flake in this same directory.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
