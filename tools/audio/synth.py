"""Tiny numpy synthesizer used by tools/gen_audio.py (no external audio libraries).

Everything returns float32 mono arrays in -1..1 at the module sample rate SR (set by the
caller with set_rate). Nothing here is random without a seed: np.random is re-seeded by the
generators so the generated files are reproducible.
"""
import numpy as np

SR = 32000


def set_rate(sr):
    global SR
    SR = sr


def t_axis(dur):
    return np.arange(int(dur * SR), dtype=np.float64) / SR


def mix(*parts, length=None):
    """Sum arrays of different lengths (aligned at the start)."""
    n = length or max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        m = min(n, len(p))
        out[:m] += p[:m]
    return out


def place(buf, sig, start_s, gain=1.0):
    """Add `sig` into `buf` starting at start_s seconds (clipped to the buffer)."""
    i = int(start_s * SR)
    if i >= len(buf):
        return
    m = min(len(sig), len(buf) - i)
    if m > 0:
        buf[i:i + m] += sig[:m] * gain


def midi(n):
    return 440.0 * 2.0 ** ((n - 69) / 12.0)


# ---------------------------------------------------------------- envelopes ----

def adsr(n, a=0.01, d=0.1, s=0.7, r=0.1):
    """Envelope over n samples; times in seconds, release at the end of the note."""
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    env = np.ones(n) * s
    a_n = min(a_n, n)
    if a_n > 0:
        env[:a_n] = np.linspace(0, 1, a_n)
    d_end = min(a_n + d_n, n)
    if d_end > a_n:
        env[a_n:d_end] = np.linspace(1, s, d_end - a_n)
    r_n = min(r_n, n)
    if r_n > 0:
        env[n - r_n:] *= np.linspace(1, 0, r_n)
    return env


def expdecay(n, tau):
    return np.exp(-np.arange(n) / (tau * SR))


def fade(sig, a=0.005, r=0.01):
    sig = sig.copy()
    a_n, r_n = min(int(a * SR), len(sig)), min(int(r * SR), len(sig))
    if a_n > 0:
        sig[:a_n] *= np.linspace(0, 1, a_n)
    if r_n > 0:
        sig[len(sig) - r_n:] *= np.linspace(1, 0, r_n)
    return sig


# -------------------------------------------------------------- oscillators ----

def sine(freq, dur, phase=0.0):
    t = t_axis(dur)
    f = np.broadcast_to(np.asarray(freq, dtype=np.float64), t.shape)
    return np.sin(phase + 2 * np.pi * np.cumsum(f) / SR)


def saw(freq, dur, harmonics=24):
    """Band-limited saw by additive synthesis (fine for the low rates used here)."""
    t = t_axis(dur)
    f = np.broadcast_to(np.asarray(freq, dtype=np.float64), t.shape)
    ph = 2 * np.pi * np.cumsum(f) / SR
    out = np.zeros_like(t)
    f0 = float(np.max(f))
    top = max(1, min(harmonics, int((SR / 2.2) / max(f0, 1.0))))
    for k in range(1, top + 1):
        out += np.sin(k * ph) / k
    return out * (2 / np.pi)


def square(freq, dur, harmonics=15):
    t = t_axis(dur)
    f = np.broadcast_to(np.asarray(freq, dtype=np.float64), t.shape)
    ph = 2 * np.pi * np.cumsum(f) / SR
    out = np.zeros_like(t)
    top = max(1, min(harmonics, int((SR / 2.2) / max(float(np.max(f)), 1.0))))
    for k in range(1, top + 1, 2):
        out += np.sin(k * ph) / k
    return out * (4 / np.pi) * 0.6


def noise(dur, rng=None):
    rng = rng or np.random
    return rng.uniform(-1, 1, int(dur * SR))


def partials(freq, dur, ratios, amps, taus=None, detune=0.0):
    """Sum of sine partials, each with its own exponential decay (bells, glass, gongs)."""
    t = t_axis(dur)
    out = np.zeros_like(t)
    for i, (r, a) in enumerate(zip(ratios, amps)):
        f = freq * r * (1 + detune * (i % 3 - 1))
        if f > SR / 2.1:
            continue
        env = np.exp(-t / taus[i]) if taus is not None else 1.0
        out += a * env * np.sin(2 * np.pi * f * t)
    return out


