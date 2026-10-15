"""Sound-effect recipes. Each recipe is registered with @sfx(name, variants, gain) and
returns a float array at synth.SR. Variants (name_1, name_2 ...) get a different seed `i`.
tools/gen_audio.py renders them all into assets/audio/sfx/*.wav.

To change a sound: edit its recipe and re-run  python tools/gen_audio.py sfx
"""
import numpy as np
import synth as S

REG = {}     # name -> (function, variants, gain, loop)


def sfx(name, variants=1, gain=0.85, loop=False):
    def deco(fn):
        REG[name] = (fn, variants, gain, loop)
        return fn
    return deco


# ------------------------------------------------------------------ helpers ----

def nz(dur, rng):
    return rng.uniform(-1, 1, int(dur * S.SR))


def sweep_band(x, c0, c1, width_ratio=0.35, steps=20):
    n = len(x)
    cs = np.geomspace(c0, c1, steps)
    pos = np.linspace(0, steps - 1, n)
    out = np.zeros(n)
    for i, c in enumerate(cs):
        w = np.clip(1 - np.abs(pos - i), 0, 1)
        out += w * S.bandpass(x, c, c * width_ratio)
    return out


def swell(n, peak=0.4):
    t = np.linspace(0, 1, n)
    up = np.clip(t / peak, 0, 1) ** 1.5
    down = np.clip((1 - t) / (1 - peak), 0, 1) ** 1.5
    return np.minimum(up, down)


def thump(freq=80, dur=0.25, f_end=None):
    f = S.pitch_curve(freq * 1.8, f_end or freq, dur, 10.0)
    return np.sin(2 * np.pi * np.cumsum(f) / S.SR) * S.expdecay(int(dur * S.SR), dur * 0.3)


def click(dur=0.02, f=3000, rng=None):
    rng = rng or np.random.RandomState(1)
    n = int(dur * S.SR)
    return S.bandpass(rng.uniform(-1, 1, n), f, f * 0.4) * S.expdecay(n, dur * 0.3)


def voice(f0, dur, bands, rng, noise=0.05, vib=5.0):
    """A sung/grunted vowel: saw source (pitch f0 can be an array) through formant bands."""
    t = S.t_axis(dur)
    f = np.broadcast_to(np.asarray(f0, dtype=np.float64), t.shape) * (1 + 0.01 * np.sin(2 * np.pi * vib * t))
    src = S.saw(f, dur, 40) + noise * rng.uniform(-1, 1, len(t)) * 3
    return S.formants(src, bands)


A_ = [(800, 100, 1.0), (1150, 130, 0.5), (2900, 250, 0.15)]
O_ = [(450, 80, 1.0), (800, 100, 0.4), (2830, 250, 0.08)]
U_ = [(325, 60, 1.0), (700, 90, 0.3), (2700, 250, 0.05)]
E_ = [(550, 80, 1.0), (1750, 150, 0.45), (2600, 250, 0.15)]
I_ = [(300, 60, 1.0), (2200, 200, 0.4), (3000, 250, 0.2)]


def coin_ping(freq=2400, dur=0.35):
    return S.partials(freq, dur, [1, 1.51, 2.4], [1.0, 0.5, 0.25], [dur * 0.25, dur * 0.18, dur * 0.1]) * 0.7


def shimmer(dur=1.0, base=1200, rng=None, density=22, up=True):
    rng = rng or np.random.RandomState(3)
    out = np.zeros(int(dur * S.SR))
    for k in range(density):
        t0 = rng.uniform(0, dur * 0.85)
        f = base * (1 + (t0 / dur if up else -t0 / dur * 0.5)) * rng.choice([1, 1.25, 1.5, 2.0])
        S.place(out, S.glock(f, 0.35) * rng.uniform(0.3, 1.0), t0)
    return out


def crackle(dur, rng, rate=60, f=3500, decay=0.004):
    out = np.zeros(int(dur * S.SR))
    for _ in range(int(dur * rate)):
        t0 = rng.uniform(0, dur)
        S.place(out, click(0.02, f * rng.uniform(0.5, 1.5), rng) * rng.uniform(0.2, 1.0), t0)
    return out


def plop(rng, f0=900, f1=260, dur=0.16):
    """A drop in water: a falling sine and a puff of filtered noise."""
    n = int(dur * S.SR)
    f = S.pitch_curve(f0, f1, dur, 4.0)
    tone = np.sin(2 * np.pi * np.cumsum(f) / S.SR) * S.expdecay(n, dur * 0.3)
    splash = S.bandpass(nz(dur, rng), 3000, 1500) * S.expdecay(n, dur * 0.2) * 0.35
    return tone + splash


def loopable(sig, tail):
    """Make a seamless loop: fold the last `tail` seconds onto the start with a crossfade."""
    n = int(tail * S.SR)
    body = sig[:-n].copy()
    ramp = np.linspace(0, 1, n)
    body[:n] = body[:n] * ramp + sig[-n:] * (1 - ramp)
    return body


# =============================================================== PLAYER COMBAT ====

@sfx("sword_swing", 3, 0.7)
def _(rng, i):
    d = 0.26 + 0.03 * i
    x = sweep_band(nz(d, rng), 700 + 250 * i, 3200 - 300 * i, 0.5)
    return x * swell(len(x), 0.35)


@sfx("sword_hit", 3, 0.9)
def _(rng, i):
    d = 0.28
    n = int(d * S.SR)
    crack = S.highpass(nz(d, rng), 1500) * S.expdecay(n, 0.012)
    body = thump(110 - 15 * i, d) * 0.9
    ring = S.partials(900 + 120 * i, d, [1, 2.3, 3.7], [0.15, 0.1, 0.06], [0.12, 0.08, 0.05])
    return crack * 0.9 + body + ring


@sfx("sword_crit", 1, 0.95)
def _(rng, i):
    d = 0.5
    n = int(d * S.SR)
    crack = S.highpass(nz(d, rng), 1200) * S.expdecay(n, 0.02)
    ring = S.partials(1100, d, [1, 1.5, 2.3, 3.1], [0.5, 0.3, 0.25, 0.15], [0.35, 0.25, 0.2, 0.15])
    return crack + thump(90, d) + ring


@sfx("block_hit", 3, 0.9)
def _(rng, i):
    d = 0.45
    n = int(d * S.SR)
    ring = S.partials(520 + 90 * i, d, [1, 1.47, 2.09, 2.56, 3.4], [1, 0.7, 0.5, 0.4, 0.25], [0.25, 0.2, 0.15, 0.1, 0.08])
    clang = S.highpass(nz(d, rng), 2000) * S.expdecay(n, 0.02)
    return ring * 0.7 + clang * 0.8 + thump(140, d) * 0.4


