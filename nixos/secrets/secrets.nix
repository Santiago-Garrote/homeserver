# Recipients for every secret in this directory, read by the `agenix` CLI
# (when encrypting/editing from a workstation) and by the agenix NixOS
# module (when decrypting on the server at activation time). Both the
# server's own SSH host key and your personal SSH key are listed as
# recipients, so either one can decrypt: the server needs to for
# `nixos-rebuild` to place secrets at `/run/agenix/<name>`, and you need to
# for the `agenix -e`/`-r` workflow described in README.md to work from
# your own machine.
#
# These are *public* keys — safe to commit. agenix accepts plain SSH
# ed25519 public keys directly as recipients, no separate age-key
# conversion needed.
let
  server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOwWsS1tgUbeTCb+d282u3v6FUDXoUtG1xnp9z92SFKk root@nixos";
  garro = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPw2spu1+nTJ9D10HuOG99R0YKeKCpgtrWk5VYmdaxp2 santiagogarrote2005@gmail.com";

  allKeys = [ server garro ];
in
{
  # No secrets yet — this just wires up the tooling. Add one entry per
  # secret file, e.g.:
  #
  #   "syncthing-gui-password.age".publicKeys = allKeys;
  #
  # then from a machine with your own SSH key:
  #   cd nixos/secrets && agenix -e syncthing-gui-password.age
  # which opens $EDITOR, encrypts on save, and leaves the ciphertext ready
  # to commit.
}
