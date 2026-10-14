"""Makes the spoken dialogue of the game with Microsoft Azure AI Speech (neural voices, free tier F0).

    godot --path . --headless --script tools/dump_voice_lines.gd      # writes tools/_voice/lines.json
    python tools/gen_voice.py                  # makes the recordings that are missing
    python tools/gen_voice.py --dry-run        # only says what would be made and how many characters (no network)
    python tools/gen_voice.py --only Σταύρος   # only lines whose text contains the word
    python tools/gen_voice.py --prune          # removes recordings that no line needs any more
    godot --headless --import                  # then, so Godot makes the .mp3.import files (commit them)

Needs only Python 3 (standard library). The Azure key and region are read from the environment variables
AZURE_SPEECH_KEY and AZURE_SPEECH_REGION (on Windows also from the user variables, so a terminal opened before
`setx` works). The key is never printed and never written anywhere. Voices, speed and pitch of every character
live in scripts/voice_data.gd; the file name of a recording is the hash that VoiceData.key() computes, and this
script recomputes it itself and stops if the two differ. Design: docs/superpowers/specs/2026-10-14-voice-over-design.md.
"""
import argparse
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.request
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
LINES_JSON = os.path.join(HERE, "_voice", "lines.json")
OUT_DIR = os.path.join(ROOT, "assets", "audio", "voice")
OUTPUT_FORMAT = "audio-24khz-48kbitrate-mono-mp3"
KEY_LENGTH = 16
RETRIES = 3


def env(name):
    value = os.environ.get(name, "")
    if not value and sys.platform == "win32":
        try:
            import winreg
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as k:
                value = winreg.QueryValueEx(k, name)[0]
        except OSError:
            value = ""
    return value.strip()


def key_of(profile, text):
    """The same as VoiceData.key() in GDScript: sha1 of voice|rate|pitch|text (UTF-8), first 16 hex characters."""
    s = "|".join([profile["voice"], profile["rate"], profile["pitch"], text])
    return hashlib.sha1(s.encode("utf-8")).hexdigest()[:KEY_LENGTH]


def ssml(profile, text):
    return ("<speak version='1.0' xml:lang='el-GR' xmlns='http://www.w3.org/2001/10/synthesis'>"
            "<voice name='%s'><prosody rate='%s' pitch='%s'>%s</prosody></voice></speak>"
            % (profile["voice"], profile["rate"], profile["pitch"], escape(text)))


def synthesize(region, key, profile, text):
    request = urllib.request.Request(
        "https://%s.tts.speech.microsoft.com/cognitiveservices/v1" % region,
        data=ssml(profile, text).encode("utf-8"),
        headers={
            "Ocp-Apim-Subscription-Key": key,
            "Content-Type": "application/ssml+xml; charset=utf-8",
            "X-Microsoft-OutputFormat": OUTPUT_FORMAT,
            "User-Agent": "george-adventures-gen-voice",
        },
        method="POST",
    )
    last = ""
    for attempt in range(RETRIES + 1):
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.read()
        except urllib.error.HTTPError as e:
            last = "HTTP %d" % e.code
            if e.code not in (429, 500, 502, 503, 504):
                break
        except (urllib.error.URLError, TimeoutError) as e:
            last = str(e)
        time.sleep(2 ** attempt)
    raise RuntimeError(last)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dry-run", action="store_true", help="list what is missing, make nothing, no network")
    parser.add_argument("--prune", action="store_true", help="delete recordings no line needs")
    parser.add_argument("--only", default="", help="only lines whose text contains this word")
    parser.add_argument("--lines", default=LINES_JSON, help="the JSON from tools/dump_voice_lines.gd")
    args = parser.parse_args()

    if not os.path.exists(args.lines):
        sys.exit("%s not found. Run: godot --path . --headless --script tools/dump_voice_lines.gd" % args.lines)
    with open(args.lines, encoding="utf-8") as f:
        data = json.load(f)
    profiles = data["profiles"]

    wanted = {}
    for line in data["lines"]:
        expected = key_of(profiles[line["profile"]], line["text"])
        if expected != line["key"]:
            sys.exit("hash mismatch for %r: GDScript says %s, Python says %s. Fix VoiceData.key() or this script."
                     % (line["text"][:40], line["key"], expected))
        wanted[line["key"]] = line

    os.makedirs(OUT_DIR, exist_ok=True)
    existing = {n[:-4] for n in os.listdir(OUT_DIR) if n.endswith(".mp3")}
    missing = [wanted[k] for k in wanted if k not in existing and args.only in wanted[k]["text"]]
    unused = sorted(existing - set(wanted))
    chars = sum(len(l["text"]) for l in missing)
    print("%d lines in the game, %d recordings present, %d to make (%d characters), %d unused"
          % (len(wanted), len(existing & set(wanted)), len(missing), chars, len(unused)))

    if args.prune:
        for k in unused:
            for name in (k + ".mp3", k + ".mp3.import"):
                path = os.path.join(OUT_DIR, name)
                if os.path.exists(path):
                    os.remove(path)
        print("removed %d unused recordings" % len(unused))
    if args.dry_run or not missing:
        return

    key = env("AZURE_SPEECH_KEY")
    region = env("AZURE_SPEECH_REGION")
    if not key:
        sys.exit("The environment variable AZURE_SPEECH_KEY is not set.")
    if not region:
        sys.exit("The environment variable AZURE_SPEECH_REGION is not set (for example northeurope).")

    failed = 0
    for i, line in enumerate(missing, 1):
        try:
            audio = synthesize(region, key, profiles[line["profile"]], line["text"])
        except RuntimeError as e:
            failed += 1
            print("FAILED (%s): %s" % (e, line["text"][:60]))
            continue
        with open(os.path.join(OUT_DIR, line["key"] + ".mp3"), "wb") as f:
            f.write(audio)
        print("[%d/%d] %s  %s" % (i, len(missing), line["profile"], line["text"][:50]))
    print("done: %d made, %d failed" % (len(missing) - failed, failed))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