@sfx("player_hurt", 3, 0.85)
def _(rng, i):
    d = 0.3
    f = S.pitch_curve(230 - 20 * i, 130, d, 4.0)
    v = voice(f, d, O_ if i != 1 else A_, rng, 0.08)
    return v * S.adsr(len(v), 0.01, 0.05, 0.7, 0.12)


@sfx("player_death", 1, 0.9)
def _(rng, i):
    d = 1.2
    f = S.pitch_curve(200, 70, d, 2.0)
    v = voice(f, d, O_, rng, 0.1)
    v *= S.adsr(len(v), 0.02, 0.1, 0.6, 0.5)
    out = np.zeros(int(1.8 * S.SR))
    S.place(out, v, 0.0)
    S.place(out, thump(60, 0.5) * 0.9, 0.9)
    S.place(out, S.lowpass(nz(0.5, rng), 600, 1) * S.expdecay(int(0.5 * S.SR), 0.15) * 0.6, 0.85)
    return out


@sfx("jump", 1, 0.5)
def _(rng, i):
    x = sweep_band(nz(0.2, rng), 400, 1400, 0.6)
    return x * swell(len(x), 0.5) * 0.8


@sfx("land", 2, 0.6)
def _(rng, i):
    d = 0.22
    return thump(70 + 10 * i, d) + S.lowpass(nz(d, rng), 1200, 1) * S.expdecay(int(d * S.SR), 0.05) * 0.6


def _step(name, lo, hi, dur, tone, decay):
    def make(rng, i):
        n = int(dur * S.SR)
        x = S.bandpass(nz(dur, rng), (lo + hi) / 2 * (0.85 + 0.1 * i), (hi - lo) / 2) * S.expdecay(n, decay)
        return x + tone * thump(90 + 6 * i, dur) * 0.5
    return make


sfx("footstep_grass", 4, 0.28)(_step("g", 500, 2600, 0.14, 0.2, 0.04))
sfx("footstep_stone", 4, 0.3)(_step("s", 1200, 4800, 0.12, 0.5, 0.025))
sfx("footstep_wood", 3, 0.32)(_step("w", 300, 1800, 0.16, 0.9, 0.05))
sfx("footstep_heavy", 2, 0.5)(_step("h", 200, 1000, 0.3, 1.6, 0.09))
sfx("footstep_snow", 4, 0.3)(_step("n", 300, 2200, 0.2, 0.15, 0.07))


@sfx("footstep_hoof", 3, 0.42)
def _(rng, i):
    # two quick hoof knocks (a trot): a hard click on top of a short wooden thump
    out = np.zeros(int(0.32 * S.SR))
    for k, t0 in enumerate([0.0, 0.11]):
        knock = S.bandpass(nz(0.12, rng), 1800 + 220 * i + 150 * k, 1500) * S.expdecay(int(0.12 * S.SR), 0.02)
        S.place(out, knock * 0.9 + thump(130 + 12 * i, 0.12) * 0.6, t0 + 0.012 * k * i)
    return out


@sfx("horse_whinny", 1, 0.7)
def _(rng, i):
    # a rising neigh: a harmonic stack with a wavering pitch through two vowel-like bands, then a short breath
    dur = 0.9
    n = int(dur * S.SR)
    t = np.linspace(0, 1, n)
    f = 520 + 520 * np.sin(np.pi * np.clip(t * 1.25, 0, 1)) ** 0.6 + 40 * np.sin(2 * np.pi * 14 * t)
    voice = np.zeros(n)
    phase = 2 * np.pi * np.cumsum(f) / S.SR
    for h in range(1, 12):
        voice += np.sin(h * phase) / h
    voice = S.formants(voice, [(900, 300, 1.0), (2300, 500, 0.6)])
    voice *= swell(n, 0.35)
    breath = S.bandpass(nz(0.3, rng), 1500, 900) * swell(int(0.3 * S.SR), 0.2) * 0.25
    out = np.zeros(int(1.3 * S.SR))
    S.place(out, voice * 0.7, 0.0)
    S.place(out, breath, 0.8)
    return out


@sfx("potion_drink", 1, 0.7)
def _(rng, i):
    out = np.zeros(int(1.1 * S.SR))
    for k, t0 in enumerate([0.0, 0.22, 0.42]):
        f = S.pitch_curve(260 + 60 * k, 420 + 60 * k, 0.14, -2.5)
        g = np.sin(2 * np.pi * np.cumsum(f) / S.SR) * np.hanning(len(f))
        S.place(out, g, t0, 0.8)
    S.place(out, S.lowpass(nz(0.5, rng), 1800, 1) * swell(int(0.5 * S.SR)) * 0.25, 0.0)
    S.place(out, shimmer(0.55, 1500, rng, 8), 0.6, 0.5)
    return out


@sfx("amb_rain", 1, 0.5, True)
def _(rng, i):
    d = 14.0
    hiss = S.highpass(S.lowpass(nz(d + 2, rng), 9000, 1), 800, 2)
    body = S.bandpass(nz(d + 2, rng), 2800, 1300)
    gust = np.clip(0.55 + 0.45 * S.lowpass(nz(d + 2, rng), 0.3, 2) * 40, 0.0, 1.0)
    out = (hiss * 0.5 + body * 0.35) * (0.78 + 0.22 * gust)
    out += crackle(d + 2, rng, 110, 5200) * 0.22
    return loopable(out, 2.0)


@sfx("amb_rain_roof", 1, 0.45, True)
def _(rng, i):
    d = 14.0
    out = S.lowpass(nz(d + 2, rng), 1800, 2) * 0.5 + S.lowpass(nz(d + 2, rng), 220, 2) * 0.35
    out += crackle(d + 2, rng, 45, 1600) * 0.5
    for _k in range(int(d * 2.5)):
        S.place(out, thump(rng.uniform(150, 260), 0.08, 90), rng.uniform(0, d), rng.uniform(0.03, 0.09))
    return loopable(out, 2.0)


@sfx("thunder", 2, 0.85)
def _(rng, i):
    d = 4.5 + 0.6 * i
    n = int(d * S.SR)
    out = np.zeros(n)
    t = np.linspace(0, 1, n)
    crack = S.bandpass(nz(0.25, rng), 1800, 900) * S.expdecay(int(0.25 * S.SR), 0.06)
    S.place(out, crack, 0.0, 0.45)
    rumble = S.sweep_lowpass(nz(d, rng), 500, 70, 16)
    roll = 0.55 + 0.45 * np.sin(2 * np.pi * (1.1 + 0.5 * i) * d * t + rng.uniform(0, 6))
    env = np.minimum(t / 0.05, 1.0) * np.exp(-t * 3.2)
    S.place(out, rumble * roll * env, 0.0, 1.0)
    S.place(out, S.sine(S.pitch_curve(60, 38, d, 1.5), d) * env, 0.0, 0.35)
    return out


