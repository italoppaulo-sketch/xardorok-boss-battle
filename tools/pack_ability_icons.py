"""Crop an AI-authored 7x5 alpha atlas into stable 64px runtime icons.

Technical raster preparation only; creates no new illustration. Pillow offline.
"""
import argparse
import json
from pathlib import Path
from PIL import Image

IDS = [
    'skin', 'hammer', 'double', 'giant', 'unarmed', 'dodge', 'fushigiri',
    'root_arrow', 'ice_arrow', 'energy_arrow', 'flight', 'antispell', 'heal', 'purple_fire',
    'illusion', 'chain', 'silence', 'smoke', 'meteors', 'summon', 'red_laser',
    'basic_0', 'basic_1', 'basic_2', 'basic_3', 'basic_4', 'basic_5', 'basic_6',
    'move', 'end_turn', 'aura', 'reaction', 'phase', 'spirit', 'frozen',
]


def pack(source: Path, destination: Path):
    image = Image.open(source).convert('RGBA')
    destination.mkdir(parents=True, exist_ok=True)
    atlas = Image.new('RGBA', (448, 320))
    manifest = {'frame_size': [64, 64], 'grid': [7, 5], 'icons': {}}
    for index, identity in enumerate(IDS):
        x, y = index % 7, index // 7
        cell = image.crop((round(x * image.width / 7), round(y * image.height / 5),
                           round((x + 1) * image.width / 7), round((y + 1) * image.height / 5)))
        box = cell.getchannel('A').point(lambda value: 255 if value > 20 else 0).getbbox()
        if not box:
            raise ValueError(f'Empty icon {identity}')
        crop = cell.crop(box)
        factor = min(60 / crop.width, 60 / crop.height)
        crop = crop.resize((max(1, round(crop.width * factor)), max(1, round(crop.height * factor))), Image.Resampling.NEAREST)
        icon = Image.new('RGBA', (64, 64))
        icon.alpha_composite(crop, ((64 - crop.width) // 2, (64 - crop.height) // 2))
        icon.save(destination / f'{identity}.png', optimize=True)
        atlas.alpha_composite(icon, (x * 64, y * 64))
        manifest['icons'][identity] = {'file': f'{identity}.png', 'region': [x*64, y*64, 64, 64], 'source_cell': index}
    atlas.save(destination / 'atlas.png', optimize=True)
    (destination / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Packed {len(IDS)} distinct alpha icons at {destination}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path)
    args = parser.parse_args()
    pack(args.source, args.destination)
