"""Music: a small composition engine plus nine loop-able tracks.

A track is a SPEC dict (tempo, chord per bar, which parts play). render(spec) turns it into
a mono float array at RATE that loops seamlessly (notes and reverb wrap around the end).
Edit a spec (chords, tempo, parts, gains) and run  python tools/gen_audio.py music <name>.

Everything is deterministic (seeded) so regenerating gives the same music.
"""
import numpy as np
import synth as S

RATE = 22050

CHORDS = {
    "maj": [0, 4, 7], "min": [0, 3, 7], "dim": [0, 3, 6], "sus2": [0, 2, 7], "sus4": [0, 5, 7],
    "m7": [0, 3, 7, 10], "maj7": [0, 4, 7, 11], "7": [0, 4, 7, 10], "pwr": [0, 7, 12], "m9": [0, 3, 7, 14],
}
MODES = {
    "major": [0, 2, 4, 5, 7, 9, 11], "mixo": [0, 2, 4, 5, 7, 9, 10], "dorian": [0, 2, 3, 5, 7, 9, 10],
    "minor": [0, 2, 3, 5, 7, 8, 10], "phrygian": [0, 1, 3, 5, 7, 8, 10], "harmonic": [0, 2, 3, 5, 7, 8, 11],
    "pent": [0, 2, 4, 7, 9], "minpent": [0, 3, 5, 7, 10],
}

# ------------------------------------------------------------------ drum hits ----
DRUM = {"k": S.kick, "s": S.snare, "h": S.hat, "o": lambda: S.hat(open_=True), "t": S.tom,
        "T": S.taiko, "c": S.clap, "x": S.shaker}
DRUM_GAIN = {"k": 0.9, "s": 0.6, "h": 0.35, "o": 0.35, "t": 0.6, "T": 0.9, "c": 0.5, "x": 0.5}


def clamp_low(n, floor):
    """Shift a note up by octaves until it is at least `floor` (keeps bass/pad notes audible)."""
    while n < floor:
        n += 12
    return n


def chord_notes(root, quality, octave_shift=0, count=None):
    notes = [root + i + 12 * octave_shift for i in CHORDS[quality]]
    if count:
        while len(notes) < count:
            notes.append(notes[len(notes) - len(CHORDS[quality])] + 12)
    return notes