@sfx("fish_cast", 1, 0.7)
def _(rng, i):
    out = np.zeros(int(0.9 * S.SR))
    whoosh = sweep_band(nz(0.35, rng), 2500, 700, 0.5) * swell(int(0.35 * S.SR), 0.5)
    S.place(out, whoosh, 0.0, 0.6)
    S.place(out, plop(rng), 0.38, 0.9)
    return out


@sfx("fish_bite", 1, 0.7)
def _(rng, i):
    out = np.zeros(int(0.5 * S.SR))
    S.place(out, plop(rng, 700, 300, 0.12), 0.0, 0.8)
    S.place(out, plop(rng, 1100, 400, 0.10), 0.10, 0.6)
    return out


@sfx("fish_catch", 1, 0.75)
def _(rng, i):
    out = np.zeros(int(1.0 * S.SR))
    S.place(out, S.bandpass(nz(0.3, rng), 2500, 1800) * swell(int(0.3 * S.SR), 0.3), 0.0, 0.5)
    S.place(out, plop(rng, 800, 300, 0.2), 0.05, 0.7)
    S.place(out, shimmer(0.6, 1400, rng, 10), 0.25, 0.6)
    return out


@sfx("fish_escape", 1, 0.65)
def _(rng, i):
    out = np.zeros(int(0.6 * S.SR))
    S.place(out, thump(160, 0.3, 70), 0.0, 0.6)
    S.place(out, plop(rng, 600, 200, 0.2), 0.12, 0.7)
    return out


@sfx("eat", 2, 0.6)
def _(rng, i):
    out = np.zeros(int(0.8 * S.SR))
    for k, t0 in enumerate([0.0, 0.22, 0.46]):
        S.place(out, S.bandpass(nz(0.12, rng), 1400 + 200 * k + 100 * i, 700) * S.expdecay(int(0.12 * S.SR), 0.04), t0, 0.7)
    S.place(out, shimmer(0.4, 1200, rng, 6), 0.6, 0.35)
    return out


@sfx("potion_buff", 1, 0.75)
def _(rng, i):
    return shimmer(1.2, 900, rng, 28) + S.pad(330, 1.2, 3, 0.005, 2500, 0.3, 0.6) * 0.25


@sfx("heal", 1, 0.7)
def _(rng, i):
    out = np.zeros(int(1.4 * S.SR))
    for k, n in enumerate([72, 76, 79, 84]):
        S.place(out, S.glock(S.midi(n), 0.9), 0.11 * k)
    S.place(out, S.pad(S.midi(60), 1.4, 3, 0.004, 2000, 0.25, 0.7) * 0.25, 0.0)
    return S.reverb(out, 1.0, 0.25)[:len(out)]


# ======================================================================= SKILLS ====

@sfx("skill_heavy", 1, 0.95)
def _(rng, i):
    out = np.zeros(int(0.8 * S.SR))
    w = sweep_band(nz(0.4, rng), 300, 2200, 0.55)
    S.place(out, w * swell(len(w), 0.7), 0.0, 0.9)
    S.place(out, thump(65, 0.5) * 1.2, 0.3)
    S.place(out, S.highpass(nz(0.3, rng), 1500) * S.expdecay(int(0.3 * S.SR), 0.02), 0.3)
    return out


@sfx("skill_shield", 1, 0.8)
def _(rng, i):
    out = np.zeros(int(1.1 * S.SR))
    for k, n in enumerate([67, 71, 74, 79]):
        S.place(out, S.partials(S.midi(n), 0.9, [1, 2.0, 3.01, 4.2], [1, 0.4, 0.3, 0.2], [0.5, 0.3, 0.2, 0.15]) * 0.5, 0.07 * k)
    S.place(out, S.highpass(nz(0.2, rng), 3000) * S.expdecay(int(0.2 * S.SR), 0.04), 0.0, 0.6)
    return S.reverb(out, 0.9, 0.2)[:len(out)]


@sfx("skill_whirl", 1, 0.8)
def _(rng, i):
    d = 1.0
    x = sweep_band(nz(d, rng), 500, 1800, 0.6)
    trem = 0.6 + 0.4 * np.sin(2 * np.pi * 7 * S.t_axis(d))
    return x * trem * swell(len(x), 0.5)


@sfx("skill_blessing", 1, 0.75)
def _(rng, i):
    out = np.zeros(int(2.2 * S.SR))
    for n in [57, 64, 69]:
        S.place(out, S.choir(S.midi(n), 2.0, "a") * 0.6, 0.0)
    S.place(out, shimmer(1.8, 1400, rng, 22), 0.2, 0.8)
    S.place(out, S.bell(S.midi(81), 1.8) * 0.3, 0.1)
    return S.reverb(out, 1.4, 0.3)[:len(out)]


@sfx("skill_dash", 1, 0.8)
def _(rng, i):
    x = sweep_band(nz(0.3, rng), 3500, 600, 0.5)
    return S.mix(x * swell(len(x), 0.25), thump(100, 0.2) * 0.5)


@sfx("skill_shout", 1, 0.95)
def _(rng, i):
    d = 1.1
    f = S.pitch_curve(150, 85, d, 1.5)
    v = voice(f, d, [(600, 120, 1.0), (1000, 150, 0.6), (2400, 300, 0.2)], rng, 0.25)
    v = S.distort(v / (np.max(np.abs(v)) + 1e-9), 3.0) * S.adsr(len(v), 0.03, 0.1, 0.8, 0.4)
    return S.reverb(v, 0.8, 0.2)[:len(v)]


@sfx("skill_wall", 1, 0.9)
def _(rng, i):
    out = np.zeros(int(1.0 * S.SR))
    S.place(out, S.lowpass(nz(0.9, rng), 500, 1) * swell(int(0.9 * S.SR), 0.3) * 1.2, 0.0)
    for k in range(5):
        S.place(out, thump(60 + 10 * k, 0.3) * 0.8, 0.1 + 0.12 * k)
    S.place(out, S.partials(220, 0.6, [1, 1.6, 2.4], [0.4, 0.3, 0.2], [0.3, 0.2, 0.1]), 0.55)
    return out


@sfx("skill_frenzy", 1, 0.9)
def _(rng, i):
    d = 1.0
    f = S.pitch_curve(90, 180, d, -1.5)
    v = voice(f, d, [(500, 100, 1.0), (1200, 150, 0.5)], rng, 0.4)
    v = S.distort(v / (np.max(np.abs(v)) + 1e-9), 4.0)
    return v * S.adsr(len(v), 0.1, 0.1, 0.8, 0.3)


@sfx("skill_lightning", 1, 0.95)
def _(rng, i):
    out = np.zeros(int(1.6 * S.SR))
    S.place(out, crackle(0.35, rng, 140, 4500), 0.0, 1.0)
    S.place(out, S.highpass(nz(0.12, rng), 800) * S.expdecay(int(0.12 * S.SR), 0.03) * 1.3, 0.3)
    S.place(out, S.lowpass(nz(1.2, rng), 300, 2) * S.expdecay(int(1.2 * S.SR), 0.4) * 2.0, 0.32)
    S.place(out, thump(45, 0.8) * 1.2, 0.32)
    return out


