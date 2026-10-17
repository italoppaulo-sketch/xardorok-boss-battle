"""Technical atlas split/nearest resampling. Does not synthesize artwork."""
from pathlib import Path
import argparse,json
import numpy as np
from PIL import Image

def pack(source, destination):
    im=Image.open(source).convert('RGBA')
    names=['aura','shield','hit_fire','floor_fire','floors','electric']
    destination.mkdir(parents=True,exist_ok=True)
    for row,name in enumerate(names):
        pieces=[]
        for col in range(4):
            cell=im.crop((round(col*im.width/4),round(row*im.height/6),round((col+1)*im.width/4),round((row+1)*im.height/6)))
            a=np.asarray(cell)[:,:,3]
            ys,xs=np.where(a>(180 if name=='floors' else 20))
            box=(int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1))
            patch=cell.crop(box)
            if name=='floors':
                inset=4;patch=patch.crop((inset,inset,patch.width-inset,patch.height-inset)).convert('RGB').convert('RGBA')
            pieces.append(patch)
        atlas=Image.new('RGBA',(384,96))
        factor=min(86/max(p.width for p in pieces),86/max(p.height for p in pieces))
        for frame,patch in enumerate(pieces):
            patch=patch.resize((96,96) if name=='floors' else (max(1,round(patch.width*factor)),max(1,round(patch.height*factor))),Image.Resampling.NEAREST)
            atlas.alpha_composite(patch,(frame*96+(96-patch.width)//2,(96-patch.height)//2))
        atlas.save(destination/(name+'.png'),optimize=True)
        alpha=np.asarray(atlas)[:,:,3]
        if name!='floors':
            assert (alpha<10).mean()>.3
            assert (alpha[:,0]==0).all() and (alpha[:,-1]==0).all()
        print(name,atlas.size,'clear',round(float((alpha<10).mean()),3))
    (destination/'atlas.json').write_text(json.dumps({'columns':4,'frame_size':[96,96],'families':names,'frames':24,'resampling':'nearest','runtime_dependencies':[]},indent=2)+'\n')
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('destination',type=Path);a=p.parse_args();pack(a.source,a.destination)
