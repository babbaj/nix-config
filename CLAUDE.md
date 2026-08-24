# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal NixOS + home-manager flake configuration for `babbaj`, covering two machines:

- **`nixosConfigurations.nixos`** (x86_64-linux) — the primary desktop, built from `configuration.nix`. This is the main system these files target.
- **`darwinConfigurations.soybook`** (aarch64-darwin, nix-darwin) — a MacBook, built from `macbook/macbook-config.nix`.

There is no application code here — everything is Nix modules, shell scripts embedded in Nix, and a handful of source patches. Changes are evaluated/applied directly on the target machine, not via CI.

## Commands

Build/switch the Linux system (run as root, from this directory since it's `/etc/nixos`):
```
nixos-rebuild switch --flake .#nixos
```

Build without switching (useful to check the config evaluates/builds):
```
nixos-rebuild build --flake .#nixos
```

Just check the flake evaluates (fast sanity check, no build):
```
nix flake check
```
```
nix eval .#nixosConfigurations.nixos.config.system.build.toplevel
```

Update flake inputs:
```
nix flake update            # all inputs
nix flake lock --update-input <name>   # single input
```

macOS side (from `macbook/`, via nix-darwin):
```
darwin-rebuild switch --flake .#soybook
```

There is no test suite, linter, or CI in this repo — correctness is "does it evaluate and does the system come up correctly," typically verified with `nixos-rebuild build` before `switch`.

## Structure

- `flake.nix` — single source of truth for inputs and outputs. Defines a patched `nixpkgs` (via `pkgs.applyPatches`, currently no active patches) and a patched `home-manager`, several package overlays (custom `gb-backup`, `prismlauncher` with extra JDKs, patched `looking-glass-client` pinned to a specific commit, `steam` with `-noreactlogin`, `helvum` pulled from the stable channel, `nix-alien`), and the two `nixosConfigurations`/`darwinConfigurations` outputs. When adding a new overlay or override, it goes in the `overlays` list here, not in `configuration.nix`.
- `configuration.nix` — the main NixOS module: boot/kernel, networking (VLANs, dnsmasq DHCP on a tagged sub-interface, firewall), desktop environment (COSMIC + GNOME both enabled, gdm as display manager), services (vaultwarden, postgresql, plex, tailscale, mullvad, openrazer, ratbagd, docker), and the large `environment.systemPackages` list. That package list is grouped into local `let`-bound lists (`ides`, `dev-tools`, `shell-tools`, `cli-tools`, `nix-tools`, `cosmic-stuff`, plus an inline VM package pulled from `gpu-idle-vm.nix`) — add new packages to the group that matches their purpose rather than appending to the final list.
- `configuration.nix` imports a set of top-level `.nix` files, each owning one concern: `hardware.nix` (generated hardware scan), `wireguard.nix`, `vm-setup.nix` (VFIO/looking-glass GPU passthrough VM, imports `looking-glass-module.nix`), `scripts.nix` (systemd **user** services — backup/log-sync jobs, mostly disabled), `pipewire.nix`, `metrics.nix`, `nix.nix`, `mic-setup/mic-setup.nix`, `smb.nix`.
- `home/` — home-manager modules for the `babbaj` user, entry point `home/home.nix`, one file per tool (`zsh.nix`, `git.nix`, `kitty.nix`, `nnn.nix`, `i3.nix`, `starship.nix`, etc.), imported explicitly in `home.nix`'s `imports` list. This module tree is shared between the Linux desktop and the macOS config — `vm-setup.nix` and `macbook/macbook-config.nix` both import `../home/home.nix` directly, so keep it platform-agnostic (guard Linux-only bits with `pkgs.stdenv.isLinux` if needed).
- `pkgs/` — custom package derivations built via overlays or `callPackage`: `gb-backup` (Go build of a private backup tool, from the `gb-src` flake input), `looking-glass/` (patches + OBS plugin for Looking Glass), `soundux/`, `sysmontask/` (patched with `poz.patch`, `troll.nix` for the trolled variant).
- Top-level `*.patch` / `*.diff` files are source patches applied to specific derivations — they're referenced by relative path from the `.nix` file that consumes them (e.g. `fix-vfio-troll.patch` → `vm-setup.nix` kernel patch, `nnn-patch.diff` → `home/nnn.nix`, `obs-notify-patch.patch` → `obs.nix`). Keep a patch next to the module that applies it, or reference it explicitly if it lives elsewhere.
- `secrets/` — `agenix`-encrypted secrets (`*.age`). `secrets/secrets.nix` declares which SSH public key(s) can decrypt each secret; edit secrets with `agenix -e <file>.age`, never by hand.
- `macbook/` — nix-darwin config for the MacBook: `macbook-config.nix` (Homebrew casks/brews for GUI apps not well-packaged in nixpkgs, Dock setup via `dockutil`, TouchID sudo) plus its own `wireguard.nix`.
- `gpu-idle-vm.nix` — a separate NixOS VM configuration (built via `import "${modulesPath}/../"` in `configuration.nix`) used to idle/manage a secondary GPU; not part of the main system closure directly, it's built as a runnable VM package.

## Conventions to follow

- One concern per file, imported explicitly from a parent module — don't cram unrelated settings into `configuration.nix` when a focused module already exists or would be clearer.
- Package additions to `environment.systemPackages` go into the matching category list inside `configuration.nix`'s `let` block (dev tool → `dev-tools`, CLI utility → `cli-tools` or `shell-tools`, GUI app → the trailing list built with the `gpu-vm` binding, etc.).
- Prefer overlays in `flake.nix` for package modifications (version pins, patches, build flag overrides) over ad-hoc `pkgs.foo.overrideAttrs` scattered through `configuration.nix`, mirroring how `looking-glass-client`, `steam`, `prismlauncher`, etc. are already handled.
- Disabled/experimental config is commonly left in place but commented out (see `flake.nix` inputs, `configuration.nix` imports, `scripts.nix` services with `enable = false`) rather than deleted — follow that pattern when disabling something you're not sure you want to remove permanently.
- home-manager modules under `home/` must stay usable from both the NixOS host and the Darwin host — avoid assuming Linux-only paths/services without a platform guard.
