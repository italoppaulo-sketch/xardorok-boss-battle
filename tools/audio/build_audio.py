"""Render the licensed generated source recordings into the Marco 6 catalogue.
Python + numpy/scipy and FFmpeg; this never invokes a paid API.
Usage: python tools/audio/build_audio.py /path/to/source-recordings
"""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

import numpy as np
from scipy.signal import butter, find_peaks, sosfilt

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/audio"
SR = 44100
CATALOG = {}
METRICS = []


def read(path):
    raw = subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(path),
                                   "-ar", str(SR), "-ac", "2", "-f", "f32le", "-"])
    return np.frombuffer(raw, dtype=np.float32).reshape(-1, 2).copy()


def fade(x, seconds=.012):
    x = x.copy()
    n = min(int(seconds * SR), len(x) // 3)
    if n:
        ramp = np.linspace(0, 1, n)
        x[:n] *= ramp[:, None]
        x[-n:] *= ramp[::-1, None]
    return x


def loop(x, seconds=1.0):
    n = min(int(seconds * SR), len(x) // 4)
    a = np.linspace(0, 1, n)[:, None]
    # Periodic overlap-add: both outer boundaries retain the source's local slope.
    join = x[-n:] * (1 - a) + x[:n] * a
    return np.concatenate([join, x[n:-n]])


def save(name, x, group, db=-7, bus="SFX", priority=40, cooldown=.035, looping=False):
    peak = float(np.max(np.abs(x)))
    if peak < 1e-6:
        raise ValueError("silent source " + name)
    x = x * (10 ** (db / 20) / peak)
    ext = "ogg" if group in ["music", "ambience"] else "wav"
    path = OUT / group / (name + "." + ext)
    path.parent.mkdir(parents=True, exist_ok=True)
    codec = ["-c:a", "libvorbis", "-q:a", "5"] if ext == "ogg" else ["-c:a", "pcm_s16le"]
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(SR),
                    "-ac", "2", "-i", "-", *codec, str(path)], input=x.astype("float32").tobytes(), check=True)
    decoded = read(path)
    CATALOG[name] = dict(path="res://" + str(path.relative_to(ROOT)), bus=bus,
                         gain_db=0, priority=priority, cooldown=cooldown, loop=looping)
    METRICS.append(dict(cue=name, seconds=len(decoded)/SR, sample_peak_db=round(20*np.log10(max(1e-9,np.max(np.abs(decoded)))), 2),
                        rms_db=round(20*np.log10(max(1e-9,np.sqrt(np.mean(decoded**2)))), 2),
                        sha256=hashlib.sha256(path.read_bytes()).hexdigest(), bytes=path.stat().st_size))


