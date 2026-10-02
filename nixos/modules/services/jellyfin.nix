{ pkgs, ... }:

{
  # Media server (issue #23). GUI/streaming reached via Caddy on :8446, same
  # pattern as Syncthing — not opened directly. Media library lives on the
  # free space on the single root disk (no separate media partition); garro
  # is in the "jellyfin" group (./users.nix) so files can be copied in
  # without sudo.
  #
  # Hardware transcode: this box's iGPU (Intel HD 2500/4000, Ivy Bridge —
  # see SPECS.md) is Gen7, which the modern `intel-media-driver` (iHD)
  # doesn't support (Broadwell/Gen8+ only) — it needs the older
  # `intel-vaapi-driver` (i965) instead, and only has H.264 hardware
  # encode/decode, no HEVC/AV1.
  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.intel-vaapi-driver ];
  };

  services.jellyfin = {
    enable = true;
    openFirewall = false;
    user = "jellyfin";
    group = "jellyfin";
    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/renderD128";
    };
    transcoding.enableHardwareEncoding = true;
  };

  # Device node for /dev/dri is root:render by default; jellyfin's own
  # DeviceAllow only grants the cgroup permission, the process's own
  # user/group still needs this to actually open the device.
  users.users.jellyfin.extraGroups = [ "render" "video" ];

  # /srv/media (setgid, group-writable) is Jellyfin's media library (#23) —
  # garro is in the "jellyfin" group so files can be copied in without sudo.
  systemd.tmpfiles.rules = [
    "d /srv/media 2775 jellyfin jellyfin -"
  ];
}