@sfx("skill_flame", 1, 0.85)
def _(rng, i):
    d = 1.2
    x = S.lowpass(nz(d, rng), 1800, 1) * swell(int(d * S.SR), 0.3)
    return x * 1.2 + crackle(d, rng, 90, 3000) * 0.5 * swell(int(d * S.SR), 0.5)


@sfx("skill_holy_circle", 1, 0.8)
def _(rng, i):
    out = np.zeros(int(2.4 * S.SR))
    for n in [53, 60, 65, 72]:
        S.place(out, S.choir(S.midi(n), 2.2, "o") * 0.55, 0.0)
    S.place(out, S.bell(S.midi(77), 2.0) * 0.35, 0.5)
    S.place(out, shimmer(2.0, 1000, rng, 25), 0.1, 0.8)
    return S.reverb(out, 1.6, 0.3)[:len(out)]


@sfx("skill_resurrect", 1, 0.85)
def _(rng, i):
    out = np.zeros(int(3.0 * S.SR))
    S.place(out, S.bell(S.midi(60), 2.8), 0.0, 0.8)
    for n in [60, 64, 67, 72]:
        S.place(out, S.choir(S.midi(n), 2.5, "a") * 0.6, 0.3)
    S.place(out, shimmer(2.4, 1200, rng, 30), 0.6)
    return S.reverb(out, 1.8, 0.3)[:len(out)]


@sfx("cooldown_ready", 1, 0.4)
def _(rng, i):
    return S.glock(S.midi(88), 0.4)


# ================================================================== PROGRESSION ====

def fanfare(notes, step=0.14, hold=1.0, brass_gain=0.6):
    out = np.zeros(int((step * len(notes) + hold + 1.0) * S.SR))
    for k, n in enumerate(notes):
        dur = hold + step * (len(notes) - k) * 0.4 if k < len(notes) - 1 else hold + 0.5
        S.place(out, S.brass(S.midi(n), dur, 2600) * brass_gain, k * step)
        S.place(out, S.glock(S.midi(n + 12), 0.8) * 0.3, k * step)
    return S.reverb(out, 1.4, 0.25)[:len(out)]


@sfx("level_up", 1, 0.9)
def _(rng, i):
    return fanfare([60, 64, 67, 72, 76, 79], 0.12, 1.0)


@sfx("quest_new", 1, 0.8)
def _(rng, i):
    out = np.zeros(int(1.6 * S.SR))
    S.place(out, S.lowpass(nz(0.25, rng), 3000, 1) * swell(int(0.25 * S.SR)) * 0.5, 0.0)
    S.place(out, S.brass(S.midi(62), 0.5) * 0.5, 0.25)
    S.place(out, S.brass(S.midi(69), 0.9) * 0.5, 0.5)
    return S.reverb(out, 1.0, 0.25)[:len(out)]


@sfx("quest_ready", 1, 0.75)
def _(rng, i):
    out = np.zeros(int(1.3 * S.SR))
    for k, n in enumerate([79, 83, 88]):
        S.place(out, S.glock(S.midi(n), 1.0), 0.12 * k)
    return S.reverb(out, 0.9, 0.2)[:len(out)]


@sfx("quest_done", 1, 0.9)
def _(rng, i):
    return fanfare([55, 62, 67, 71, 74], 0.18, 1.3)


@sfx("quest_item", 1, 0.8)
def _(rng, i):
    return S.mix(shimmer(0.9, 1300, rng, 16), S.glock(S.midi(84), 0.8) * 0.5)


@sfx("talent_learn", 1, 0.8)
def _(rng, i):
    out = np.zeros(int(1.2 * S.SR))
    S.place(out, S.bell(S.midi(79), 1.1), 0.0, 0.6)
    S.place(out, shimmer(0.9, 1500, rng, 14), 0.05)
    return S.reverb(out, 0.9, 0.2)[:len(out)]


@sfx("gold_pickup", 3, 0.55)
def _(rng, i):
    out = np.zeros(int(0.5 * S.SR))
    S.place(out, coin_ping(2300 + 200 * i), 0.0)
    S.place(out, coin_ping(3100 + 150 * i), 0.07, 0.8)
    return out


@sfx("item_pickup", 2, 0.6)
def _(rng, i):
    f = S.pitch_curve(300, 700 + 100 * i, 0.12, -2.0)
    return np.sin(2 * np.pi * np.cumsum(f) / S.SR) * np.hanning(len(f)) * 0.8


@sfx("equip", 2, 0.7)
def _(rng, i):
    d = 0.4
    n = int(d * S.SR)
    return S.partials(700 + 60 * i, d, [1, 1.7, 2.6], [0.6, 0.4, 0.2], [0.15, 0.1, 0.07]) + S.bandpass(nz(d, rng), 900, 400) * S.expdecay(n, 0.05) * 0.8


@sfx("error", 1, 0.5)
def _(rng, i):
    d = 0.25
    x = S.square(110, d) * 0.6 + S.square(116, d) * 0.4
    return S.lowpass(x, 900, 1) * S.adsr(len(x), 0.005, 0.02, 0.9, 0.05)


@sfx("buy", 1, 0.7)
def _(rng, i):
    out = np.zeros(int(0.8 * S.SR))
    for k in range(5):
        S.place(out, coin_ping(2000 + 400 * rng.rand()), 0.06 * k, 0.7)
    return out


@sfx("sell", 1, 0.7)
def _(rng, i):
    out = np.zeros(int(0.8 * S.SR))
    for k in range(4):
        S.place(out, coin_ping(2800 - 350 * k), 0.07 * k, 0.8)
    return out


@sfx("chest_open", 1, 0.8)
def _(rng, i):
    out = np.zeros(int(1.2 * S.SR))
    d = 0.7
    f = S.pitch_curve(140, 320, d, -1.0)
    creak = S.lowpass(S.saw(f * (1 + 0.04 * np.sin(2 * np.pi * 14 * S.t_axis(d))), d, 20), 1500, 1)
    S.place(out, creak * swell(len(creak), 0.5) * 0.7, 0.0)
    S.place(out, click(0.03, 1800, rng) * 2.0, 0.0)
    S.place(out, thump(90, 0.2) * 0.8, 0.7)
    return out


@sfx("chest_coins", 1, 0.7)
def _(rng, i):
    out = np.zeros(int(1.0 * S.SR))
    for k in range(10):
        S.place(out, coin_ping(2000 + 1600 * rng.rand(), 0.4), 0.05 * k + 0.02 * rng.rand(), 0.4 + 0.5 * rng.rand())
    return out


