# homeserver specs

Gathered 2026-09-29 via SSH (`hostnamectl`, `lscpu`, `free`, `lsblk`, `lspci`).

## Machine

- **Board:** ASUS H61M-K (desktop, firmware from 2013 — no meaningful hardware upgrades expected)
- **CPU:** Intel Core i3-3240 @ 3.40GHz (Ivy Bridge, 2 cores / 4 threads)
- **GPU:** Intel HD Graphics 2500/4000 (integrated) — supports Intel Quick Sync Video, but only H.264 hardware encode/decode (no HEVC/AV1 QSV on this generation)
- **RAM:** 11 GiB (+ 8.2 GiB swap)
- **Network:** Gigabit Ethernet (Realtek RTL8111/8168), static IP `192.168.1.29`

## Storage

- `sda`: 465.8 GB disk, GPT
  - `/boot`: 1 GB, vfat
  - `/`: 456.6 GB ext4 (**422 GB free** of it)
  - swap: 8.2 GB
- Single disk, no RAID/redundancy — no protection against drive failure.

## OS

- NixOS 25.11 "Xantusia", kernel 6.12.90
- **⚠️ Support for 25.11 ended 2026-06-30 — this release is currently unsupported (no security patches).** Worth planning an upgrade to a current release (e.g. via `system.stateVersion` stays, but bump the nixpkgs channel/flake input) separately from other work.

## What this realistically supports

Good fit — modest, low-power desktop hardware, fine for always-on lightweight services:
- Several concurrent Docker containers (Pi-hole/AdGuard, Home Assistant, Syncthing, a reverse proxy, small web apps, a git server, monitoring/dashboards)
- Media serving (Jellyfin/Plex) with **H.264-only** hardware-accelerated transcoding — fine for most phones/browsers/TVs, but transcoding 4K/HEVC sources will fall back to slow CPU transcoding
- File sync / small NAS-style storage (422 GB usable) — fine for documents, photos, config backups; not a large media library or object-storage-scale workload

Poor fit:
- Anything needing serious CPU throughput (heavy CI, ML/compute, many simultaneous transcodes)
- Storage-heavy or redundant storage needs (single disk, no RAID — a drive failure loses everything on it)
- GPU compute (integrated graphics only)

## Open question

No redundancy on the single 465 GB disk — if backups/durability matter for whatever gets put on here, worth deciding a backup destination (another machine, cloud, external drive) before storing anything irreplaceable on it.