# ----------------------------------------------------------------- filtering ----

def _fft_filter(x, response_fn):
    n = len(x)
    size = 1 << (n - 1).bit_length()
    spec = np.fft.rfft(x, size)
    freqs = np.fft.rfftfreq(size, 1.0 / SR)
    spec *= response_fn(freqs)
    return np.fft.irfft(spec, size)[:n]


def lowpass(x, cutoff, order=2):
    return _fft_filter(x, lambda f: 1.0 / np.sqrt(1.0 + (f / cutoff) ** (2 * order)))


def highpass(x, cutoff, order=2):
    return _fft_filter(x, lambda f: 1.0 - 1.0 / np.sqrt(1.0 + (f / max(cutoff, 1.0)) ** (2 * order)))


def bandpass(x, centre, width):
    """Gaussian band centred on `centre` Hz, `width` = std-dev in Hz."""
    return _fft_filter(x, lambda f: np.exp(-0.5 * ((f - centre) / width) ** 2))


def formants(x, bands):
    """Vowel-like sound: sum of band-passed copies [(centre, width, gain), ...]."""
    out = np.zeros_like(x)
    for c, w, g in bands:
        out += g * bandpass(x, c, w)
    return out


def sweep_lowpass(x, start, end, steps=24):
    """Low-pass whose cutoff glides from start to end Hz over the signal (block crossfade)."""
    n = len(x)
    cuts = np.geomspace(start, end, steps)
    out = np.zeros(n)
    pos = np.linspace(0, steps - 1, n)
    for i, c in enumerate(cuts):
        w = np.clip(1 - np.abs(pos - i), 0, 1)
        out += w * lowpass(x, c)
    return out


# -------------------------------------------------------------------- effects ----

def reverb(x, seconds=1.6, wet=0.25, damping=4000.0, seed=7, predelay=0.012):
    """Convolution reverb with a synthetic decaying-noise impulse response."""
    rng = np.random.RandomState(seed)
    n = int(seconds * SR)
    ir = rng.uniform(-1, 1, n) * np.exp(-np.arange(n) / (seconds * SR / 5.0))
    ir = lowpass(ir, damping, order=1)
    ir[: int(predelay * SR)] = 0
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    size = 1 << (len(x) + n - 1).bit_length()
    y = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x) + n]
    out = np.zeros(len(y))
    out[: len(x)] += x * (1 - wet)
    out += y * wet * 3.0
    return out


def echo(x, delay, feedback=0.4, taps=4, tone=3000.0):
    out = x.copy()
    out = np.concatenate([out, np.zeros(int(delay * SR * taps))])
    for k in range(1, taps + 1):
        d = int(delay * SR * k)
        out[d:d + len(x)] += lowpass(x, tone, 1) * (feedback ** k)
    return out


def distort(x, amount=3.0):
    return np.tanh(x * amount) / np.tanh(amount)


def pitch_curve(f0, f1, dur, curve=3.0):
    """Frequency array gliding from f0 to f1, quickly at first (kicks, zaps)."""
    t = np.linspace(0, 1, int(dur * SR))
    return f1 + (f0 - f1) * np.exp(-curve * t)


# ----------------------------------------------------------------- instruments ----

