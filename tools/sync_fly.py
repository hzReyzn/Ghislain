"""Vendor FLY and embed its exact source; runtime execution needs no code download.

Usage: python tools/sync_fly.py ../fly-ssj3/FLY-SSJ3.lua
Omit the argument to rebuild from the already vendored source.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
target = ROOT / "features/FLY-SSJ3.lua"
if len(sys.argv) > 1:
    target.write_text(Path(sys.argv[1]).read_text())
fly = target.read_text()
start = "-- BEGIN NO FALL COORDINATOR\n"
end = "-- END NO FALL COORDINATOR\n"
coordinator = start + fly.split(start, 1)[1].split(end, 1)[0] + end
source = (ROOT / "Reyzn X.lua").read_text()
if start in source:
    before, rest = source.split(start, 1)
    _, after = rest.split(end, 1)
    source = before + coordinator + after
else:
    source = source.replace("local NoFallDamage={}", coordinator + "\nlocal NoFallDamage={}", 1)
start = "-- BEGIN BUNDLED FLY SSJ3\n"
end = "-- END BUNDLED FLY SSJ3\n"
block = start + "local function runFlySSJ3()\n" + fly + "end\n" + end
if start in source:
    before, rest = source.split(start, 1)
    _, after = rest.split(end, 1)
    source = before + block + after
else:
    source = source.replace("-- Main executable integration.\n", block + "\n-- Main executable integration.\n", 1)
(ROOT / "Reyzn X.lua").write_text(source)
