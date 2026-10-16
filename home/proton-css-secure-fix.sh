#!/usr/bin/env bash
# Rebuild a patched GE-Proton10-34 that reports a valid CheckFileSignature,
# so Source-engine games (CS:S) stay in secure mode under Proton.
#
# What it does:
#   1. Takes a pristine GE-Proton10-34 tree (default: the one Steam already has
#      registered via the GE-Proton10-34 compat-tool symlink).
#   2. Makes a full, dereferenced copy into a new compat tool
#      "GE-Proton10-34-cssfix" (nothing symlinks back to the read-only source).
#   3. Byte-patches files/lib/wine/x86_64-unix/lsteamclient.so so the
#      CheckFileSignature_t callback (id 705) result is forced to
#      ValidSignature(1). Refuses to run if the binary isn't the expected build.
#   4. Writes the compat-tool manifest.
#
# After running: fully restart Steam, then set CS:S -> Properties ->
# Compatibility to "GE-Proton10-34 (CS:S secure fix)".
#
# NOTE: tied to the GE-Proton10-34 release build of lsteamclient.so. A different
# Proton version will fail the byte-pattern check (safe: it aborts, never
# corrupts). Only callback id 705 is universal across versions.
set -euo pipefail

SRC="${1:-$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton10-34}"
TOOL="${2:-$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton10-34-cssfix}"
SRC="$(readlink -f "$SRC")"
LIB_REL="files/lib/wine/x86_64-unix/lsteamclient.so"

[ -f "$SRC/$LIB_REL" ] || { echo "error: $SRC/$LIB_REL not found" >&2; exit 1; }

echo ">> source Proton: $SRC"
echo ">> target tool:   $TOOL"

# --- build the patched .so in a temp file, with safety checks ---
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SRC/$LIB_REL" "$TMP/orig.so"

python3 - "$TMP/orig.so" "$TMP/patched.so" <<'PY'
import struct, sys, shutil
src, dst = sys.argv[1], sys.argv[2]
shutil.copyfile(src, dst)
data = bytearray(open(dst, "rb").read())

CAVE_VA  = 0x13eda5     # unused space just after .fini, inside the exec segment
ENTRY_VA = 0x10412f     # inside ISteamUtils_SteamUtils010_GetAPICallResult
RET_136  = 0x104136     # success -> convert path
RET_15C  = 0x10415c     # fail / skip-convert path
# vaddr == file offset within the exec segment for this build

def rel32(target, instr_end):
    return struct.pack("<i", target - instr_end)

cave  = bytes.fromhex("884308")             # mov [rbx+0x8], al   (replicate)
cave += bytes.fromhex("84c0")               # test al, al
cave += bytes.fromhex("7416")               # je  .fail
cave += bytes.fromhex("817b1dc1020000")     # cmp dword [rbx+0x1d], 705 (CheckFileSignature_t)
cave += bytes.fromhex("7508")               # jne .to136
cave += bytes.fromhex("41c7042401000000")   # mov dword [r12], 1  (ValidSignature)
cave += b"\xe9" + rel32(RET_136, CAVE_VA + len(cave) + 5)   # jmp success/convert
cave += b"\xe9" + rel32(RET_15C, CAVE_VA + len(cave) + 5)   # jmp fail
assert len(cave) == 0x22

# --- safety: refuse anything that isn't the expected build ---
region = data[CAVE_VA:CAVE_VA+len(cave)]
if set(region) != {0}:
    sys.exit("cave region not empty -- not the expected GE-Proton10-34 lsteamclient.so")
orig = bytes.fromhex("884308" "84c0" "7426")
if data[ENTRY_VA:ENTRY_VA+7] != orig:
    sys.exit("entry bytes mismatch -- wrong Proton build; refusing to patch")

data[CAVE_VA:CAVE_VA+len(cave)] = cave
data[ENTRY_VA:ENTRY_VA+7] = b"\xe9" + rel32(CAVE_VA, ENTRY_VA+5) + b"\x90\x90"

# grow the exec LOAD segment (phdr index 1) to cover the cave
e_phoff = struct.unpack_from("<Q", data, 0x20)[0]
ph1 = e_phoff + 1*56
p_type, p_flags = struct.unpack_from("<II", data, ph1)
p_offset = struct.unpack_from("<Q", data, ph1+8)[0]
assert p_type == 1 and p_flags == 5 and p_offset == 0x64000, "unexpected exec segment"
new_size = (CAVE_VA + len(cave)) - p_offset
assert (CAVE_VA + len(cave)) < 0x13f000
struct.pack_into("<Q", data, ph1+32, new_size)   # p_filesz
struct.pack_into("<Q", data, ph1+40, new_size)   # p_memsz

open(dst, "wb").write(data)
print("   patched OK (%d bytes changed)" %
      sum(1 for a, b in zip(open(src,'rb').read(), data) if a != b))
PY

# --- build the compat tool as a full dereferenced copy ---
echo ">> copying Proton tree (dereferencing symlinks)..."
rm -rf "$TOOL"
cp -rL "$SRC" "$TOOL"
chmod -R u+w "$TOOL"

install -m 0755 "$TMP/patched.so" "$TOOL/$LIB_REL"

cat > "$TOOL/compatibilitytool.vdf" <<'VDF'
"compatibilitytools"
{
  "compat_tools"
  {
    "GE-Proton10-34-cssfix"
    {
      "install_path" "."
      "display_name" "GE-Proton10-34 (CS:S secure fix)"
      "from_oslist"  "windows"
      "to_oslist"    "linux"
    }
  }
}
VDF

echo ">> done."
echo "   Fully restart Steam, then set CS:S -> Properties -> Compatibility"
echo "   to \"GE-Proton10-34 (CS:S secure fix)\"."
