#!/usr/bin/env bash
# Generalized Proton secure-mode fix.
#
# Force ISteamUtils::GetAPICallResult to report a valid CheckFileSignature
# (callback id 705) so Source-engine games (CS:S etc.) stay in secure mode
# under Proton. Unlike proton-css-secure-fix.sh (hardcoded to GE-Proton10-34),
# this version disassembles the target library and adapts to whatever
# registers/offsets/addresses the build uses, so it works across Proton
# versions. It refuses to write if it can't confidently match the code.
#
# Usage:
#   proton-secure-fix.sh [SOURCE] [TOOLNAME]
#     SOURCE   compat-tool name under compatibilitytools.d, or a path to a
#              Proton dir. Default: GE-Proton10-34.
#     TOOLNAME name of the patched tool to create. Default: <SOURCE>-securefix.
#
# After running: fully restart Steam, then set the game -> Properties ->
# Compatibility to the new "<name> (secure fix)" tool.
#
# Requires: python3, objdump, readelf (binutils). Patches the x86_64 unix
# lsteamclient.so (covers 64-bit Windows Source games). Not upstreamable:
# deliberately defeats an integrity check.
set -euo pipefail

CTOOLS="$HOME/.local/share/Steam/compatibilitytools.d"
SRC_ARG="${1:-GE-Proton10-34}"
case "$SRC_ARG" in
  */*) SRC="$(readlink -f "$SRC_ARG")"; BASE="$(basename "$SRC_ARG")" ;;
  *)   SRC="$(readlink -f "$CTOOLS/$SRC_ARG")"; BASE="$SRC_ARG" ;;
esac
TOOLNAME="${2:-${BASE}-securefix}"
TOOL="$CTOOLS/$TOOLNAME"
LIB_REL="files/lib/wine/x86_64-unix/lsteamclient.so"

command -v python3 >/dev/null && command -v objdump >/dev/null && command -v readelf >/dev/null \
  || { echo "error: need python3, objdump, readelf" >&2; exit 1; }
[ -f "$SRC/$LIB_REL" ] || { echo "error: $SRC/$LIB_REL not found" >&2; exit 1; }

echo ">> source Proton: $SRC"
echo ">> new tool:      $TOOL  (display: \"$BASE (secure fix)\")"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/genpatch.py" <<'GENPATCH_EOF'
#!/usr/bin/env python3
"""Generalized patcher: force ISteamUtils::GetAPICallResult to report a valid
CheckFileSignature (callback id 705) in a Proton lsteamclient.so, for any build
whose GetAPICallResult still follows the standard hand-written shape.

It resolves the target functions by symbol, disassembles each via objdump,
reads the registers/offsets the compiler actually used, and emits an adapted
code cave. Refuses (never corrupts) anything it can't confidently match.
"""
import re, struct, subprocess, sys

CB_CHECKFILESIGNATURE = 705   # k_iSteamUtilsCallbacks(700) + 5; stable across versions

# ---------- ELF helpers ----------
class Elf:
    def __init__(self, data):
        self.d = bytearray(data)
        assert self.d[:4] == b"\x7fELF" and self.d[4] == 2, "not ELF64"
        self.e_phoff = struct.unpack_from("<Q", self.d, 0x20)[0]
        self.e_phentsize = struct.unpack_from("<H", self.d, 0x36)[0]
        self.e_phnum = struct.unpack_from("<H", self.d, 0x38)[0]
        self.phdrs = []
        for i in range(self.e_phnum):
            o = self.e_phoff + i*self.e_phentsize
            p_type, p_flags = struct.unpack_from("<II", self.d, o)
            p_offset, p_vaddr = struct.unpack_from("<QQ", self.d, o+8)
            p_filesz, p_memsz = struct.unpack_from("<QQ", self.d, o+32)
            self.phdrs.append(dict(i=i, off=o, type=p_type, flags=p_flags,
                                   p_offset=p_offset, p_vaddr=p_vaddr,
                                   p_filesz=p_filesz, p_memsz=p_memsz))
        self.exec_seg = next(p for p in self.phdrs
                             if p["type"] == 1 and (p["flags"] & 0x1))

    def va_to_off(self, va):
        s = self.exec_seg
        return va - s["p_vaddr"] + s["p_offset"]

    def grow_exec(self, new_end_va):
        s = self.exec_seg
        new_size = new_end_va - s["p_vaddr"]
        if new_size > s["p_filesz"]:
            struct.pack_into("<Q", self.d, s["off"]+32, new_size)  # p_filesz
            struct.pack_into("<Q", self.d, s["off"]+40, new_size)  # p_memsz
            s["p_filesz"] = s["p_memsz"] = new_size

    def cave_window(self):
        """Free space just past the exec segment content, up to the next
        segment's vaddr (bytes must currently be zero)."""
        s = self.exec_seg
        start = s["p_vaddr"] + s["p_filesz"]
        later = [p["p_vaddr"] for p in self.phdrs
                 if p["type"] == 1 and p["p_vaddr"] > start]
        limit = min(later) if later else (start + 0x1000)
        return start, limit

# ---------- symbol resolution ----------
def get_targets(path):
    out = subprocess.check_output(["readelf", "-sW", path], text=True)
    rx = re.compile(r"^\s*\d+:\s*([0-9a-f]+)\s+(\d+)\s+FUNC\s+\S+\s+\S+\s+\S+\s+"
                    r"(ISteamUtils_SteamUtils\d+_GetAPICallResult)\s*$")
    seen = {}
    for line in out.splitlines():
        m = rx.match(line)
        if m and not m.group(3).startswith("wow64_"):
            va, size, name = int(m.group(1), 16), int(m.group(2)), m.group(3)
            if size and name not in seen:
                seen[name] = (va, size)
    return seen

# ---------- disassembly & pattern extraction ----------
def disasm(path, va, size):
    out = subprocess.check_output(
        ["objdump", "-d", "--start-address=%d" % va,
         "--stop-address=%d" % (va+size), "-M", "intel", path], text=True)
    insns = []
    for line in out.splitlines():
        m = re.match(r"^\s*([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$", line)
        if m:
            insns.append((int(m.group(1), 16),
                          bytes.fromhex(m.group(2).replace(" ", "")),
                          m.group(3).strip()))
    return insns

def parse(insns):
    """Locate the '_ret store' triple and the surrounding register usage.
    Returns dict or None if the shape isn't recognized."""
    # native call = indirect call through the interface vtable
    call_i = next((i for i, (_, _, t) in enumerate(insns)
                   if re.match(r"call\s+QWORD PTR \[\w+\+0x[0-9a-f]+\]", t)), None)
    if call_i is None:
        return None
    # entry triple: mov [Rargs+Xret], al ; test al,al ; je TARGET
    ent = None
    for i in range(call_i+1, len(insns)-2):
        m = re.match(r"mov\s+BYTE PTR \[(\w+)\+0x([0-9a-f]+)\],al$", insns[i][2])
        if not m:
            continue
        if not re.match(r"test\s+al,al$", insns[i+1][2]):
            continue
        mj = re.match(r"je\s+([0-9a-f]+)", insns[i+2][2])
        if not mj:
            continue
        ent = dict(Rargs=m.group(1), Xret=int(m.group(2), 16),
                   entry_va=insns[i][0],
                   convert_va=insns[i+3][0] if i+3 < len(insns) else None,
                   je_target=int(mj.group(1), 16))
        break
    if not ent or ent["convert_va"] is None:
        return None
    # iCallbackExpected: mov r8d, [Rargs+Zicb] before the native call (5th arg)
    Zicb = None
    for va, _, t in insns[:call_i]:
        m = re.match(r"mov\s+r8d,DWORD PTR \[%s\+0x([0-9a-f]+)\]$" % ent["Rargs"], t)
        if m:
            Zicb = int(m.group(1), 16)
    # native callback buffer: mov rdx,<Rbuf> just before native call (3rd arg)
    Rbuf = None
    for va, _, t in insns[:call_i]:
        m = re.match(r"mov\s+rdx,(\w+)$", t)
        if m:
            Rbuf = m.group(1)
    if Zicb is None or Rbuf is None:
        return None
    ent.update(Zicb=Zicb, Rbuf=Rbuf)
    return ent

# ---------- minimal x86-64 encoder (only the forms we need) ----------
REG = {n: i for i, n in enumerate(
    ["rax","rcx","rdx","rbx","rsp","rbp","rsi","rdi",
     "r8","r9","r10","r11","r12","r13","r14","r15"])}

def enc_mem(opcode, reg_field, base, disp):
    """opcode(bytes) reg_field(int) [base+disp] -> bytes (32/8-bit operand, no REX.W)."""
    b = REG[base]
    rex = 0x40 | ((reg_field >= 8) << 2) | (b >= 8)
    rm = b & 7
    need_sib = (rm == 4)                 # rsp/r12 base
    if disp == 0 and rm != 5:            # rbp/r13 can't use mod=00
        mod, dispb = 0, b""
    elif -128 <= disp <= 127:
        mod, dispb = 1, struct.pack("<b", disp)
    else:
        mod, dispb = 2, struct.pack("<i", disp)
    modrm = (mod << 6) | ((reg_field & 7) << 3) | (4 if need_sib else rm)
    out = bytearray()
    if rex != 0x40:
        out.append(rex)
    out += bytes(opcode)
    out.append(modrm)
    if need_sib:
        out.append(0x24)                 # scale0 index=none base=rm
    out += dispb
    return bytes(out)

def rel32(target, ip_after):
    return struct.pack("<i", target - ip_after)

def build_cave(cave_va, e):
    """Assemble the adapted cave at cave_va; return bytes."""
    mov_ret = enc_mem([0x88], REG["rax"] & 7, e["Rargs"], e["Xret"])  # mov [Rargs+X],al (al=reg0)
    cmp_icb = enc_mem([0x81], 7, e["Rargs"], e["Zicb"]) + struct.pack("<i", CB_CHECKFILESIGNATURE)
    mov_valid = enc_mem([0xC7], 0, e["Rbuf"], 0) + struct.pack("<i", 1)  # mov dword[Rbuf],1
    # layout with two short jumps (je FAIL, jne TOCONV) then two rel32 jmps
    # sizes: mov_ret | 84 c0 | 74 r8 | cmp_icb | 75 r8 | mov_valid | e9 conv | FAIL: e9 target
    off = 0
    off += len(mov_ret)
    off += 2                       # test al,al
    je_at = off; off += 2          # je rel8
    cmp_at = off; off += len(cmp_icb)
    jne_at = off; off += 2         # jne rel8
    off += len(mov_valid)
    jconv_at = off; off += 5       # e9 rel32 -> convert_va
    fail_at = off; off += 5        # e9 rel32 -> je_target
    je_rel = fail_at - (je_at + 2)
    jne_rel = jconv_at - (jne_at + 2)
    assert 0 <= je_rel <= 127 and 0 <= jne_rel <= 127
    cave = bytearray()
    cave += mov_ret
    cave += b"\x84\xc0"
    cave += bytes([0x74, je_rel])
    cave += cmp_icb
    cave += bytes([0x75, jne_rel])
    cave += mov_valid
    cave += b"\xe9" + rel32(e["convert_va"], cave_va + jconv_at + 5)
    cave += b"\xe9" + rel32(e["je_target"], cave_va + fail_at + 5)
    return bytes(cave)

# ---------- driver ----------
def patch(src, dst):
    raw = open(src, "rb").read()
    elf = Elf(raw)
    targets = get_targets(src)
    if not targets:
        sys.exit("no ISteamUtils_*_GetAPICallResult symbols; stripped or wrong file")
    cave_va, cave_limit = elf.cave_window()
    cursor = cave_va
    patched = []
    for name, (va, size) in sorted(targets.items()):
        e = parse(disasm(src, va, size))
        if not e:
            print("  skip %s (unrecognized shape)" % name); continue
        cave = build_cave(cursor, e)
        # entry region = [entry_va, convert_va): overwrite with jmp cave + nops
        entry_len = e["convert_va"] - e["entry_va"]
        if entry_len < 5:
            print("  skip %s (entry too short)" % name); continue
        if cursor + len(cave) > cave_limit:
            sys.exit("out of cave space")
        c_off = elf.va_to_off(cursor)
        if set(elf.d[c_off:c_off+len(cave)]) - {0}:
            sys.exit("cave region at %#x not free" % cursor)
        elf.d[c_off:c_off+len(cave)] = cave
        e_off = elf.va_to_off(e["entry_va"])
        jmp = b"\xe9" + rel32(cursor, e["entry_va"]+5)
        elf.d[e_off:e_off+entry_len] = jmp + b"\x90"*(entry_len-5)
        cursor += len(cave)
        patched.append(name)
        print("  patched %s: Rargs=%s Xret=%#x Zicb=%#x Rbuf=%s cave@%#x" %
              (name, e["Rargs"], e["Xret"], e["Zicb"], e["Rbuf"], cursor-len(cave)))
    if not patched:
        sys.exit("nothing patched; refusing to write")
    elf.grow_exec(cursor)
    open(dst, "wb").write(elf.d)
    print("wrote %s (%d function(s) patched)" % (dst, len(patched)))

if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: genpatch.py <in.so> <out.so>")
    patch(sys.argv[1], sys.argv[2])
GENPATCH_EOF

echo ">> patching lsteamclient.so ..."
python3 "$TMP/genpatch.py" "$SRC/$LIB_REL" "$TMP/patched.so"

echo ">> building compat tool (full dereferenced copy) ..."
rm -rf "$TOOL"
cp -rL "$SRC" "$TOOL"
chmod -R u+w "$TOOL"
install -m 0755 "$TMP/patched.so" "$TOOL/$LIB_REL"

cat > "$TOOL/compatibilitytool.vdf" <<VDF
"compatibilitytools"
{
  "compat_tools"
  {
    "$TOOLNAME"
    {
      "install_path" "."
      "display_name" "$BASE (secure fix)"
      "from_oslist"  "windows"
      "to_oslist"    "linux"
    }
  }
}
VDF

echo ">> done. Fully restart Steam, then set the game -> Properties ->"
echo "   Compatibility to \"$BASE (secure fix)\"."
