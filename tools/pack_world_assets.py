"""Structural export of generated effect/prop sheets; no new artwork is drawn here."""
from pathlib import Path
import json
import argparse
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]

FAMILIES=['ice','fire','lightning','arrows','illusion','healing','smoke','meteor','laser']

def trim_alpha(image):
    a=np.asarray(image)[:,:,3]
    ys,xs=np.where(a>12)
    if len(xs)==0: raise ValueError('Empty source cell')
    return image.crop((int(xs.min()),int(ys.min()),int(xs.max())+1,int(ys.max())+1))

def effects(source):
    im=Image.open(source).convert('RGBA')
    for row,family in enumerate(FAMILIES):
        images=[]
        for col in range(4):
            region=(round(col*im.width/4),round(row*im.height/9),round((col+1)*im.width/4),round((row+1)*im.height/9))
            images.append(trim_alpha(im.crop(region)))
        factor=min(84/max(i.width for i in images),84/max(i.height for i in images))
        atlas=Image.new('RGBA',(384,96))
        for col,image in enumerate(images):
            image=image.resize((max(1,round(image.width*factor)),max(1,round(image.height*factor))),Image.Resampling.NEAREST)
            atlas.alpha_composite(image,(col*96+(96-image.width)//2,(96-image.height)//2))
        folder=ROOT/'assets/effects'/family;folder.mkdir(parents=True,exist_ok=True)
        atlas.save(folder/'atlas.png',optimize=True)
        (folder/'atlas.json').write_text(json.dumps({'frames':4,'frame_size':[96,96],'anchor':[48,48],'source_grid_row':row})+'\n')
        print('effect',family,atlas.getextrema()[3])

def environment(source, background):
    im=Image.open(source).convert('RGBA')
    names=['floor_0','floor_1','floor_2','floor_frost','floor_seal','floor_crack','floor_snow','floor_embers',
      'pillar','broken_pillar','arch','balustrade','fascia','throne','stairs','chain',
      'brazier_0','brazier_1','brazier_2','brazier_3','crystals','crystals_small','rubble','banner',
      'rune_ice','rune_fire','crack','ash','crown','sword','ice_edge','buttress']
    base=ROOT/'assets/environments/xardorok_arena'
    for i,name in enumerate(names):
        col,row=i%8,i//8
        reg=(round(col*im.width/8),round(row*im.height/4),round((col+1)*im.width/8),round((row+1)*im.height/4))
        patch=trim_alpha(im.crop(reg))
        folder=base/('tiles' if i<8 else 'props');folder.mkdir(parents=True,exist_ok=True)
        if i<8:
            # Opaque square floor interior; prevents transparent seams in walkable cells.
            inset=max(3,round(min(patch.size)*0.035))
            patch=patch.crop((inset,inset,patch.width-inset,patch.height-inset)).convert('RGB').convert('RGBA')
            patch=patch.resize((64,64),Image.Resampling.NEAREST)
        else:
            limit=(64,112) if name in ['pillar','broken_pillar','arch','buttress'] else (96,80)
            factor=min(limit[0]/patch.width,limit[1]/patch.height)
            patch=patch.resize((max(1,round(patch.width*factor)),max(1,round(patch.height*factor))),Image.Resampling.NEAREST)
        patch.save(folder/(name+'.png'),optimize=True)
    (base/'backgrounds').mkdir(parents=True,exist_ok=True)
    bg=Image.open(background).convert('RGB')
    bg=bg.resize((900,375),Image.Resampling.NEAREST)
    bg.save(base/'backgrounds/castle_distance.png',optimize=True)
    print('environment',len(names),'modular pieces')

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--effects',required=True,type=Path)
    parser.add_argument('--environment',required=True,type=Path)
    parser.add_argument('--background',required=True,type=Path)
    args=parser.parse_args()
    effects(args.effects)
    environment(args.environment,args.background)
