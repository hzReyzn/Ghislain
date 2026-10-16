"""Run deterministic client tests; no Roblox renderer or game physics are simulated."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
LUAU = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("luau")
source = (ROOT / "Reyzn X.lua").read_text()
compiler = LUAU.with_name("luau-compile")
if compiler.is_file():
    subprocess.run([str(compiler), str(ROOT / "Reyzn X.lua")], check=True, stdout=subprocess.DEVNULL)
for forbidden in ("loadstring", "TeleportService", "Humanoid", "VideoFrame", 'make("Sound"', "CharacterAdded", "CharacterRemoving"):
    assert forbidden not in source, forbidden
assert source.count('game:HttpGet(') == 1, 'Only the fixed PNG downloader may use HTTP'
assert source.count('https://') == 6, 'Only the six supplied artwork URLs are allowed'
assert 'validPng(body,asset)' in source
generated = ROOT / "tests" / "_generated.luau"
try:
    generated.write_text("local source=[====[" + source + "]====]\nrequire('./behavior')(source)\n")
    subprocess.run([str(LUAU), str(generated)], check=True)
finally:
    generated.unlink(missing_ok=True)
