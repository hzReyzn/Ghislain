"""Run deterministic client tests; no Roblox renderer or game physics are simulated."""
from pathlib import Path
import subprocess
import sys
import re

ROOT = Path(__file__).resolve().parents[1]
LUAU = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("luau")
source = (ROOT / "Reyzn X.lua").read_text()
fly = (ROOT / "features/FLY-SSJ3.lua").read_text()
assert "local function runFlySSJ3()\n" + fly + "end\n" in source, "Rebuild bundled FLY with tools/sync_fly.py"
coordinator = fly.split("-- BEGIN NO FALL COORDINATOR\n", 1)[1].split("-- END NO FALL COORDINATOR\n", 1)[0]
assert source.split("-- BEGIN NO FALL COORDINATOR\n", 1)[1].split("-- END NO FALL COORDINATOR\n", 1)[0] == coordinator
for path,name in [('runtime/CharacterFeature.luau','createCharacterFeature'),
                  ('features/WalkOnWater.luau','createWalkOnWater'),('features/Antifling.luau','createAntifling'),
                  ('runtime/DisasterDetection.luau','DisasterDetection'),
                  ('features/DisasterPrediction.luau','createDisasterPrediction'),
                  ('features/FPSCounter.luau','createFPSCounter'),('features/ServerTravel.luau','createServerTravel')]:
    assert 'local '+name+' = (function()\n'+(ROOT/path).read_text()+'end)()' in source, 'Rebuild character features'
compiler = LUAU.with_name("luau-compile")
if compiler.is_file():
    subprocess.run([str(compiler), str(ROOT / "Reyzn X.lua")], check=True, stdout=subprocess.DEVNULL)
# Remote execution is confined to the two links expressly requested for Scripts.
for forbidden in ("VideoFrame", 'make("Sound"', "setclipboard"):
    assert forbidden not in source, forbidden
remote = source.split('-- BEGIN REQUESTED REMOTE EXECUTABLES\n', 1)[1].split('-- END REQUESTED REMOTE EXECUTABLES\n', 1)[0]
assert 'loadstring' not in source.replace(remote, '')
assert source.count('game:HttpGet(') == 3, 'Only artwork, requested scripts and click-only server discovery may use HTTP'
assert source.count('https://') == 18, 'Fifteen images, one official server list and two requested scripts'
assert re.findall(r'https://scriptblox.com/[^"\s]+', source) == [
    'https://scriptblox.com/raw/Universal-Script-Telekinesis-Ui-95037',
    'https://scriptblox.com/raw/Natural-Disaster-Survival-Ultra-Blackhole-and-Super-ring-no-lying-Full-FE+Keyless-228862']
loader = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/hzReyzn/Ghislain/main/Reyzn%20X.lua"))()\n'
assert (ROOT / 'Loader.lua').read_text() == loader, 'Keep the exact loader chosen by Reyzn'
assert loader.rstrip() in (ROOT / 'README.md').read_text()
assert 'validArtwork(body,asset)' in source
# Check actual repository bytes, not just fabricated network fixtures. The
# supplied background is JPEG despite its original .png upload filename.
assets = re.findall(r'url="https://raw.githubusercontent.com/hzReyzn/Ghislain/main/([^"]+)",file="[^"]+",bytes=(\d+)([^\n]+)', source)
assert len(assets) == 15
for name, size, properties in assets:
    body = (ROOT / name).read_bytes()
    assert len(body) == int(size), f'Incorrect asset byte count: {name}'
    if 'format="jpeg"' in properties:
        assert name.endswith('.jpg') and body[:3] == b'\xff\xd8\xff' and body[-2:] == b'\xff\xd9', name
    else:
        assert body[:8] == b'\x89PNG\r\n\x1a\n' and body[12:16] == b'IHDR' and body[-8:-4] == b'IEND', name
generated = ROOT / "tests" / "_generated.luau"
try:
    generated.write_text("local source=[====[" + source + "]====]\nlocal fly=[====[" + fly + "]====]\nrequire('./behavior')(source)\nrequire('./integration')(source,fly)\nrequire('./character_features')(source,fly)\nrequire('./executables')(source)\nrequire('./disaster_prediction')(source)\nrequire('./session_tools')(source)\n")
    subprocess.run([str(LUAU), str(generated)], check=True)
finally:
    generated.unlink(missing_ok=True)