def pluck(freq, dur, decay=0.996, bright=0.5, seed=1):
    """Karplus-Strong string (lute / harp / guitar). Computed block-wise with numpy, then
    resampled slightly so the pitch is exact (integer delay lines are out of tune)."""
    period = SR / freq
    p = max(int(round(period - 0.5)), 4)
    eff = p + 0.5                       # the 2-point average adds half a sample of delay
    ratio = eff / period                # >1: read faster -> higher; we want exactly `freq`
    n_out = int(dur * SR)
    n_gen = int(n_out * ratio) + p * 2 + 8
    rng = np.random.RandomState(seed + int(freq))
    burst = rng.uniform(-1, 1, p + 1)
    burst = lowpass(burst - burst.mean(), 1500 + bright * 9000, 1)
    burst -= burst.mean()
    out = np.zeros(n_gen)
    out[: p + 1] = burst
    s = p + 1
    while s < n_gen:
        e = min(s + p, n_gen)
        out[s:e] = decay * 0.5 * (out[s - p:e - p] + out[s - p - 1:e - p - 1])
        s = e
    idx = np.arange(n_out) * ratio
    i0 = np.floor(idx).astype(int)
    fr = idx - i0
    i1 = np.minimum(i0 + 1, n_gen - 1)
    sig = out[np.minimum(i0, n_gen - 1)] * (1 - fr) + out[i1] * fr
    sig = sig - np.mean(sig)
    return fade(sig / (np.max(np.abs(sig)) + 1e-9), 0.001, 0.03)


def pad(freq, dur, voices=3, detune=0.004, bright=1800.0, attack=0.6, release=0.8):
    sig = np.zeros(int(dur * SR))
    for v in range(voices):
        d = (v - (voices - 1) / 2) * detune
        sig += saw(freq * (1 + d), dur, harmonics=14)
    sig = lowpass(sig, bright, 1) / voices
    return sig * adsr(len(sig), attack, 0.2, 0.85, release)


def flute(freq, dur, vib=5.0, vib_depth=0.006, breath=0.05, seed=2):
    t = t_axis(dur)
    f = freq * (1 + vib_depth * np.sin(2 * np.pi * vib * t) * np.minimum(t / 0.25, 1.0))
    ph = 2 * np.pi * np.cumsum(f) / SR
    sig = np.sin(ph) + 0.25 * np.sin(2 * ph) + 0.08 * np.sin(3 * ph)
    rng = np.random.RandomState(seed)
    sig += breath * bandpass(rng.uniform(-1, 1, len(t)), freq * 2, freq * 0.5) * 8
    return sig * adsr(len(sig), 0.06, 0.1, 0.8, 0.1) * 0.6


def fiddle(freq, dur, vib=5.5, seed=3):
    t = t_axis(dur)
    f = freq * (1 + 0.007 * np.sin(2 * np.pi * vib * t) * np.minimum(t / 0.2, 1.0))
    sig = saw(f, dur, harmonics=18)
    sig = lowpass(sig, 3200, 1)
    return sig * adsr(len(sig), 0.05, 0.1, 0.85, 0.08) * 0.55


def brass(freq, dur, bright=2400.0):
    sig = saw(freq, dur, harmonics=20) + 0.5 * saw(freq * 1.003, dur, harmonics=20)
    env = adsr(len(sig), 0.07, 0.15, 0.8, 0.1)
    sig = sweep_lowpass(sig, bright * 0.35, bright, 8) * env
    return sig * 0.5


def strings(freq, dur):
    sig = saw(freq * 0.997, dur, 16) + saw(freq * 1.003, dur, 16) + saw(freq, dur, 16)
    sig = lowpass(sig, 2200, 1) / 3
    return sig * adsr(len(sig), 0.25, 0.2, 0.85, 0.3) * 0.7


def choir(freq, dur, vowel="a"):
    bands = {"a": [(800, 90, 1.0), (1150, 110, 0.5), (2900, 200, 0.12)],
             "o": [(450, 70, 1.0), (800, 90, 0.4), (2830, 200, 0.08)],
             "u": [(325, 60, 1.0), (700, 80, 0.3), (2700, 200, 0.05)]}[vowel]
    t = t_axis(dur)
    f = freq * (1 + 0.004 * np.sin(2 * np.pi * 5.2 * t))
    src = saw(f, dur, 30) + 0.7 * saw(f * 1.004, dur, 30) + 0.6 * saw(f * 0.996, dur, 30)
    sig = formants(src, bands)
    return sig * adsr(len(sig), 0.9, 0.3, 0.9, 1.0) * 0.7


