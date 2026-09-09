# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal NixOS + home-manager flake configuration for `babbaj`, covering two machines:

- **`nixosConfigurations.nixos`** (x86_64-linux) — the primary desktop, built from `PC/`. This is the main system these files target.
- **`darwinConfigurations.soybook`** (aarch64-darwin, nix-darwin) — a MacBook, built from `macbook/macbook-config.nix`.

There is no application code here — everything is Nix modules, shell scripts embedded in Nix, and a handful of source patches. Changes are evaluated/applied directly on the target machine, not via CI.

## Commands

Build/switch the Linux system (run as root, from this directory since it's `/etc/nixos`):
```
nixos-rebuild switch --flake .#nixos
```

Build without switching — the normal sanity check before a switch:
```
nixos-rebuild build --flake .#nixos
```

Evaluate only, no build:
```
nix eval .#nixosConfigurations.nixos.config.system.build.toplevel
```

Update flake inputs:
```
nix flake update                        # all inputs
nix flake lock --update-input <name>    # single input
```

macOS side (via nix-darwin):
```
darwin-rebuild switch --flake .#soybook
```

`nix flake check` evaluates every output including `darwinConfigurations`, so it is not a useful gate here — see "Known breakage" below. There is no test suite, linter, or CI; correctness is "does it evaluate and does the system come up correctly."

## Structure

- `flake.nix` — single source of truth for inputs and outputs. Defines a patched `nixpkgs` and a patched `home-manager` (both via `pkgs.applyPatches` — see the gotcha below), the package overlays (custom `gb-backup`, `prismlauncher` with extra JDKs, `looking-glass-client` built from the `looking-glass-src` flake input, `steam` with `-noreactlogin`, `helvum` from the stable channel, `nix-alien`, an `obs-studio-plugins.looking-glass-obs` fixup), and the two system outputs. New overlays and package overrides go here, not in the host modules.
- `PC/` — the desktop. `PC/default.nix` is the entry point: the `imports` list plus host identity (hostname, locale, user account, home-manager wiring, `system.stateVersion`). Everything else is one concern per file:
  - `boot.nix` — kernel package, loader, kernel modules/params, sysctl, pam limits
  - `networking.nix` — NetworkManager, firewall, `/etc/hosts` handling, the loopback dnsmasq resolver
  - `desktop.nix` — X11/nvidia, COSMIC + GNOME, gdm, Qt theming, fonts, portals
  - `services.nix` — vaultwarden, postgresql, openssh, plex, tailscale, mullvad, docker, openrazer, udev rules
  - `packages.nix` — the whole of `environment.systemPackages`, plus the `/etc/jdk*` links for IntelliJ
  - `audio.nix` — pipewire; `metrics.nix` — prometheus; `samba.nix`; `wireguard.nix`; `user-services.nix` — personal systemd *user* units
  - `nix.nix` — nix daemon settings, shared with the macOS host
  - `vm/` — VFIO GPU passthrough: `default.nix`, the `looking-glass.nix` module, `gpu-idle-vm.nix` (a standalone VM built as a runnable package), and `fix-vfio-troll.patch`
  - `mic/` — push-to-talk and pipewire autolink, with the two Rust helper derivations and `pw-loopback-nodes.conf`
- `home/` — home-manager modules for `babbaj`, entry point `home/home.nix`, one file per tool, imported explicitly from `home.nix`'s `imports`. **Shared between the Linux desktop and the macOS config** — keep it platform-agnostic, guarding Linux-only bits with `pkgs.stdenv.hostPlatform.isLinux` (see `i3.nix`, `easyeffects.nix`, `steam-proton.nix` for the pattern).
- `pkgs/` — custom derivations: `gb-backup/` (Go build from the `gb-src` flake input), `looking-glass/`, and `obs.nix` (a wrapped OBS plus its autostart item, imported by `PC/packages.nix`).
- `secrets/` — `agenix`-encrypted secrets (`*.age`). `secrets/secrets.nix` declares which SSH key can decrypt each one. Edit with `agenix -e <file>.age`, never by hand.
- `macbook/` — nix-darwin config: Homebrew casks/brews for GUI apps not well packaged in nixpkgs, Dock setup, TouchID sudo, plus its own wireguard.

## Conventions

- One concern per file, imported explicitly from `PC/default.nix`. Don't grow `default.nix` back into a monolith — if something doesn't fit an existing file, add a new one.
- Package additions go into the matching group in `PC/packages.nix` (`ides`, `dev-tools`, `shell-tools`, `cli-tools`, `nix-tools`, `apps`), not appended to the end of the final list.
- Prefer overlays in `flake.nix` for package modifications (version pins, patches, build-flag overrides) over ad-hoc `overrideAttrs` in host modules.
- Keep a patch next to the module that applies it (`PC/vm/fix-vfio-troll.patch`), referenced by relative path.
- Commented-out config is commonly left in place rather than deleted when it's something that might come back — but prefer deleting when it's genuinely dead, and say so.

## Gotchas

These are non-obvious and have each caused real breakage or silent rebuilds.

- **Flakes ignore untracked files.** A new module must be `git add`ed before `nixos-rebuild` can see it, or you get a confusing "path does not exist in Git repository" error. This applies to every new file.
- **The `imports` order in `PC/default.nix` is load-bearing.** NixOS collects option definitions in *reverse breadth-first* import order (`filterModules` uses `genericClosure`). The five modules carved out of the original monolithic `configuration.nix` are listed first specifically so their definitions land where the single file's did. This matters for order-sensitive options — `environment.systemPackages`, `boot.extraModprobeConfig`, `services.udev.extraRules`. Reordering imports silently rebuilds the closure.
- **The empty `patches = [ ]` in `applyPatches` is not a no-op.** It gives nixpkgs and home-manager distinct store paths; `pkgs.path` — and therefore `/etc/nixpkgs-link` — points at the patched one. Deleting the wrapper changes the system closure.
- **Strings that look like comments often aren't.** The `#` lines inside `services.udev.extraRules` are written into the generated rules file, and the empty `egl = { }` in the Looking Glass settings emits an `[egl]` INI section. Deleting either changes the build.
- **`enable = false` units are still materialized** as symlinks to `/dev/null`. The disabled jobs in `PC/user-services.nix` are deliberately declared rather than deleted; removing one is not equivalent to disabling it.
- **`hardware.openrazer` is declared twice on purpose** — in `PC/hardware.nix` and `PC/services.nix`. `users` is a plain list and is *not* deduplicated, so it currently evaluates to `[ "babbaj" "babbaj" ]`. This is almost certainly an unintended bug, but fixing it changes the closure, so it's left with a comment until someone wants the rebuild.
- **The store path label contains the git revision.** `system.nixos.versionSuffix` is derived from `self.shortRev`/`lastModifiedDate`, so a dirty tree builds to `...-dirty` and committing changes the path even when nothing else did. When checking whether a change is closure-neutral, compare two builds made at the same git state, or override `system.nixos.versionSuffix` with `lib.mkForce` on both sides before comparing `.drvPath`.

## Known breakage

- `darwinConfigurations.soybook` does not currently evaluate. nix-darwin removed `services.nix-daemon.enable`, `nix.configureBuildUsers`, and `security.pam.enableSudoTouchIdAuth`; `macbook/macbook-config.nix` still sets all three. This predates the module reorganization.
