"""Technical crops and nearest-neighbour exports of two generated source images.
No game art is procedurally painted. Sources stay outside the repository.
Usage: python tools/pack_marco4_arena.py ATLAS.png BACKDROP.png
"""
from pathlib import Path
import sys
from PIL import Image

out = Path(__file__).resolve().parents[1] / 'assets/environments/xardorok_arena/marco4'
out.mkdir(parents=True, exist_ok=True)
atlas = Image.open(sys.argv[1]).convert('RGBA')
# Explicit source bounds prevent neighbouring assets or empty margins from leaking.
boxes = {
 'floor_0':(86,43,303,262), 'floor_1':(392,43,605,260),
 'floor_crack':(687,43,903,260), 'floor_cold':(993,43,1207,260),
 'ruin_0':(38,318,326,540), 'ruin_1':(357,318,648,540),
 'ruin_2':(665,318,949,540), 'ruin_3':(969,318,1252,540),
 'arch_0':(62,541,319,912), 'arch_1':(378,541,649,912),
 'arch_2':(681,541,956,912), 'arch_3':(978,541,1262,912),
 'brazier':(77,913,289,1203), 'ice_fissure':(359,913,651,1203),
 'fascia':(674,913,960,1203), 'cloud':(964,913,1273,1203),
}
for name, bounds in boxes.items():
    im = atlas.crop(bounds)
    if name.startswith('floor'):
        im = im.convert('RGB').resize((64,64), Image.Resampling.NEAREST).convert('RGBA')
    else:
        alpha = im.getchannel('A')
        bb = alpha.point(lambda a: 255 if a > 12 else 0).getbbox()
        if bb: im = im.crop(bb)
        target = (52,38) if name.startswith('ruin') else (120,176)
        if name == 'brazier': target=(36,50)
        if name == 'ice_fissure': target=(68,52)
        if name == 'fascia': target=(64,70)
        if name == 'cloud': target=(330,240)
        ratio=min(target[0]/im.width,target[1]/im.height)
        im=im.resize((round(im.width*ratio),round(im.height*ratio)),Image.Resampling.NEAREST)
    im.save(out / (name+'.png'))
Image.open(sys.argv[2]).convert('RGB').resize((1200,480),Image.Resampling.NEAREST).save(out/'storm_distance.png')
print('Exported',len(boxes)+1,'PNG assets')
