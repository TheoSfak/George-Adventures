#!/usr/bin/env python3
"""Checks that no ambience loop beeps: a steady, narrow-band tone that pulses several times a second sounds
like an alarm when it plays for hours. The old night "crickets" were exactly that (a 5 kHz tone, 3800 times
the median, pulsing 9.5 times a second). Run it after editing an ambience recipe:

    python tools/check_ambience.py          (exit code 1 when a loop pulses)
"""
import glob
import os
import sys
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(ROOT, "assets", "audio", "sfx")
PULSE_LIMIT = 0.05      # share of the envelope energy at the strongest pulse rate (clean loops measure 0.00 to 0.01)
TONE_LIMIT = 500.0      # how many times the median the strongest tone stands out


def load(path):
    w = wave.open(path)
    sr = w.getframerate()
    data = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(float)
    if w.getnchannels() > 1:
        data = data.reshape(-1, w.getnchannels()).mean(axis=1)
    return data / 32768.0, sr


def pulsing(x, sr):
    """(peak tone Hz, how many times the median it is, pulse rate Hz, share of envelope energy)."""
    spec = np.abs(np.fft.rfft(x * np.hanning(len(x))))
    freqs = np.fft.rfftfreq(len(x), 1 / sr)
    high = freqs > 1000
    k = int(np.argmax(np.where(high, spec, 0)))
    tone = float(freqs[k])
    ratio = float(spec[k] / (np.median(spec[high]) + 1e-9))
    band = np.where((freqs > tone - 400) & (freqs < tone + 400), np.fft.rfft(x), 0)
    env = np.abs(np.fft.irfft(band, len(x)))
    step = sr // 200
    env = env[:len(env) // step * step].reshape(-1, step).mean(axis=1)
    env = env - env.mean()
    mod = np.abs(np.fft.rfft(env * np.hanning(len(env))))
    mf = np.fft.rfftfreq(len(env), 1 / 200)
    sel = (mf > 1.0) & (mf < 40)
    j = int(np.argmax(np.where(sel, mod, 0)))
    return tone, ratio, float(mf[j]), float(mod[j] / (mod.sum() + 1e-9))


def main():
    bad = 0
    paths = sorted(glob.glob(os.path.join(SFX, "amb_*.wav")) + glob.glob(os.path.join(SFX, "*_loop.wav")))
    for p in paths:
        x, sr = load(p)
        tone, ratio, rate, share = pulsing(x, sr)
        verdict = "BEEPS" if share > PULSE_LIMIT and ratio > TONE_LIMIT else "ok"
        if verdict != "ok":
            bad += 1
        print("%-18s %-6s tone %5.0f Hz (%5.0fx median), strongest pulse %4.1f Hz, share %.2f" % (os.path.basename(p), verdict, tone, ratio, rate, share))
    print("%d loops checked, %d beeping" % (len(paths), bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