def organ(freq, dur):
    t = t_axis(dur)
    out = np.zeros_like(t)
    for r, a in [(0.5, 0.5), (1, 1.0), (2, 0.6), (3, 0.35), (4, 0.3), (6, 0.15), (8, 0.1)]:
        if freq * r < SR / 2.2:
            out += a * np.sin(2 * np.pi * freq * r * t)
    return out * adsr(len(out), 0.05, 0.1, 0.9, 0.2) * 0.35


def bell(freq, dur=3.0, brightness=1.0):
    ratios = [0.5, 1.0, 1.19, 1.56, 2.0, 2.51, 2.74, 3.0, 4.07]
    amps = [0.45, 1.0, 0.55, 0.4, 0.35 * brightness, 0.25 * brightness, 0.2 * brightness, 0.15 * brightness, 0.1 * brightness]
    taus = [dur * 0.5, dur * 0.4, dur * 0.3, dur * 0.25, dur * 0.2, dur * 0.18, dur * 0.15, dur * 0.12, dur * 0.1]
    sig = partials(freq, dur, ratios, amps, taus)
    sig[: int(0.002 * SR)] *= np.linspace(0, 1, int(0.002 * SR))
    return sig * 0.5


def glock(freq, dur=1.2):
    return partials(freq, dur, [1, 2.76, 5.4, 8.9], [1.0, 0.4, 0.2, 0.1], [dur * 0.4, dur * 0.2, dur * 0.12, dur * 0.07]) * 0.6


# ----------------------------------------------------------------------- drums ----

def kick(dur=0.35, f0=130, f1=42):
    n = int(dur * SR)
    f = pitch_curve(f0, f1, dur, 9.0)
    sig = np.sin(2 * np.pi * np.cumsum(f) / SR) * expdecay(n, dur * 0.35)
    click = lowpass(np.random.RandomState(4).uniform(-1, 1, n), 2500, 1) * expdecay(n, 0.004)
    return distort(sig + 0.25 * click, 1.4)


def snare(dur=0.25, seed=5):
    n = int(dur * SR)
    nz = highpass(np.random.RandomState(seed).uniform(-1, 1, n), 1200) * expdecay(n, dur * 0.3)
    tone = np.sin(2 * np.pi * np.cumsum(pitch_curve(260, 170, dur, 12.0)) / SR) * expdecay(n, dur * 0.12)
    return nz * 0.8 + tone * 0.5


def hat(dur=0.08, seed=6, open_=False):
    d = 0.3 if open_ else dur
    n = int(d * SR)
    return highpass(np.random.RandomState(seed).uniform(-1, 1, n), 6000) * expdecay(n, d * 0.25) * 0.5


def tom(freq=110, dur=0.4):
    n = int(dur * SR)
    f = pitch_curve(freq * 1.5, freq, dur, 10.0)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * expdecay(n, dur * 0.3)


def taiko(dur=0.7, freq=70):
    n = int(dur * SR)
    f = pitch_curve(freq * 2.2, freq, dur, 11.0)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * expdecay(n, dur * 0.3)
    skin = lowpass(np.random.RandomState(8).uniform(-1, 1, n), 900, 1) * expdecay(n, 0.05)
    return distort(body + 0.35 * skin, 1.8)


def shaker(dur=0.09, seed=9):
    n = int(dur * SR)
    return bandpass(np.random.RandomState(seed).uniform(-1, 1, n), 7500, 2500) * np.hanning(n) * 0.4


def clap(dur=0.18, seed=10):
    n = int(dur * SR)
    sig = bandpass(np.random.RandomState(seed).uniform(-1, 1, n), 1500, 700) * expdecay(n, 0.06)
    for k in range(3):
        sig[int(k * 0.011 * SR):] *= 1.0
    return sig * 1.2


# ------------------------------------------------------------------------ output ----

def normalize(x, peak=0.9):
    m = np.max(np.abs(x))
    return x * (peak / m) if m > 1e-9 else x


def to_int16(x):
    return (np.clip(x, -1.0, 1.0) * 32767).astype(np.int16)


def save_wav(path, x, sr=None):
    import wave
    sr = sr or SR
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(to_int16(x).tobytes())
