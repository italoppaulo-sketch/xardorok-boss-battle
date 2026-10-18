"""Render an original 32-bar JRPG boss theme, 'A Coroa em Chamas'.

No excerpts from battle.ogg or other recordings. Deterministic score + FluidR3 GM
(MIT) via libfluidsynth. Requires numpy, scipy, ffmpeg and libfluidsynth.
Usage: python tools/audio/compose_phase_two.py /path/to/FluidR3_GM.sf2
Outputs the loop, a MIDI score and technical provenance. No runtime dependencies.
"""
import ctypes as C
import ctypes.util
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys

import numpy as np
from scipy.signal import butter, sosfilt

ROOT = Path(__file__).resolve().parents[2]
SR, BPM, BARS = 44100, 150, 32
BEAT = 60 / BPM
PERIOD = round(BARS * 4 * BEAT * SR)
EVENTS = []
PROGRAMS = {0: 60, 1: 48, 2: 33, 3: 45, 4: 68, 5: 0, 6: 47, 7: 56}


def note(channel, pitch, start, length, velocity):
    EVENTS.append((start, 1, channel, pitch, velocity))
    EVENTS.append((start + length, 0, channel, pitch, 0))


def score():
    # D minor, Bb, C, A7; a contrasting G minor / F bridge, then dominant return.
    harmony = [(50, [62, 65, 69]), (46, [62, 65, 70]),
               (48, [60, 64, 67]), (45, [61, 64, 67])]
    bridge = [(43, [62, 67, 70]), (48, [60, 64, 67]),
              (41, [60, 65, 69]), (45, [61, 64, 67])]
    melodies = [
        [74, 77, 76, 74, 69, 73], [74, 77, 81, 79, 77, 74],
        [76, 79, 77, 76, 72, 76], [73, 76, 79, 81, 79, 73],
        [74, 81, 79, 77, 76, 74], [77, 82, 81, 79, 77, 74],
        [79, 76, 72, 76, 79, 84], [85, 81, 79, 76, 73, 69],
    ]
    bridge_melodies = [
        [79, 82, 81, 79, 74, 77], [79, 76, 72, 74, 76, 79],
        [81, 77, 76, 77, 72, 69], [73, 76, 81, 79, 76, 73],
    ]
    rhythm = [.5, .5, .5, .5, 1, 1]
    for bar in range(BARS):
        start = bar * 4
        bass, chord = (bridge if 16 <= bar < 24 else harmony)[bar % 4]
        # Warm string ostinato: articulated eighth notes, no audio-chunk splicing.
        arpeggio = [chord[0], chord[2], chord[1], chord[2],
                    chord[0] + 12, chord[2], chord[1], chord[2]]
        for step, pitch in enumerate(arpeggio):
            note(3, pitch, start + step * .5, .37, 43 + (step % 4 == 0) * 12)
        for offset in [0, 2]:
            for pitch in chord:
                note(1, pitch - 12, start + offset, 1.85, 43 if bar < 24 else 52)
        for step in range(8):
            pitch = bass - 12 if step % 4 != 3 else bass - 5
            note(2, pitch, start + step * .5, .38, 74 if step % 2 == 0 else 57)
        melody = bridge_melodies[bar % 4] if 16 <= bar < 24 else melodies[bar % 8]
        # Three phrases: horns, oboe bridge, brass reprise. New melodic material.
        voice = 4 if 16 <= bar < 24 else 0
        position = 0
        for i, (pitch, length) in enumerate(zip(melody, rhythm)):
            note(voice, pitch - (12 if voice == 0 else 0), start + position,
                 length * .87, 86 + (i in [0, 4]) * 6)
            if bar >= 24:
                note(7, pitch, start + position, length * .81, 58)
            position += length
        if 8 <= bar < 16 or bar >= 24:
            for i, pitch in enumerate([chord[2] + 12, chord[1] + 12]):
                note(5, pitch, start + 1.5 + i, .42, 43)
        # Sparse acoustic drums, not the rejected chopped percussion recording.
        for beat in [0, 2]:
            note(9, 36, start + beat, .15, 68)
        for beat in [1, 3]:
            note(9, 38, start + beat, .13, 50 if bar < 24 else 58)
        if bar % 4 == 0:
            note(9, 49, start, 1.5, 42)
            note(6, bass, start, .7, 55)
        if bar % 8 == 7:
            for beat, drum in [(3, 45), (3.5, 43), (3.75, 41)]:
                note(9, drum, start + beat, .16, 52)


def vlq(value):
    result = [value & 127]
    while value >> 7:
        value >>= 7
        result.insert(0, (value & 127) | 128)
    return bytes(result)


