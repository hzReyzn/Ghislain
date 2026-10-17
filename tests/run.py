"""Run deterministic client tests; no Roblox renderer or game physics are simulated."""
from pathlib import Path
import subprocess
import sys
import re

ROOT = Path(__file__).resolve().parents[1]
LUAU = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("luau")
source = (ROOT / "Reyzn X.lua").read_text()
compiler = LUAU.with_name("luau-compile")
if compiler.is_file():
    subprocess.run([str(compiler), str(ROOT / "Reyzn X.lua")], check=True, stdout=subprocess.DEVNULL)
# Main now contains the explicitly requested local velocity controller. Keep the
# ban on downloaded code, unrelated services and the original clipboard side effect.
for forbidden in ("loadstring", "TeleportService", "VideoFrame", 'make("Sound"', "setclipboard"):
    assert forbidden not in source, forbidden
assert source.count('game:HttpGet(') == 1, 'Only the fixed artwork downloader may use HTTP'
assert source.count('https://') == 12, 'Only the eleven supplied images and shared fire sprite are allowed'
assert 'validArtwork(body,asset)' in source
# Check actual repository bytes, not just fabricated network fixtures. The
# supplied background is JPEG despite its original .png upload filename.
assets = re.findall(r'url="https://raw.githubusercontent.com/hzReyzn/Ghislain/main/([^"]+)",file="[^"]+",bytes=(\d+)([^\n]+)', source)
assert len(assets) == 12
for name, size, properties in assets:
    body = (ROOT / name).read_bytes()
    assert len(body) == int(size), f'Incorrect asset byte count: {name}'
    if 'format="jpeg"' in properties:
        assert name.endswith('.jpg') and body[:3] == b'\xff\xd8\xff' and body[-2:] == b'\xff\xd9', name
    else:
        assert body[:8] == b'\x89PNG\r\n\x1a\n' and body[12:16] == b'IHDR' and body[-8:-4] == b'IEND', name
generated = ROOT / "tests" / "_generated.luau"
try:
    generated.write_text("local source=[====[" + source + "]====]\nrequire('./behavior')(source)\n")
    subprocess.run([str(LUAU), str(generated)], check=True)
finally:
    generated.unlink(missing_ok=True)
