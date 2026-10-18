"""Embed independent feature modules in the single-file public Hub."""
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
target=ROOT/'Reyzn X.lua'
source=target.read_text()
blocks=[]
for path,name in [('runtime/CharacterFeature.luau','createCharacterFeature'),
                  ('features/WalkOnWater.luau','createWalkOnWater'),
                  ('features/Antifling.luau','createAntifling'),
                  ('runtime/DisasterDetection.luau','DisasterDetection'),
                  ('features/DisasterPrediction.luau','createDisasterPrediction')]:
    blocks.append('local '+name+' = (function()\n'+(ROOT/path).read_text()+'end)()\n')
start='-- BEGIN CHARACTER FEATURES\n'
end='-- END CHARACTER FEATURES\n'
block=start+''.join(blocks)+end
if start in source:
    before,rest=source.split(start,1)
    _,after=rest.split(end,1)
    source=before+block+after
else:
    source=source.replace('-- Main executable integration.\n',block+'\n-- Main executable integration.\n',1)
target.write_text(source)
