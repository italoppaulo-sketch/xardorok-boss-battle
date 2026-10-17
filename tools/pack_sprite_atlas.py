"""Technical atlas packing only: preserve source art/alpha, crop, anchor and resize nearest.
Requires Pillow, NumPy and SciPy for the offline art pipeline, not for running Godot.
"""
import argparse
import json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy.ndimage import label, find_objects

FRAME = (112, 128)
ANIMATIONS = {
    'idle': (0, 4, 5, True), 'walk': (4, 4, 9, True),
    'attack': (8, 4, 10, False), 'attack_alt': (12, 4, 11, False),
    'cast': (16, 4, 8, False), 'hit': (20, 2, 9, False),
    'evade': (22, 2, 10, False), 'death': (24, 4, 7, False),
    'special': (28, 4, 8, False),
}

def pack(source, destination, idle_height, columns=8, rows=4):
    image = Image.open(source).convert('RGBA')
    rgba = np.asarray(image)
    labels, _ = label(rgba[:, :, 3] > 8)
    sizes = np.bincount(labels.ravel())
    slices = find_objects(labels)
    groups = [[] for _ in range(columns*rows)]
    h, w = labels.shape
    # Each separated connected component belongs to its nominal source grid cell.
    for component, sl in enumerate(slices, 1):
        if sizes[component] < 6:
            continue
        ys, xs = sl
        yy, xx = np.where(labels[sl] == component)
        cx, cy = xx.mean() + xs.start, yy.mean() + ys.start
        col = min(columns-1, int(cx * columns / w))
        row = min(rows-1, int(cy * rows / h))
        groups[row * columns + col].append(component)
    frames = []
    for i, components in enumerate(groups):
        if not components:
            raise ValueError(f'Empty animation cell {i}: source requires inspection')
        # Ignore tiny disconnected halo noise far from the main silhouette.
        main = max(components, key=lambda c: sizes[c])
        my, mx = slices[main - 1]
        if (mx.stop-mx.start) > w/columns*1.35 or (my.stop-my.start) > h/rows*1.45:
            raise ValueError(f'Merged neighboring poses at cell {i}; regenerate source with padding')
        valid = []
        for c in components:
            yy, xx = slices[c-1]
            if sizes[c] >= 40 or (xx.start >= mx.start-8 and xx.stop <= mx.stop+8 and yy.start >= my.start-8 and yy.stop <= my.stop+8):
                valid.append(c)
        mask = np.isin(labels, valid)
        yy, xx = np.where(mask)
        box = (int(xx.min()), int(yy.min()), int(xx.max())+1, int(yy.max())+1)
        x0,y0,x1,y1 = box
        crop = np.array(rgba[y0:y1, x0:x1], copy=True)
        crop[:, :, 3] = np.where(mask[y0:y1,x0:x1],crop[:,:,3],0)
        frames.append(Image.fromarray(crop))
    reference_height = float(np.median([f.height for f in frames[:4]]))
    factor = min(idle_height/reference_height, (FRAME[0]-14)/max(f.width for f in frames), (FRAME[1]-16)/max(f.height for f in frames))
    sheet = Image.new('RGBA',(FRAME[0]*columns,FRAME[1]*rows))
    metrics = []
    for i, frame in enumerate(frames):
        scale_size = (max(1,round(frame.width*factor)),max(1,round(frame.height*factor)))
        resized = frame.resize(scale_size,Image.Resampling.NEAREST)
        # All animations share an immutable baseline; no per-frame scale changes.
        x = (FRAME[0]-resized.width)//2
        y = FRAME[1]-10-resized.height
        sheet.alpha_composite(resized,((i%columns)*FRAME[0]+x,(i//columns)*FRAME[1]+y))
        metrics.append({'frame':i,'bounds':[x,y,resized.width,resized.height], 'baseline':118})
    destination = Path(destination)
    destination.mkdir(parents=True,exist_ok=True)
    sheet.save(destination/'atlas.png',optimize=True)
    resource_path = 'res://' + (destination/'atlas.png').as_posix()
    lines = [f'[gd_resource type="SpriteFrames" load_steps={columns*rows+2} format=3]', '', f'[ext_resource type="Texture2D" path="{resource_path}" id="1"]','']
    for i in range(columns*rows):
        lines += [f'[sub_resource type="AtlasTexture" id="Frame_{i}"]', 'atlas = ExtResource("1")',f'region = Rect2({i%columns*112}, {i//columns*128}, 112, 128)','']
    anims=[]
    for name,(start,count,speed,loop) in ANIMATIONS.items():
        if columns*rows == 8:
            start = 0 if name in ['idle','walk','evade'] else 4
            count = min(4, columns*rows-start)
        values=', '.join('{"duration": 1.0, "texture": SubResource("Frame_%d")}'%i for i in range(start,start+count))
        anims.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": %s}'%(values,str(loop).lower(),name,float(speed)))
    lines += ['[resource]','animations = ['+',\n'.join(anims)+']','']
    (destination/'animations.tres').write_text('\n'.join(lines))
    (destination/'atlas.json').write_text(json.dumps({'grid':[columns,rows],'frame_size':list(FRAME),'anchor':[56,118],'idle_height':round(reference_height*factor),'frames':metrics},indent=2)+'\n')
    print(destination, f'{columns*rows} frames', 'idle height',round(reference_height*factor),'alpha',sheet.getextrema()[3])

if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('source');parser.add_argument('destination');parser.add_argument('--height',type=int,default=64)
    parser.add_argument('--columns',type=int,default=8);parser.add_argument('--rows',type=int,default=4)
    args=parser.parse_args();pack(args.source,args.destination,args.height,args.columns,args.rows)