def main():
    sources = Path(sys.argv[1])
    groups = {
        "heroes": "hammer_swing hammer_hit ice_form ice_shards giant punch dodge shadow_charge sword_slash shadow_rupture sacrifice bow_release arrow_hit roots energy_charge energy_impact flight arcane_cast arcane_hit dispel heal violet_beam illusion silence",
        "boss": "boss_hit smoke summon fire_ignite fire_hit phase crown",
        "minions": "minion_spawn minion_death",
        "combat": "footsteps body_hit hero_death critical",
        "ui": "ui",
    }
    recordings = {}
    for group, names in groups.items():
        for name in names.split():
            x = read(sources / (name + ".mp3"))
            cutoff = 120 if name in ["sword_slash", "shadow_rupture"] else 40
            x = sosfilt(butter(2, [cutoff, 12500], fs=SR, btype="bandpass", output="sos"), x, axis=0)
            # Trim only quiet leading padding; preserve up to the first audible gesture.
            power = np.max(np.abs(x), axis=1)
            audible = np.flatnonzero(power > max(.0015, power.max() * .025))
            if len(audible):
                x = x[max(0, min(int(.25*SR), int(audible[0])) - 130):]
            recordings[name] = x
            save(name, fade(x), "sfx/" + group, db=-12 if name == "ui" else -7,
                 bus="UI" if group == "ui" else "SFX", priority=90 if name in ["sword_slash","crown","phase"] else 40)
    def segment(name, source, start, end, group, db=-9, priority=40):
        save(name, fade(source[int(start*SR):int(end*SR)]), "sfx/"+group, db=db, priority=priority)
    for name, start, end in [("ui_select",0,.18),("ui_confirm",.45,.68),("ui_invalid",.92,1.12),("ui_open",1.45,1.70)]:
        segment(name, recordings["ui"], start,end,"ui",-15)
        CATALOG[name]["bus"]="UI"
    segment("step",recordings["footsteps"],.1,.37,"combat",-15)
    segment("land",recordings["footsteps"],.6,.92,"combat",-12)
    segment("punch_air",recordings["dodge"],0,.16,"heroes",-12)
    segment("ice_hit",recordings["ice_shards"],0,.42,"heroes",-8)
    segment("minion_dissolve",recordings["minion_death"],.65,1.3,"minions",-14)
    blue=read(sources/"approved_chain.mp3")
    segment("chain_charge",blue,0,.25,"heroes",-13)
    segment("chain_jump",blue,.52,.73,"heroes",-10)
    laser=read(sources/"approved_laser.mp3")
    segment("laser_charge",laser,0,.13,"minions",-14)
    segment("laser_emit",laser,.13,.5,"minions",-8)
    segment("laser_hit",laser,.5,.85,"minions",-10)
    meteor=read(sources/"approved_meteor.mp3")
    segment("meteor_fall",meteor,.25,.55,"boss",-10,90)
    segment("meteor_hit",meteor,1.0,3.1,"boss",-5,95)
    segment("guard",recordings["boss_hit"],0,.32,"combat",-16)
    segment("guard_hit",recordings["body_hit"],0,.23,"combat",-17)
    segment("warning",recordings["critical"],0,.25,"ui",-12,90)
    CATALOG["warning"]["bus"]="UI"
    # Battle loop retains the original melody; phase 2 adds a separately generated
    # percussion performance, with hit placements derived from the actual music.
    music=read(sources/"battle_original.mp3")
    music=loop(music,1.25)
    drums=read(sources/"phase_percussion.mp3")
    mono=drums.mean(axis=1)
    energy=np.sqrt(np.mean(mono[:len(mono)//441*441].reshape(-1,441)**2,axis=1))
    peaks,_=find_peaks(energy,distance=22,prominence=max(.001,energy.max()*.08))
    chunks=[fade(drums[max(0,int(p*.01*SR)-220):int(p*.01*SR)+int(.24*SR)]) for p in peaks[:12]]
    if not chunks: raise ValueError("No percussion hits detected")
    m=music.mean(axis=1);env=np.sqrt(np.mean(m[:len(m)//441*441].reshape(-1,441)**2,axis=1))
    attacks,_=find_peaks(env,distance=24,prominence=max(.001,env.max()*.045))
    extra=np.zeros_like(music)
    for i,p in enumerate(attacks):
        start=int(p*.01*SR); hit=chunks[i%len(chunks)]
        end=min(len(extra),start+len(hit));extra[start:end]+=hit[:end-start] * (.25 if i%4 else .38)
    save("battle",music,"music",db=-5,bus="Music",looping=True)
    save("phase_two",music+extra,"music",db=-5,bus="Music",looping=True)
    # Phase 2 now has an independently composed score; retain the legacy render as source only.
    distinct = OUT / "music/phase_two_distinct.ogg"
    if not distinct.is_file():
        raise FileNotFoundError("Render the distinct score with compose_phase_two.py first")
    CATALOG["phase_two"]["path"] = "res://assets/audio/music/phase_two_distinct.ogg"
    # Short complete-cue edits; the original generations remain in source archive.
    for name,length in [("victory",6.0),("defeat",6.5)]:
        x=read(sources/(name+".mp3"))[:int(length*SR)]
        n=int(1.15*SR);x[-n:]*=np.linspace(1,0,n)[:,None]
        save(name,fade(x,.005),"music",db=-5,bus="Music",priority=100)
    wind=read(sources/"ambience.mp3")
    ambient=np.concatenate([wind,wind[:,::-1]*.8])
    ambient=loop(ambient,1.5)
    save("ruins",ambient,"ambience",db=-12,bus="Ambience",looping=True)
    presence=loop(recordings["fire_ignite"][-int(.55*SR):],.12)
    save("aura_presence",presence,"ambience",db=-17,bus="Ambience",looping=True)
    (OUT/"catalog.json").write_text(json.dumps(CATALOG,indent=2)+"\n")
    docs=ROOT/"docs/audio";docs.mkdir(parents=True,exist_ok=True)
    (docs/"audio_metrics.json").write_text(json.dumps(METRICS,indent=2,default=float)+"\n")
    assert all(m["sample_peak_db"] < -3.5 and m["rms_db"] > -65 for m in METRICS)
    print(f"{len(CATALOG)} cues rendered, no silent files or near-full-scale sample peaks")


if __name__=="__main__":main()