@sfx("door_open", 1, 0.7)
def _(rng, i):
    d = 0.55
    f = S.pitch_curve(110, 190, d, -1.0)
    creak = S.lowpass(S.saw(f * (1 + 0.05 * np.sin(2 * np.pi * 11 * S.t_axis(d))), d, 20), 1100, 1)
    out = np.zeros(int(0.9 * S.SR))
    S.place(out, click(0.03, 1200, rng) * 1.5, 0.0)
    S.place(out, creak * swell(len(creak), 0.5) * 0.6, 0.04)
    S.place(out, thump(100, 0.2) * 0.6, 0.6)
    return out


@sfx("door_close", 1, 0.7)
def _(rng, i):
    return S.mix(thump(85, 0.35), S.lowpass(nz(0.3, rng), 900, 1) * S.expdecay(int(0.3 * S.SR), 0.06) * 0.5)


@sfx("dialogue_blip", 4, 0.3)
def _(rng, i):
    d = 0.045
    return S.sine(300 + 55 * i, d) * np.hanning(int(d * S.SR))


@sfx("ui_click", 1, 0.45)
def _(rng, i):
    return click(0.04, 2500, rng) * 1.2 + S.sine(1200, 0.04) * np.hanning(int(0.04 * S.SR)) * 0.4


@sfx("ui_hover", 1, 0.25)
def _(rng, i):
    return S.sine(1800, 0.03) * np.hanning(int(0.03 * S.SR))


@sfx("window_open", 1, 0.45)
def _(rng, i):
    x = sweep_band(nz(0.22, rng), 800, 3000, 0.5)
    return x * swell(len(x), 0.6)


@sfx("window_close", 1, 0.45)
def _(rng, i):
    x = sweep_band(nz(0.2, rng), 2800, 700, 0.5)
    return x * swell(len(x), 0.4)


# ================================================================== ENEMIES ====

def rattle(dur, rng, count=10, f=2400):
    out = np.zeros(int(dur * S.SR))
    for k in range(count):
        t0 = rng.uniform(0, dur * 0.8)
        S.place(out, S.bandpass(nz(0.05, rng), f * rng.uniform(0.6, 1.4), 500) * S.expdecay(int(0.05 * S.SR), 0.012), t0, rng.uniform(0.4, 1.0))
    return out


@sfx("skel_attack", 2, 0.6)
def _(rng, i):
    x = sweep_band(nz(0.3, rng), 500, 2400, 0.5)
    return x * swell(len(x), 0.4) * 0.8 + rattle(0.3, rng, 5) * 0.6


@sfx("skel_hurt", 3, 0.75)
def _(rng, i):
    return S.mix(rattle(0.3, rng, 8, 2800), thump(150, 0.1) * 0.5)


@sfx("skel_death", 2, 0.85)
def _(rng, i):
    d = 1.1
    out = np.zeros(int(d * S.SR))
    t = 0.0
    gap = 0.03
    while t < d - 0.1:
        S.place(out, S.bandpass(nz(0.06, rng), rng.uniform(1500, 3500), 600) * S.expdecay(int(0.06 * S.SR), 0.015), t, rng.uniform(0.5, 1.0))
        t += gap
        gap *= 1.12
    S.place(out, thump(75, 0.3) * 0.7, d * 0.55)
    return out


# --- creatures made from props (golem, haunted tree, pumpkin, mimic)

@sfx("stone_hit", 3, 0.9)
def _(rng, i):
    d = 0.4
    n = int(d * S.SR)
    crack = S.bandpass(nz(d, rng), 900 + 200 * i, 700) * S.expdecay(n, 0.02)
    grind = S.lowpass(S.bandpass(nz(d, rng), 220, 160), 500) * S.expdecay(n, 0.12) * 1.4
    return crack * 0.9 + grind + thump(70 - 8 * i, d) * 0.9


@sfx("stone_death", 2, 0.95)
def _(rng, i):
    d = 1.5
    out = np.zeros(int(d * S.SR))
    S.place(out, thump(55, 0.6) * 1.1, 0.0)
    t0 = 0.05
    while t0 < d - 0.3:
        n = int(0.09 * S.SR)
        S.place(out, S.bandpass(nz(0.09, rng), rng.uniform(300, 1800), 500) * S.expdecay(n, 0.03), t0, rng.uniform(0.4, 1.0))
        t0 += rng.uniform(0.04, 0.16)
    S.place(out, thump(45, 0.5) * 0.9, 0.9)
    return S.reverb(out, 0.9, 0.18)[:len(out)]


@sfx("wood_hit", 3, 0.85)
def _(rng, i):
    d = 0.35
    n = int(d * S.SR)
    knock = S.partials(190 + 40 * i, d, [1, 2.4, 4.1], [1.0, 0.5, 0.25], [0.09, 0.05, 0.03])
    creak = S.lowpass(S.saw(S.pitch_curve(150, 260 + 30 * i, 0.3, 2.0), 0.3, 18), 1200) * swell(int(0.3 * S.SR), 0.5) * 0.5
    out = np.zeros(n)
    S.place(out, knock, 0.0)
    S.place(out, creak, 0.04)
    S.place(out, click(0.02, 1400, rng) * 1.5, 0.0)
    return out


@sfx("wood_death", 2, 0.9)
def _(rng, i):
    d = 1.3
    out = np.zeros(int(d * S.SR))
    for k in range(7):
        S.place(out, click(0.03, rng.uniform(500, 1500), rng) * 2.0, 0.08 * k + rng.uniform(0, 0.03), rng.uniform(0.5, 1.0))
        S.place(out, S.partials(rng.uniform(120, 220), 0.25, [1, 2.2], [1.0, 0.4], [0.08, 0.04]), 0.08 * k, 0.8)
    creak = S.lowpass(S.saw(S.pitch_curve(220, 70, 0.9, 2.5), 0.9, 18), 900) * swell(int(0.9 * S.SR), 0.35) * 0.6
    S.place(out, creak, 0.2)
    S.place(out, thump(60, 0.5) * 0.9, 0.9)
    return out


@sfx("squish_hit", 3, 0.8)
def _(rng, i):
    return S.mix(plop(rng, 520 + 80 * i, 140, 0.22) * 1.3, thump(110, 0.12) * 0.4)


@sfx("squish_death", 2, 0.85)
def _(rng, i):
    d = 0.9
    out = np.zeros(int(d * S.SR))
    for k in range(5):
        S.place(out, plop(rng, rng.uniform(500, 900), rng.uniform(120, 220), 0.2), 0.11 * k, 1.0 - 0.12 * k)
    S.place(out, S.lowpass(nz(0.5, rng), 600) * S.expdecay(int(0.5 * S.SR), 0.2) * 0.8, 0.0)
    return out


