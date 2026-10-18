"""Rebuild the approval renders from the original generated MP3 files.

Requires Python 3, FFmpeg and ffprobe. No network access or paid generation.
Originals and WAV master are in the downloadable source package, not duplicated in git.
"""
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
GENERATED = ROOT / "sources/generated"
SFX = {
    "grosso_martelo": "characters",
    "kodokami_fushigiri": "characters",
    "thuxil_raio": "characters",
    "xardorok_meteoro": "xardorok",
    "lacaio_laser": "minions",
}
MUSIC = "o_ultimo_rei_das_cinzas"


def run(args):
    result = subprocess.run(args, capture_output=True, text=True, check=True)
    return result.stdout + result.stderr


def ffmpeg(source, target, filters, codec):
    target.parent.mkdir(parents=True, exist_ok=True)
    run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(source),
         "-map_metadata", "-1", "-af", filters, "-ar", "44100", "-ac", "2",
         *codec, str(target)])


def loudness(path):
    output = run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(path),
                  "-af", "loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json",
                  "-f", "null", "-"])
    return json.loads(re.findall(r'\{\s*"input_i".*?\}', output, re.S)[-1])


def peak(path):
    output = run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(path),
                  "-af", "volumedetect", "-f", "null", "-"])
    return float(re.search(r"max_volume: ([\-\d.]+) dB", output).group(1))


def info(path):
    payload = json.loads(run(["ffprobe", "-v", "error", "-show_entries",
                             "format=duration:stream=codec_name,sample_rate,channels",
                             "-of", "json", str(path)]))
    measure = loudness(path)
    return {
        "path": str(path.relative_to(ROOT)), "bytes": path.stat().st_size,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "duration_seconds": float(payload["format"]["duration"]),
        "stream": payload["streams"][0],
        "integrated_lufs": float(measure["input_i"]),
        "true_peak_dbtp": float(measure["input_tp"]),
        "loudness_range_lu": float(measure["input_lra"]),
    }


def main():
    master = ROOT / "masters" / (MUSIC + "_75s.wav")
    preview = ROOT / "music" / (MUSIC + "_75s.ogg")
    original = GENERATED / (MUSIC + "_original.mp3")
    edit = "atrim=0:75,asetpts=PTS-STARTPTS,afade=t=out:st=72:d=3"
    output = run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(original),
                  "-af", edit + ",loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json",
                  "-f", "null", "-"])
    m = json.loads(re.findall(r'\{\s*"input_i".*?\}', output, re.S)[-1])
    norm = ("loudnorm=I=-16:TP=-1.5:LRA=11:linear=true:"
            f"measured_I={m['input_i']}:measured_TP={m['input_tp']}:"
            f"measured_LRA={m['input_lra']}:measured_thresh={m['input_thresh']}:"
            f"offset={m['target_offset']}")
    ffmpeg(original, master, edit + "," + norm, ["-c:a", "pcm_s24le"])
    ffmpeg(master, preview, "anull", ["-c:a", "libvorbis", "-q:a", "6"])
    outputs = [master, preview]
    for name, group in SFX.items():
        source = GENERATED / (name + "_original.mp3")
        target = ROOT / "sfx" / group / (name + ".wav")
        # Distinct original generations; gentle cleanup, not pitch/speed variants.
        cleanup = "highpass=f=35,lowpass=f=12500"
        preliminary = ROOT / "masters" / (name + "_cleanup.wav")
        ffmpeg(source, preliminary, cleanup, ["-c:a", "pcm_s16le"])
        gain = -3.0 - peak(preliminary)
        duration = float(json.loads(run(["ffprobe", "-v", "error", "-show_entries",
                         "format=duration", "-of", "json", str(preliminary)]))["format"]["duration"])
        filters = f"volume={gain:.3f}dB,afade=t=in:d=0.003,afade=t=out:st={duration-0.025:.6f}:d=0.025"
        ffmpeg(preliminary, target, filters, ["-c:a", "pcm_s16le"])
        preliminary.unlink()
        outputs.append(target)
    reports = [info(path) for path in outputs]
    for row in reports:
        assert row["duration_seconds"] > 0
        assert math.isfinite(row["integrated_lufs"])
        assert row["true_peak_dbtp"] <= -0.8, row
        assert row["stream"]["sample_rate"] == "44100"
        assert row["stream"]["channels"] == 2
    assert abs(reports[0]["duration_seconds"] - 75) < .01
    assert abs(reports[1]["duration_seconds"] - 75) < .1
    assert -17 <= reports[0]["integrated_lufs"] <= -15
    assert len({r["sha256"] for r in reports[2:]}) == 5
    (ROOT / "sources/audio_metrics.json").write_text(json.dumps(reports, indent=2) + "\n")
    print(json.dumps(reports, indent=2))


if __name__ == "__main__":
    main()