def midi(path):
    events = [(0, b'\xff\x51\x03' + round(60000000 / BPM).to_bytes(3, 'big'))]
    events += [(0, bytes([0xC0 + ch, program])) for ch, program in PROGRAMS.items()]
    events += [(round(beat * 480), bytes([(0x90 if on else 0x80) + ch, key, vel]))
               for beat, on, ch, key, vel in sorted(EVENTS)]
    track, last = bytearray(), 0
    for tick, message in sorted(events, key=lambda x: x[0]):
        track.extend(vlq(tick - last) + message)
        last = tick
    track.extend(vlq(BARS * 4 * 480 - last) + b'\xff\x2f\x00')
    path.write_bytes(b'MThd' + struct.pack('>IHHH', 6, 0, 1, 480)
                     + b'MTrk' + struct.pack('>I', len(track)) + track)


def render(soundfont):
    lib = C.CDLL(ctypes.util.find_library('fluidsynth'))
    def bind(name, result, args):
        fn = getattr(lib, name)
        fn.restype, fn.argtypes = result, args
        return fn
    pointer, integer = C.c_void_p, C.c_int
    settings = bind('new_fluid_settings', pointer, [])()
    setnum = bind('fluid_settings_setnum', integer, [pointer, C.c_char_p, C.c_double])
    setint = bind('fluid_settings_setint', integer, [pointer, C.c_char_p, integer])
    setnum(settings, b'synth.sample-rate', SR)
    setnum(settings, b'synth.gain', .5)
    setnum(settings, b'synth.reverb.level', .18)
    setnum(settings, b'synth.reverb.room-size', .55)
    setint(settings, b'synth.chorus.active', 0)
    setint(settings, b'synth.polyphony', 256)
    synth = bind('new_fluid_synth', pointer, [pointer])(settings)
    load = bind('fluid_synth_sfload', integer, [pointer, C.c_char_p, integer])
    assert load(synth, str(soundfont).encode(), 1) >= 0
    program = bind('fluid_synth_program_change', integer, [pointer, integer, integer])
    cc = bind('fluid_synth_cc', integer, [pointer, integer, integer, integer])
    for ch, prg in PROGRAMS.items():
        program(synth, ch, prg)
        cc(synth, ch, 10, {0: 70, 1: 45, 2: 64, 3: 82, 4: 55, 5: 92, 6: 40, 7: 60}[ch])
        cc(synth, ch, 91, 38)
    on = bind('fluid_synth_noteon', integer, [pointer, integer, integer, integer])
    off = bind('fluid_synth_noteoff', integer, [pointer, integer, integer])
    write = bind('fluid_synth_write_float', integer,
                 [pointer, integer, pointer, integer, integer, pointer, integer, integer])
    audio = np.zeros((PERIOD * 3, 2), dtype=np.float32)
    cursor = 0
    def advance(end):
        nonlocal cursor
        while cursor < end:
            count = min(end - cursor, 4096)
            address = audio[cursor:].ctypes.data
            assert write(synth, count, address, 0, 2, address, 1, 2) == 0
            cursor += count
    for cycle in range(3):
        for beat, enabled, channel, key, velocity in sorted(EVENTS):
            advance(cycle * PERIOD + round(beat * BEAT * SR))
            if enabled:
                on(synth, channel, key, velocity)
            else:
                off(synth, channel, key)
    advance(len(audio))
    bind('delete_fluid_synth', None, [pointer])(synth)
    bind('delete_fluid_settings', None, [pointer])(settings)
    # The middle repetition includes natural tails from the preceding repetition.
    loop = audio[PERIOD:PERIOD * 2].copy()
    loop = sosfilt(butter(2, 30, 'highpass', fs=SR, output='sos'), loop, axis=0)
    # Match both channels at the seam without fading to silence or shortening a beat.
    seam = loop[-1] - loop[0]
    count = round(.008 * SR)
    loop[-count:] -= np.linspace(0, 1, count)[:, None] * seam
    loop *= (10 ** (-5 / 20)) / np.max(np.abs(loop))
    return loop.astype(np.float32)


def main():
    soundfont = Path(sys.argv[1]).resolve()
    score()
    folder = ROOT / 'docs/phase2/music'
    folder.mkdir(parents=True, exist_ok=True)
    midi(folder / 'A_Coroa_em_Chamas.mid')
    loop = render(soundfont)
    output = ROOT / 'assets/audio/music/phase_two_distinct.ogg'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(SR),
                    '-ac', '2', '-i', '-', '-c:a', 'libvorbis', '-q:a', '6', str(output)],
                   input=loop.tobytes(), check=True)
    provenance = {'title': 'A Coroa em Chamas', 'bpm': BPM, 'bars': BARS,
                  'key': 'D minor', 'seconds': PERIOD / SR, 'sample_rate': SR,
                  'composition': 'Original deterministic score; no audio excerpts from the first phase',
                  'renderer': 'FluidSynth + FluidR3 GM (MIT)',
                  'soundfont_sha256': hashlib.sha256(soundfont.read_bytes()).hexdigest(),
                  'ogg_sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
                  'notes': len(EVENTS) // 2, 'human_listening': 'pending'}
    (folder / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n')
    print(json.dumps(provenance, indent=2))


if __name__ == '__main__':
    main()