@sfx("mimic_snap", 3, 0.9)
def _(rng, i):
    d = 0.5
    out = np.zeros(int(d * S.SR))
    for k in range(2):
        S.place(out, S.partials(260 - 30 * i, 0.18, [1, 2.1, 3.3], [1.0, 0.6, 0.3], [0.05, 0.03, 0.02]), 0.18 * k, 1.0)
        S.place(out, click(0.025, 2200, rng) * 2.2, 0.18 * k)
    S.place(out, roar(0.35, 120 + 20 * i, 70, rng, 0.3) * 0.5, 0.0)
    return out


@sfx("skel_aggro", 2, 0.7)
def _(rng, i):
    d = 0.7
    x = S.bandpass(nz(d, rng), 1200, 500) * swell(int(d * S.SR), 0.3) * 0.6
    return x + rattle(d, rng, 12, 2200) * 0.5


@sfx("arrow_shoot", 1, 0.6)
def _(rng, i):
    out = np.zeros(int(0.5 * S.SR))
    S.place(out, S.pluck(180, 0.35, 0.99, 0.9) * 0.9, 0.0)
    S.place(out, sweep_band(nz(0.2, rng), 3500, 1200, 0.5) * swell(int(0.2 * S.SR), 0.2) * 0.6, 0.02)
    return out


@sfx("arrow_hit", 2, 0.7)
def _(rng, i):
    return S.mix(thump(160, 0.15), S.highpass(nz(0.1, rng), 1800) * S.expdecay(int(0.1 * S.SR), 0.015) * 0.6)


@sfx("orb_cast", 1, 0.7)
def _(rng, i):
    d = 0.8
    f = S.pitch_curve(250, 1100, d, -1.5)
    x = np.sin(2 * np.pi * np.cumsum(f) / S.SR) + 0.4 * np.sin(4 * np.pi * np.cumsum(f) / S.SR)
    return x * swell(len(x), 0.8) * 0.6 + shimmer(d, 900, rng, 10) * 0.4


@sfx("orb_hit", 2, 0.8)
def _(rng, i):
    d = 0.5
    return S.mix(crackle(0.25, rng, 120, 4000), thump(70, d) * 0.9, S.sine(S.pitch_curve(900, 200, d, 6.0), d) * S.expdecay(int(d * S.SR), 0.12) * 0.5)


def roar(dur, f_start, f_end, rng, rough=0.35, bands=None, drive=3.5):
    f = S.pitch_curve(f_start, f_end, dur, 1.2)
    v = voice(f, dur, bands or [(500, 110, 1.0), (900, 140, 0.7), (2000, 300, 0.2)], rng, rough)
    v = S.distort(v / (np.max(np.abs(v)) + 1e-9), drive)
    return v * S.adsr(len(v), 0.06, 0.1, 0.85, 0.35)


@sfx("brute_roar", 1, 0.9)
def _(rng, i):
    return S.reverb(roar(1.0, 100, 60, rng), 0.7, 0.15)[:int(1.0 * S.SR)]


@sfx("boss_roar", 1, 1.0)
def _(rng, i):
    d = 2.0
    v = roar(d, 75, 40, rng, 0.45, drive=4.5)
    out = np.zeros(int(2.8 * S.SR))
    S.place(out, v, 0.0)
    S.place(out, thump(40, 1.0) * 1.2, 0.05)
    return S.reverb(out, 1.6, 0.3)[:len(out)]


@sfx("warlord_roar", 1, 1.0)
def _(rng, i):
    return S.reverb(roar(1.6, 90, 45, rng, 0.4, drive=4.0), 1.3, 0.25)[:int(1.9 * S.SR)]


# ====================================================================== WORLD ====

@sfx("bell_toll", 2, 0.9)
def _(rng, i):
    f = [S.midi(53), S.midi(48)][i]
    return S.reverb(S.bell(f, 4.5), 1.5, 0.25)[:int(5.5 * S.SR)]


@sfx("invasion_horn", 1, 0.95)
def _(rng, i):
    d = 3.2
    out = np.zeros(int((d + 1.5) * S.SR))
    for fnote, st in [(S.midi(43), 0.0), (S.midi(50), 1.4)]:
        h = S.brass(fnote, 1.6, 1800) + 0.5 * S.brass(fnote * 2.0, 1.6, 1500)
        S.place(out, h, st, 0.7)
    return S.reverb(out, 1.8, 0.3)[:len(out)]


@sfx("wave_horn", 1, 0.9)
def _(rng, i):
    out = np.zeros(int(2.4 * S.SR))
    S.place(out, S.brass(S.midi(46), 1.4, 1600), 0.0, 0.8)
    S.place(out, S.brass(S.midi(53), 0.9, 1800), 1.0, 0.8)
    return S.reverb(out, 1.2, 0.25)[:len(out)]


@sfx("village_saved", 1, 0.95)
def _(rng, i):
    return fanfare([60, 67, 72, 76, 79, 84], 0.16, 1.6)


@sfx("village_fell", 1, 0.9)
def _(rng, i):
    out = np.zeros(int(5.0 * S.SR))
    S.place(out, S.bell(S.midi(41), 4.5), 0.0, 0.9)
    S.place(out, S.strings(S.midi(40), 4.0) * 0.5, 0.2)
    S.place(out, S.strings(S.midi(46), 4.0) * 0.4, 0.2)
    return S.reverb(out, 2.0, 0.3)[:len(out)]


@sfx("rescue_alert", 1, 0.95)
def _(rng, i):
    # A fast, urgent call: three rising brass herald blasts that cut through the ambience
    d = 2.4
    out = np.zeros(int((d + 1.2) * S.SR))
    for fnote, st in [(S.midi(55), 0.0), (S.midi(60), 0.35), (S.midi(67), 0.75)]:
        h = S.brass(fnote, 0.7, 2200) + 0.4 * S.brass(fnote * 1.5, 0.7, 1800)
        S.place(out, h, st, 0.85)
    return S.reverb(out, 1.4, 0.25)[:len(out)]


@sfx("rescue_failed", 1, 0.9)
def _(rng, i):
    # A sad, mournful cue when Andreas falls: a deep bell followed by falling minor chords
    out = np.zeros(int(4.0 * S.SR))
    S.place(out, S.bell(S.midi(45), 3.8), 0.0, 0.85)
    S.place(out, S.strings(S.midi(57), 3.0) * 0.45, 0.25)
    S.place(out, S.strings(S.midi(53), 2.8) * 0.40, 0.7)
    S.place(out, S.strings(S.midi(48), 2.6) * 0.35, 1.2)
    return S.reverb(out, 1.8, 0.3)[:len(out)]


@sfx("rooster", 1, 0.55)
def _(rng, i):
    out = np.zeros(int(1.6 * S.SR))
    for t0, f0, f1, d in [(0.0, 700, 1100, 0.22), (0.3, 800, 1350, 0.25), (0.62, 900, 1500, 0.3), (1.0, 1300, 700, 0.5)]:
        f = S.pitch_curve(f0, f1, d, -1.5 if f1 > f0 else 3.0)
        v = voice(f, d, [(1100, 200, 1.0), (2200, 300, 0.7), (3300, 400, 0.4)], rng, 0.1, 25.0)
        S.place(out, v * np.hanning(len(v)), t0, 0.7)
    return out


