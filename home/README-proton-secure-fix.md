# Proton secure-mode fix (Counter-Strike: Source & other Source games)

## The problem

Under Proton, Source-engine games launch in **insecure mode** and can't join
secure servers. The engine asks Steam to verify the signature of its own
`client.dll` / `server.dll`, Steam replies "no valid signature," and the engine
disables secure servers. The native Linux build never does this check, so it
isn't affected.

## The fix

These scripts build a **patched copy** of a Proton compatibility tool whose
`lsteamclient.so` forces the signature check to report *valid* — but only for
that one check (Steam callback id 705, `CheckFileSignature_t`). Every other
Steam call is untouched. Your original Proton is left alone; the patched build
is installed as a **separate** compatibility tool.

Two scripts are provided:

| Script | Use |
|---|---|
| `proton-secure-fix.sh` | **Generalized.** Adapts to the Proton build by disassembling the library. Use this one. |
| `proton-css-secure-fix.sh` | Original, hardcoded to the exact GE-Proton10-34 build. Kept as a fallback. |

Requires `python3`, `objdump`, `readelf` (binutils) on `PATH`.

---

## Quick start

```sh
# Patch the default GE-Proton10-34 into a new tool "GE-Proton10-34-securefix"
/etc/nixos/home/proton-secure-fix.sh
```

Then:

1. **Fully restart Steam** (tray → Exit, relaunch). Steam only scans for new
   compatibility tools at startup.
2. Right-click the game → **Properties → Compatibility**.
3. Tick **Force the use of a specific Steam Play compatibility tool** and pick
   **"GE-Proton10-34 (secure fix)"**.
4. Launch and join a secure server.

---

## Options

```sh
proton-secure-fix.sh [SOURCE] [TOOLNAME]
```

- **SOURCE** — a compatibility-tool name under
  `~/.local/share/Steam/compatibilitytools.d/`, or a path to a Proton
  directory. Default: `GE-Proton10-34`.
- **TOOLNAME** — name of the patched tool to create. Default:
  `<SOURCE>-securefix`.

Examples:

```sh
# Patch a different installed Proton version
proton-secure-fix.sh GE-Proton9-26

# Patch a Proton dir by path, name the result yourself
proton-secure-fix.sh /path/to/GE-ProtonX-Y my-secure-proton
```

The script prints what it found and patched, e.g.:

```
patched ISteamUtils_SteamUtils010_GetAPICallResult: Rargs=rbx Xret=0x8 Zicb=0x1d Rbuf=r12 cave@0x13ee93
```

If it can't confidently match the code it **skips that function**, and if nothing
matches it **refuses to write** — it never corrupts a binary. Re-running just
rebuilds the tool.

---

## Verify it worked

Set the game's launch options to `PROTON_LOG=1 %command%`, launch to the main
menu, quit, then check `~/steam-240.log` (240 = the game's AppID). You want to
**not** see:

```
No valid signature found for ... client.dll
Loading unsigned module client.dll ... Access to secure servers is disabled.
```

Clear the `PROTON_LOG=1` launch option afterwards — it writes a large log each
launch.

---

## Revert

- In the game's **Properties → Compatibility**, switch back to the unpatched
  Proton (untick the force option, or pick the original tool).
- Optionally delete the patched tool:
  `rm -rf ~/.local/share/Steam/compatibilitytools.d/GE-Proton10-34-securefix`

---

## When Proton updates

The patch is tied to the exact library build:

- **Same version, new Nix store path** (e.g. after `nixos-rebuild`): just
  re-run the script — it follows the `GE-Proton10-34` symlink to the new path.
- **New version** (GE-Proton10-35, 9-x, …): re-run
  `proton-secure-fix.sh <new-version>`. The generalized script re-derives all
  offsets, so it should just work. If upstream ever changes the shape of
  `GetAPICallResult`, it will refuse rather than mispatch — tell whoever
  maintains this to recheck.

---

## Scope & caveats

- Patches the **x86_64 unix** `lsteamclient.so` — covers 64-bit Windows Source
  games (CS:S). 32-bit-only titles (the `i386-unix` library / wow64 thunks) are
  not handled.
- The gate is by **callback type**, not by file hash: within the patched tool,
  *any* DLL the game sign-checks is reported valid, not only the genuine ones.
  For a game whose anti-cheat is defunct this is harmless, but it means the tool
  should be used only for that purpose.
- Not upstreamable — it deliberately defeats an integrity check. Keep it as a
  personal patched tool; don't submit it to Proton/GE.
- `css-secure-fix.patch` is the equivalent change as Proton **source** (against
  `lsteamclient/unix_steam_utils_manual.cpp`), for building proton-ge from
  source. Nobody packages a source build of proton-ge in Nix, so the binary
  patch above is the practical route.
```