class Song:
    def __init__(self, spec):
        self.spec = spec
        self.beat = 60.0 / spec["bpm"]
        self.bpb = spec.get("bpb", 4)
        self.bar = self.beat * self.bpb
        self.bars = spec["bars"]
        self.length = int(self.bars * self.bar * S.SR)
        self.tail = int(6 * S.SR)
        self.buf = np.zeros(self.length + self.tail)
        self.rng = np.random.RandomState(spec.get("seed", 1))
        self.key = spec["key"]
        self.scale = MODES[spec.get("mode", "major")]
        self.cache = {}

    # chord of bar b: (root midi, quality)
    def chord(self, b):
        ch = self.spec["chords"]
        semi, q = ch[b % len(ch)]
        return self.key + semi, q

    def at(self, bar, beat):
        return (bar * self.bpb + beat) * self.beat

    def put(self, sig, bar, beat, gain=1.0):
        S.place(self.buf, sig, self.at(bar, beat), gain)

    def cached(self, key, fn):
        if key not in self.cache:
            self.cache[key] = fn()
        return self.cache[key]

    # ----------------------------------------------------------------- parts ----
    def part_pad(self, p):
        inst = {"pad": S.pad, "strings": S.strings, "choir": lambda f, d: S.choir(f, d, p.get("vowel", "a")),
                "organ": S.organ}[p.get("inst", "pad")]
        every = p.get("every", 1)
        for b in range(0, self.bars, every):
            root, q = self.chord(b)
            for n in chord_notes(root, q, p.get("oct", 0), p.get("voices")):
                n = clamp_low(n, 36 if p.get("inst") == "organ" else 45)
                dur = self.bar * every + 0.5
                key = (p["inst"], n, round(dur, 2), p.get("vowel"))
                self.put(self.cached(key, lambda: inst(S.midi(n), dur)), b, 0, p["gain"])

    def part_arp(self, p):
        inst = p.get("inst", "pluck")
        step = p.get("step", 0.5)                      # beats
        pattern = p["pattern"]                          # indices into chord tones (cycled)
        per_bar = int(self.bpb / step)
        for b in range(self.bars):
            root, q = self.chord(b)
            tones = chord_notes(root, q, p.get("oct", 0), 6)
            for k in range(per_bar):
                idx = pattern[k % len(pattern)]
                if idx is None:
                    continue
                n = tones[idx]
                vel = p["gain"] * (1.0 if k % 2 == 0 else 0.7) * (0.85 + 0.15 * self.rng.rand())
                dur = step * self.beat * p.get("len", 3.0)
                key = (inst, n, round(dur, 2))
                if inst == "pluck":
                    sig = self.cached(key, lambda: S.pluck(S.midi(n), dur, p.get("decay", 0.996), p.get("bright", 0.5)))
                else:
                    sig = self.cached(key, lambda: S.glock(S.midi(n), dur))
                self.put(sig, b, k * step, vel)

    def part_bass(self, p):
        inst = p.get("inst", "pluck")
        pattern = p["pattern"]                          # list of (beat, 0=root/1=fifth/2=octave, beats)
        for b in range(self.bars):
            root, q = self.chord(b)
            for beat, which, ln in pattern:
                n = clamp_low(root + [0, 7, 12][which] + p.get("oct", -24), 38)
                dur = ln * self.beat
                key = (inst, n, round(dur, 2))
                if inst == "pluck":
                    sig = self.cached(key, lambda: S.pluck(S.midi(n), dur + 0.1, 0.995, 0.15))
                elif inst == "saw":
                    sig = self.cached(key, lambda: S.lowpass(S.saw(S.midi(n), dur, 16), 700, 2) * S.adsr(int(dur * S.SR), 0.01, 0.05, 0.9, 0.05))
                else:
                    sig = self.cached(key, lambda: S.sine(S.midi(n), dur) * S.adsr(int(dur * S.SR), 0.02, 0.1, 0.9, 0.1))
                self.put(sig, b, beat, p["gain"])

    def part_drone(self, p):
        n = clamp_low(self.key + p.get("oct", -36), 33)
        dur = self.bars * self.bar + 3
        sig = S.sine(S.midi(n), dur) + 0.4 * S.sine(S.midi(n) * 2.003, dur) + p.get("fifth", 0.0) * S.sine(S.midi(n + 7), dur)
        sig *= 0.6 + 0.4 * np.sin(2 * np.pi * S.t_axis(dur) / (self.bar * 2))
        S.place(self.buf, sig, 0.0, p["gain"])

    def part_drums(self, p):
        steps = p.get("steps", 16)
        patterns = p["patterns"]                        # list of {drum letter: pattern string}
        fill_every = p.get("fill_every", 0)
        step_len = self.bar / steps
        for b in range(self.bars):
            pat = patterns[(b // p.get("pat_len", 1)) % len(patterns)]
            for letter, row in pat.items():
                for i, ch in enumerate(row):
                    if ch in "xX!":
                        vel = 1.0 if ch != "x" else 0.6
                        if ch == "!":
                            vel = 1.2
                        sig = self.cached(("d", letter), DRUM[letter])
                        S.place(self.buf, sig, b * self.bar + i * step_len, DRUM_GAIN[letter] * vel * p["gain"])
            if fill_every and b % fill_every == fill_every - 1:
                for i in range(steps - 4, steps):      # a short tom fill in the last beat of the phrase
                    sig = self.cached(("d", "t"), DRUM["t"])
                    S.place(self.buf, sig, b * self.bar + i * step_len, 0.7 * p["gain"])

    def part_stabs(self, p):
        pattern = p["pattern"]                          # (beat, beats long)
        for b in range(self.bars):
            root, q = self.chord(b)
            if p.get("every", 1) > 1 and b % p["every"] != 0:
                continue
            for beat, ln in pattern:
                for n in chord_notes(root, q, p.get("oct", 0)):
                    n = clamp_low(n, 48)
                    dur = ln * self.beat
                    key = ("br", n, round(dur, 2))
                    self.put(self.cached(key, lambda: S.brass(S.midi(n), dur, p.get("bright", 2200))), b, beat, p["gain"])

    def part_bells(self, p):
        for b in range(0, self.bars, p.get("every", 4)):
            root, q = self.chord(b)
            n = clamp_low(root + p.get("oct", 0) + (7 if p.get("fifth") and (b // p.get("every", 4)) % 2 else 0), 45)
            key = ("bell", n, p.get("dur", 4.0))
            self.put(self.cached(key, lambda: S.bell(S.midi(n), p.get("dur", 4.0))), b, p.get("beat", 0), p["gain"])

    def part_sparkle(self, p):
        """Sparse random glock/harp notes from the scale (night/crypt atmosphere)."""
        r = np.random.RandomState(p.get("seed", 5))
        for b in range(self.bars):
            root, q = self.chord(b)
            for _ in range(p.get("count", 2)):
                beat = r.choice(np.arange(0, self.bpb, 0.5))
                deg = r.choice(self.scale)
                n = self.key + p.get("oct", 24) + deg
                key = (p.get("inst", "glock"), n)
                if p.get("inst", "glock") == "glock":
                    sig = self.cached(key, lambda: S.glock(S.midi(n), 1.6))
                else:
                    sig = self.cached(key, lambda: S.pluck(S.midi(n), 2.0, 0.997, 0.6))
                self.put(sig, b, float(beat), p["gain"] * (0.5 + 0.5 * r.rand()))

    def part_melody(self, p):
        """Phrases of two bars built from chord tones and scale steps. The phrase is repeated
        (with a changed ending) so the tune sounds composed rather than random."""
        r = np.random.RandomState(p.get("seed", 3))
        inst = {"flute": S.flute, "fiddle": S.fiddle, "brass": lambda f, d: S.brass(f, d, 2000),
                "strings": S.strings, "choir": lambda f, d: S.choir(f, d, "a"), "pluck": lambda f, d: S.pluck(f, d, 0.996, 0.6),
                "glock": lambda f, d: S.glock(f, d)}[p["inst"]]
        scale = [s for s in MODES[p.get("scale", self.spec.get("mode", "major"))]]
        lo, hi = p["range"]
        rhythms = p["rhythms"]                          # each: list of (beat offset, length in beats)
        phrase_bars = p.get("phrase_bars", 2)
        rest_every = p.get("rest_every", 0)             # every Nth phrase is silent (breathing)
        memory = {}

        def pitches():
            return [self.key + o * 12 + s for o in range(-3, 4) for s in scale if lo <= self.key + o * 12 + s <= hi]

        allp = pitches()
        for ph in range(0, self.bars // phrase_bars):
            b0 = ph * phrase_bars
            if rest_every and ph % rest_every == rest_every - 1:
                continue
            slot = (ph // 2) % p.get("variety", 2)      # phrases repeat in pairs
            if slot not in memory:
                memory[slot] = {"rhythm": [rhythms[r.randint(len(rhythms))] for _ in range(phrase_bars)], "seed": r.randint(1 << 20)}
            mem = memory[slot]
            pr = np.random.RandomState(mem["seed"])
            cur = None
            for bi in range(phrase_bars):
                bar = b0 + bi
                root, q = self.chord(bar)
                tones = [t for t in allp if (t - root) % 12 in CHORDS[q]]
                for k, (off, ln) in enumerate(mem["rhythm"][bi]):
                    strong = off % 2 == 0
                    if cur is None or (strong and pr.rand() < 0.55):
                        pool = tones if cur is None else sorted(tones, key=lambda t: abs(t - cur))[:3]
                        cur = int(pr.choice(pool))
                    else:
                        i = allp.index(cur) if cur in allp else len(allp) // 2
                        i = int(np.clip(i + pr.choice([-2, -1, -1, 1, 1, 2]), 0, len(allp) - 1))
                        cur = allp[i]
                    note = cur
                    if ph % 2 == 1 and bi == phrase_bars - 1 and k == len(mem["rhythm"][bi]) - 1:
                        note = int(sorted(tones, key=lambda t: abs(t - root - 12))[0])  # answer phrase ends on a chord tone
                    dur = ln * self.beat * p.get("legato", 1.0)
                    key = (p["inst"], note, round(dur, 2))
                    self.put(self.cached(key, lambda: inst(S.midi(note), dur)), bar, off, p["gain"])

    # --------------------------------------------------------------- render ----
    def render(self):
        for p in self.spec["parts"]:
            getattr(self, "part_" + p["type"])(p)
        buf = self.buf
        main = buf[: self.length].copy()
        over = buf[self.length:]
        main[: len(over)] += over[: self.length]            # notes ringing past the end wrap to the start
        spec_rev = self.spec.get("reverb", (1.8, 0.28))
        y = S.reverb(main, spec_rev[0], spec_rev[1], 5000.0)
        out = y[: self.length].copy()
        tail = y[self.length:]
        out[: len(tail)] += tail[: self.length]
        out = out - np.mean(out)
        # level every track to the same loudness, then soft-limit the drum peaks
        out = out / (np.sqrt(np.mean(out ** 2)) + 1e-9) * 0.22
        return np.tanh(out * 1.6) / 1.6


# ===================================================================== TRACKS ====
J = lambda *a: list(a)

SPECS = {}

# --- the village by day: a warm folk tune (lute, flute, hand drum) ---------------
SPECS["day"] = dict(
    key=62, mode="major", bpm=104, bars=32, seed=11, reverb=(1.6, 0.24),
    chords=[(0, "maj"), (7, "maj"), (9, "min"), (5, "maj"), (0, "maj"), (7, "maj"), (5, "maj"), (0, "maj"),
            (5, "maj"), (0, "maj"), (4, "min"), (7, "maj"), (5, "maj"), (0, "maj"), (7, "maj"), (0, "sus4")],
    parts=[
        dict(type="arp", inst="pluck", step=0.5, pattern=[0, 1, 2, 1, 3, 2, 1, 2], gain=0.55, oct=0, len=4.0),
        dict(type="bass", inst="pluck", pattern=[(0, 0, 1.5), (2, 1, 1.5)], gain=0.7, oct=-24),
        dict(type="melody", inst="flute", range=(69, 86), scale="pent", seed=21, gain=0.8, variety=2, rest_every=4,
             rhythms=[[(0, 1.5), (1.5, 0.5), (2, 1), (3, 1)], [(0, 1), (1, 1), (2, 1.5), (3.5, 0.5)], [(0, 0.5), (0.5, 0.5), (1, 1), (2, 2)]]),
        dict(type="pad", inst="pad", gain=0.25, every=2, oct=-12),
        dict(type="drums", gain=0.5, patterns=[{"t": "x.......x.......", "x": "x.x.x.x.x.x.x.x."}, {"t": "x.......x...x...", "c": "....x.......x...", "x": "x.x.x.x.x.x.x.x."}]),
    ])

# --- the village by night: calm, a little lonely -------------------------------
SPECS["night"] = dict(
    key=57, mode="minor", bpm=66, bars=16, seed=12, reverb=(2.6, 0.38),
    chords=[(0, "min"), (8, "maj"), (3, "maj"), (10, "maj")],
    parts=[
        dict(type="pad", inst="strings", gain=0.4, every=1, oct=-12),
        dict(type="drone", gain=0.2, oct=-24),
        dict(type="sparkle", inst="pluck", count=3, oct=24, gain=0.4, seed=7),
        dict(type="bells", every=4, oct=0, gain=0.35, dur=5.0, fifth=True),
        dict(type="melody", inst="flute", range=(64, 79), scale="minpent", seed=5, gain=0.45, phrase_bars=4, rest_every=2, legato=1.6,
             rhythms=[[(0, 2), (2, 2)], [(0, 3), (3, 1)], [(0, 1.5), (1.5, 2.5)]]),
    ])

# --- the wilds beyond the village: open and a little uneasy ----------------------
SPECS["wild"] = dict(
    key=50, mode="dorian", bpm=84, bars=24, seed=13, reverb=(2.2, 0.32),
    chords=[(0, "min"), (10, "maj"), (8, "maj"), (10, "maj"), (0, "min"), (7, "min"), (8, "maj"), (10, "maj")],
    parts=[
        dict(type="pad", inst="pad", gain=0.38, every=2, oct=-12),
        dict(type="arp", inst="pluck", step=1.0, pattern=[0, 2, 1, 3], gain=0.5, oct=0, len=5.0, decay=0.997),
        dict(type="bass", inst="sine", pattern=[(0, 0, 3.5)], gain=0.35, oct=-24),
        dict(type="melody", inst="flute", range=(66, 84), scale="dorian", seed=33, gain=0.6, variety=2, rest_every=3, legato=1.1,
             rhythms=[[(0, 2), (2, 1), (3, 1)], [(0, 1), (1, 1), (2, 2)], [(0, 3), (3, 1)]]),
        dict(type="drums", gain=0.4, patterns=[{"t": "x...............", "x": "..x...x...x...x."}, {"t": "x.......x.......", "x": "..x...x...x...x."}]),
    ])

# --- fighting skeletons: war drums, driving strings -----------------------------
SPECS["combat"] = dict(
    key=50, mode="minor", bpm=148, bars=32, seed=14, reverb=(1.2, 0.2),
    chords=[(0, "min"), (0, "min"), (8, "maj"), (10, "maj"), (0, "min"), (0, "min"), (8, "maj"), (7, "maj")],
    parts=[
        dict(type="drums", gain=0.5, fill_every=8, patterns=[
            {"T": "!...x...!...x...", "s": "....x.......x...", "h": "x.x.x.x.x.x.x.x."},
            {"T": "!..x..x.!...x.x.", "s": "....x.......x..x", "h": "x.x.x.x.x.x.x.xx"}]),
        dict(type="bass", inst="saw", pattern=[(0, 0, 0.5), (0.5, 0, 0.5), (1, 0, 0.5), (1.5, 0, 0.5), (2, 0, 0.5), (2.5, 0, 0.5), (3, 1, 0.5), (3.5, 0, 0.5)], gain=0.3, oct=-24),
        dict(type="pad", inst="strings", gain=0.5, every=1, oct=0),
        dict(type="stabs", pattern=[(0, 1.5), (2, 0.5)], gain=0.45, oct=0, every=2, bright=2600),
        dict(type="melody", inst="strings", range=(62, 79), scale="minor", seed=44, gain=1.4, variety=2,
             rhythms=[[(0, 0.5), (0.5, 0.5), (1, 1), (2, 0.5), (2.5, 0.5), (3, 1)], [(0, 1), (1, 0.5), (1.5, 0.5), (2, 2)]]),
    ])

# --- the night invasion: heavier, bells, war horns ------------------------------
SPECS["invasion"] = dict(
    key=52, mode="harmonic", bpm=160, bars=32, seed=15, reverb=(1.6, 0.26),
    chords=[(0, "min"), (0, "min"), (8, "maj"), (7, "maj"), (0, "min"), (5, "min"), (8, "maj"), (7, "maj")],
    parts=[
        dict(type="drums", gain=0.55, fill_every=4, patterns=[
            {"T": "!.!.x.!.!.!.x.!.", "s": "....x.......x...", "h": "xxxxxxxxxxxxxxxx", "k": "x.....x...x....."},
            {"T": "!...!...!.x.!...", "s": "....x.......x.x.", "h": "x.x.x.x.x.x.x.x.", "k": "x...x...x...x..."}]),
        dict(type="bass", inst="saw", pattern=[(0, 0, 0.5), (0.5, 0, 0.5), (1, 0, 0.5), (1.5, 2, 0.5), (2, 0, 0.5), (2.5, 0, 0.5), (3, 1, 0.5), (3.5, 0, 0.5)], gain=0.32, oct=-24),
        dict(type="pad", inst="choir", vowel="o", gain=0.45, every=1, oct=0),
        dict(type="stabs", pattern=[(0, 1.0), (1.5, 0.5), (2, 1.0)], gain=0.5, oct=0, every=1, bright=2800),
        dict(type="bells", every=4, oct=-12, gain=0.5, dur=3.5),
        dict(type="melody", inst="brass", range=(60, 76), scale="harmonic", seed=55, gain=0.8, variety=2,
             rhythms=[[(0, 1.5), (1.5, 0.5), (2, 1), (3, 1)], [(0, 1), (1, 1), (2, 0.5), (2.5, 0.5), (3, 1)]]),
    ])

# --- boss fights: slow, huge, dissonant -----------------------------------------
SPECS["boss"] = dict(
    key=49, mode="phrygian", bpm=118, bars=32, seed=16, reverb=(2.6, 0.34),
    chords=[(0, "min"), (0, "min"), (1, "maj"), (0, "min"), (0, "min"), (8, "maj"), (1, "maj"), (0, "dim")],
    parts=[
        dict(type="pad", inst="choir", vowel="o", gain=0.6, every=1, oct=0, voices=4),
        dict(type="pad", inst="strings", gain=0.3, every=1, oct=-12),
        dict(type="drums", gain=0.55, fill_every=4, patterns=[
            {"T": "!.......!...x...", "k": "x.......x.......", "s": "............x..."},
            {"T": "!...x...!...x.x.", "k": "x...x...x...x...", "s": "....x.......x..."}]),
        dict(type="bass", inst="saw", pattern=[(0, 0, 1.5), (2, 0, 1.0), (3, 1, 1.0)], gain=0.3, oct=-24),
        dict(type="stabs", pattern=[(0, 2.0)], gain=0.45, oct=0, every=2, bright=2000),
        dict(type="bells", every=2, oct=-12, gain=0.4, dur=4.0, fifth=True),
        dict(type="melody", inst="brass", range=(55, 72), scale="phrygian", seed=66, gain=0.5, phrase_bars=4, variety=2,
             rhythms=[[(0, 2), (2, 1), (3, 1)], [(0, 1), (1, 1), (2, 2)]]),
    ])

# --- the old crypt: a drone, glass, a slow heartbeat -----------------------------
SPECS["crypt"] = dict(
    key=47, mode="phrygian", bpm=52, bars=12, seed=17, reverb=(3.2, 0.5),
    chords=[(0, "min"), (1, "maj"), (0, "min"), (6, "dim")],
    parts=[
        dict(type="drone", gain=0.2, oct=-12, fifth=0.3),
        dict(type="pad", inst="choir", vowel="u", gain=0.4, every=2, oct=-12),
        dict(type="sparkle", inst="glock", count=2, oct=24, gain=0.7, seed=9),
        dict(type="bells", every=3, oct=0, gain=0.4, dur=5.5),
        dict(type="drums", gain=0.3, patterns=[{"T": "!.......!......."}], steps=16),
    ])

# --- the tavern: a lively 6/8 jig ------------------------------------------------
SPECS["tavern"] = dict(
    key=55, mode="major", bpm=236, bpb=6, bars=32, seed=18, reverb=(0.9, 0.16),
    chords=[(0, "maj"), (7, "maj"), (4, "min"), (5, "maj"), (0, "maj"), (7, "maj"), (5, "maj"), (7, "maj")],
    parts=[
        dict(type="arp", inst="pluck", step=1.0, pattern=[0, 2, 1, 0, 2, 1], gain=0.6, oct=0, len=2.5),
        dict(type="bass", inst="pluck", pattern=[(0, 0, 2.5), (3, 1, 2.5)], gain=0.7, oct=-24),
        dict(type="melody", inst="fiddle", range=(67, 86), scale="major", seed=77, gain=0.7, variety=2, legato=0.9,
             rhythms=[[(0, 1), (1, 0.5), (1.5, 0.5), (2, 1), (3, 1), (4, 0.5), (4.5, 0.5), (5, 1)],
                      [(0, 0.5), (0.5, 0.5), (1, 1), (2, 1), (3, 1.5), (4.5, 0.5), (5, 1)]]),
        dict(type="drums", steps=6, gain=0.6, patterns=[{"k": "x..x..", "x": "x.xx.x"}, {"k": "x..x..", "c": "...x..", "x": "x.xx.x"}]),
    ])

# --- the church: slow choir and organ -------------------------------------------
SPECS["church"] = dict(
    key=53, mode="major", bpm=50, bars=12, seed=19, reverb=(3.0, 0.5),
    chords=[(0, "maj"), (9, "min"), (2, "min"), (7, "maj"), (0, "maj"), (5, "maj"), (7, "sus4"), (0, "maj")],
    parts=[
        dict(type="pad", inst="choir", vowel="a", gain=0.6, every=1, oct=0, voices=4),
        dict(type="pad", inst="organ", gain=0.15, every=1, oct=-12),
        dict(type="bass", inst="sine", pattern=[(0, 0, 3.8)], gain=0.15, oct=-24),
        dict(type="bells", every=4, oct=12, gain=0.5, dur=4.5),
    ])


# --- the Frontier beyond the mountains: cold, wide, a lonely horn -----------------
SPECS["mountain"] = dict(
    key=45, mode="minor", bpm=58, bars=16, seed=21, reverb=(3.0, 0.45),
    chords=[(0, "min"), (8, "maj"), (3, "maj"), (10, "maj")],
    parts=[
        dict(type="drone", gain=0.22, oct=-24, fifth=0.3),
        dict(type="pad", inst="strings", gain=0.38, every=2, oct=-12),
        dict(type="pad", inst="choir", vowel="o", gain=0.25, every=4, oct=0, voices=3),
        dict(type="bells", every=4, oct=-12, gain=0.35, dur=5.0, fifth=True),
        dict(type="melody", inst="brass", range=(55, 70), scale="minor", seed=88, gain=0.35, phrase_bars=4, rest_every=2, legato=1.4,
             rhythms=[[(0, 3), (3, 1)], [(0, 2), (2, 2)]]),
    ])


def make(name):
    def run():
        return Song(SPECS[name]).render()
    return run


TRACKS = {name: make(name) for name in SPECS}