@sfx("wolf_howl", 1, 0.5)
def _(rng, i):
    d = 3.2
    t = S.t_axis(d)
    f = 320 + 280 * np.sin(np.pi * np.clip(t / d, 0, 1) ** 0.8) * 1.0 - 60 * np.clip(t / d - 0.7, 0, 1) * 3
    v = voice(f, d, [(500, 90, 1.0), (1000, 120, 0.5), (1800, 200, 0.15)], rng, 0.12, 4.0)
    return S.reverb(v * S.adsr(len(v), 0.5, 0.2, 0.9, 0.8), 1.4, 0.3)[:len(v)]


@sfx("owl_hoot", 1, 0.45)
def _(rng, i):
    out = np.zeros(int(1.6 * S.SR))
    for t0 in [0.0, 0.45, 0.9]:
        d = 0.3
        f = S.pitch_curve(430, 380, d, 3.0)
        S.place(out, S.sine(f, d) * np.hanning(int(d * S.SR)), t0, 0.8 if t0 < 0.8 else 1.0)
    return S.reverb(out, 1.0, 0.25)[:len(out)]


@sfx("voice_blip", 4, 0.35)
def _(rng, i):
    d = 0.14
    f = S.pitch_curve(170 + 25 * i, 150 + 25 * i, d, 2.0) * (1 + 0.1 * (i % 2))
    v = voice(f, d, [E_, A_, O_, I_][i], rng, 0.05)
    return v * np.hanning(len(v))


@sfx("mug_clink", 2, 0.55)
def _(rng, i):
    return S.mix(S.partials(1800 + 250 * i, 0.5, [1, 2.2, 3.5], [0.7, 0.4, 0.2], [0.25, 0.15, 0.1]), click(0.01, 4000, rng) * 0.5)


@sfx("crowd_cheer", 1, 0.55)
def _(rng, i):
    d = 1.6
    x = np.zeros(int(d * S.SR))
    for k in range(7):
        dd = d - 0.2 * k
        f = S.pitch_curve(200 + 30 * k, 260 + 25 * k, dd, -0.5)
        v = voice(f, dd, [A_, O_, E_][k % 3], rng, 0.2)
        S.place(x, v * swell(len(v), 0.25), 0.05 * k, 0.5)
    return x


# ============================================================ AMBIENT LOOPS ====

def bird(rng, base):
    d = rng.uniform(0.08, 0.2)
    f = S.pitch_curve(base * rng.uniform(0.9, 1.1), base * rng.uniform(1.3, 1.9), d, -1.0 if rng.rand() < 0.5 else 3.0)
    return np.sin(2 * np.pi * np.cumsum(f) / S.SR) * np.hanning(len(f))


def wind(dur, rng, gain=1.0):
    x = S.lowpass(nz(dur, rng), 500, 2)
    slow = 0.5 + 0.5 * S.lowpass(nz(dur, rng), 0.35, 2) * 40
    return x * np.clip(slow, 0.1, 1.2) * gain


@sfx("amb_day", 1, 0.5, True)
def _(rng, i):
    d = 24.0
    out = wind(d + 2, rng) * 0.5
    for _k in range(int(d * 1.2)):
        t0 = rng.uniform(0, d)
        base = rng.choice([2400, 3000, 3600, 4200])
        for r in range(rng.randint(1, 5)):
            S.place(out, bird(rng, base), t0 + r * 0.13, rng.uniform(0.04, 0.12))
    return loopable(out, 2.0)


@sfx("amb_night", 1, 0.5, True)
def _(rng, i):
    # Night is only a soft wind. The "crickets" that used to be here were a steady train of 4.3 to 5 kHz beeps,
    # 9.5 times a second, all night long: it sounded like an alarm (checked in the file with an FFT: a 5 kHz tone
    # 3800 times the median, pulsing at 9.5 Hz; no other ambience loop pulses).
    d = 24.0
    out = wind(d + 2, rng) * 0.45
    return loopable(out, 2.0)


@sfx("amb_tavern", 1, 0.45, True)
def _(rng, i):
    d = 16.0
    out = np.zeros(int((d + 2) * S.SR))
    for k in range(28):
        t0 = rng.uniform(0, d)
        dd = rng.uniform(0.15, 0.5)
        f = S.pitch_curve(rng.uniform(110, 220), rng.uniform(100, 200), dd, 2.0)
        v = voice(f, dd, [A_, E_, O_, I_][rng.randint(4)], rng, 0.1)
        S.place(out, v * np.hanning(len(v)), t0, 0.25)
    out = S.lowpass(out, 3000, 1) + S.lowpass(nz(d + 2, rng), 700, 2) * 0.05
    return loopable(out, 2.0)


@sfx("amb_church", 1, 0.4, True)
def _(rng, i):
    d = 16.0
    out = np.zeros(int((d + 3) * S.SR))
    for n, st in [(41, 0.0), (48, 3.0), (53, 7.0), (45, 10.0)]:
        S.place(out, S.choir(S.midi(n), 6.0, "u") * 0.5, st)
    return loopable(S.reverb(out, 2.0, 0.4)[:len(out)], 3.0)


@sfx("amb_crypt", 1, 0.5, True)
def _(rng, i):
    d = 20.0
    out = wind(d + 2, rng, 1.2)
    out += S.sine(48, d + 2) * 0.08 * (0.6 + 0.4 * np.sin(2 * np.pi * 0.2 * S.t_axis(d + 2)))
    for _k in range(7):
        t0 = rng.uniform(0, d)
        S.place(out, S.partials(1500, 0.3, [1, 2.3], [0.5, 0.25], [0.06, 0.04]), t0, 0.15)
    return loopable(out, 2.0)


@sfx("amb_mountain", 1, 0.5, True)
def _(rng, i):
    d = 22.0
    out = wind(d + 2, rng, 1.5)
    out += S.bandpass(nz(d + 2, rng), 1400, 500) * 0.05 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.11 * S.t_axis(d + 2)))
    return loopable(out, 2.0)


@sfx("amb_ash", 1, 0.5, True)
def _(rng, i):
    # The Ash Valley: a low hot wind, a slow rumble of the lava river (a steady low tone, no pulse faster than 0.1 Hz)
    # and embers crackling far away. No tonal beeps (see check_ambience.py).
    d = 22.0
    out = wind(d + 2, rng, 0.8) * 0.8
    out += S.sine(41, d + 2) * 0.07 * (0.65 + 0.35 * np.sin(2 * np.pi * 0.08 * S.t_axis(d + 2)))
    out += S.lowpass(nz(d + 2, rng), 220, 2) * 0.10
    out += crackle(d + 2, rng, 16, 3000) * 0.22
    return loopable(out, 2.0)


@sfx("fire_loop", 1, 0.5, True)
def _(rng, i):
    d = 6.0
    out = S.lowpass(nz(d + 1, rng), 1400, 1) * 0.25 + crackle(d + 1, rng, 55, 3500) * 0.7
    return loopable(out, 1.0)


@sfx("water_loop", 1, 0.4, True)
def _(rng, i):
    d = 8.0
    out = S.bandpass(nz(d + 1, rng), 900, 500) * (0.5 + 0.3 * np.sin(2 * np.pi * 0.7 * S.t_axis(d + 1)))
    for _k in range(18):
        S.place(out, S.sine(S.pitch_curve(500, 1100, 0.08, -1.0), 0.08) * np.hanning(int(0.08 * S.SR)), rng.uniform(0, d), 0.15)
    return loopable(out, 1.0)


@sfx("wind_loop", 1, 0.45, True)
def _(rng, i):
    d = 12.0
    return loopable(wind(d + 2, rng, 1.0) + S.bandpass(nz(d + 2, rng), 900, 300) * 0.08, 2.0)


@sfx("amb_market", 1, 0.45, True)
def _(rng, i):
    # Village square market chatter: gentle outdoor murmurs, distant conversation, occasional rustling
    d = 16.0
    out = np.zeros(int((d + 2) * S.SR))
    for _k in range(32):
        t0 = rng.uniform(0, d)
        dd = rng.uniform(0.18, 0.55)
        f = S.pitch_curve(rng.uniform(120, 260), rng.uniform(110, 220), dd, 1.8)
        v = voice(f, dd, [A_, E_, O_, I_][rng.randint(4)], rng, 0.08)
        S.place(out, v * np.hanning(len(v)), t0, 0.22)
    for _k in range(12):
        t0 = rng.uniform(0, d)
        click_dur = rng.uniform(0.02, 0.05)
        clatter = S.bandpass(nz(click_dur, rng), rng.uniform(800, 2200), 400) * S.expdecay(int(click_dur * S.SR), 0.02)
        S.place(out, clatter, t0, 0.12)
    out = S.lowpass(out, 2800, 1) + S.lowpass(nz(d + 2, rng), 600, 2) * 0.04
    return loopable(out, 2.0)


@sfx("dog_bark", 2, 0.6)
def _(rng, i):
    # Friendly canine bark: quick pitch drop with husky body
    d = 0.22 + 0.04 * i
    f = S.pitch_curve(360 - 30 * i, 160 - 20 * i, d, 2.5)
    body = S.saw(f, d, 8) * S.adsr(int(d * S.SR), 0.015, 0.06, 0.5, 0.1)
    growl = S.bandpass(nz(d, rng), 450, 200) * S.expdecay(int(d * S.SR), 0.08)
    return S.lowpass(body * 0.8 + growl * 0.4, 1800, 1)


@sfx("dog_whimper", 1, 0.5)
def _(rng, i):
    # Affectionate happy whimper when petted
    d = 0.35
    f = S.pitch_curve(420, 680, d, -2.0)
    w = S.sine(f, d) * S.adsr(int(d * S.SR), 0.04, 0.1, 0.6, 0.12)
    return w * (1 + 0.08 * np.sin(2 * np.pi * 12 * S.t_axis(d)))


@sfx("sheep_baa", 2, 0.55)
def _(rng, i):
    # Farm sheep bleat: nasal formant around 320 Hz with trembling vibrato
    d = 0.55 + 0.1 * i
    t = S.t_axis(d)
    vibrato = 1.0 + 0.05 * np.sin(2 * np.pi * 7.5 * t)
    f0 = (180 + 20 * i) * vibrato
    sig = S.saw(f0, d, 10) * S.adsr(int(d * S.SR), 0.05, 0.15, 0.7, 0.15)
    formant = S.bandpass(sig, 420 + 30 * i, 140) * 1.2 + S.bandpass(sig, 950, 200) * 0.5
    return formant


@sfx("craft_upgrade", 1, 0.75)
def _(rng, i):
    # Anvil strike followed by a rising magical shimmer
    d = 0.95
    out = np.zeros(int(d * S.SR))
    # Anvil hammer ping
    ping = coin_ping(1150, 0.45)
    body = S.bandpass(nz(0.35, rng), 650, 250) * S.expdecay(int(0.35 * S.SR), 0.08)
    S.place(out, ping * 1.2, 0.0)
    S.place(out, body * 0.6, 0.0)
    # Magic chime rising shimmer
    mag = shimmer(0.65, 950, rng, 18, True)
    S.place(out, mag * 0.85, 0.15)
    return out


@sfx("swing_2h", 2, 0.75)
def _(rng, i):
    # Deep, heavy two-handed greatsword whoosh
    d = 0.38 + 0.04 * i
    sweep = sweep_band(nz(d, rng), 280 + 50 * i, 1600 - 150 * i, 0.6)
    sub = thump(110 - 10 * i, d, 60)
    return (sweep * 0.85 + sub * 0.45) * swell(len(sweep), 0.3)


@sfx("swing_dual", 2, 0.70)
def _(rng, i):
    # Rapid twin-blade slashes close together
    d = 0.30
    out = np.zeros(int(d * S.SR))
    slash1 = sweep_band(nz(0.18, rng), 1100, 3600, 0.4) * swell(int(0.18 * S.SR), 0.35)
    slash2 = sweep_band(nz(0.18, rng), 1400, 4200, 0.4) * swell(int(0.18 * S.SR), 0.35)
    S.place(out, slash1, 0.0)
    S.place(out, slash2, 0.10)
    return out


@sfx("scarecrow_groan", 2, 0.60)
def _(rng, i):
    # Wooden dry creak and shuddering spooky groan
    d = 0.65 + 0.1 * i
    f = S.pitch_curve(140 + 20 * i, 90, d, 2.0)
    groan = voice(f, d, [O_, U_][i % 2], rng, 0.15, 8.0) * S.adsr(int(d * S.SR), 0.08, 0.15, 0.6, 0.18)
    crk = crackle(d, rng, 40, 2200) * 0.4
    return groan * 0.8 + crk


@sfx("flame_altar", 1, 0.65)
def _(rng, i):
    # Deep resonant temple hum with volcanic flame flare
    d = 1.4
    t = S.t_axis(d)
    hum = S.sine(S.pitch_curve(85, 110, d, -1.0), d) * S.adsr(int(d * S.SR), 0.15, 0.3, 0.7, 0.35)
    fire = S.bandpass(nz(d, rng), 750, 450) * S.adsr(int(d * S.SR), 0.2, 0.4, 0.5, 0.4)
    sparkles = shimmer(d * 0.7, 1600, rng, 12, True)
    out = hum * 0.7 + fire * 0.5
    S.place(out, sparkles * 0.4, 0.2)
    return out


