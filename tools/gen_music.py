#!/usr/bin/env python3
"""Original music for Corner Office, composed in code and rendered with numpy.

Every track here is written by hand as a small score (key, tempo, chord
loop, bass and melody rules, a drum pattern) and rendered with simple
synths: sines and triangles with envelopes, a one-pole low-pass, a little
feedback delay for room. Nothing is sampled; the pieces are the project's
own work, commercial use fine. Run from the repo root:

    python3 tools/gen_music.py            # renders every track to assets/audio/music
    python3 tools/gen_music.py box_by_box # one track

Loops are exact bar multiples and the tail of the delay is folded back
into the start, so each one loops without a click.
"""
import math
import os
import subprocess
import sys
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "music")

# --- building blocks ----------------------------------------------------

NOTE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def hz(name, octave):
    return 440.0 * 2 ** ((NOTE[name] + 12 * (octave - 4) - 9) / 12.0)


def midi_hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def env(n, a, d, s, r, hold):
    """ADSR in samples: attack, decay, sustain level, release, hold length (samples) before release."""
    a = max(1, int(a * SR))
    d = max(1, int(d * SR))
    r = max(1, int(r * SR))
    hold = max(a + d, int(hold))
    out = np.zeros(n)
    t = np.arange(n)
    out[:a] = np.linspace(0, 1, a)
    out[a:a + d] = np.linspace(1, s, d)
    out[a + d:hold] = s
    rel = np.linspace(s, 0, r)
    end = min(n, hold + r)
    out[hold:end] = rel[: end - hold]
    return out


def lowpass(x, cutoff):
    """One-pole low-pass, cutoff in Hz."""
    rc = 1.0 / (2 * math.pi * cutoff)
    dt = 1.0 / SR
    alpha = dt / (rc + dt)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += alpha * (x[i] - acc)
        y[i] = acc
    return y


def lowpass_fast(x, cutoff):
    # Vectorised approximation: recursive filter through scipy-free lfilter.
    rc = 1.0 / (2 * math.pi * cutoff)
    dt = 1.0 / SR
    alpha = dt / (rc + dt)
    # y[n] = alpha*x[n] + (1-alpha)*y[n-1]
    b = alpha
    a = 1 - alpha
    y = np.zeros_like(x)
    # process in chunks with pure numpy using cumulative trick
    # y[n] = b * sum_{k<=n} a^(n-k) x[k]
    n = len(x)
    chunk = 8192
    carry = 0.0
    powers = a ** np.arange(chunk)
    for start in range(0, n, chunk):
        seg = x[start:start + chunk]
        m = len(seg)
        # convolution via FFT for the chunk, plus the carry decaying in
        conv = np.convolve(seg, powers[:m])[:m] * b
        decay = carry * (a ** np.arange(1, m + 1))
        ys = conv + decay
        y[start:start + m] = ys
        carry = ys[-1]
    return y


def delay(x, seconds, feedback, mix):
    d = int(seconds * SR)
    out = x.copy()
    buf = np.zeros(len(x) + d)
    buf[:len(x)] = x
    for i in range(d, len(buf)):
        buf[i] += buf[i - d] * feedback
    wet = buf[:len(x)]
    return out * (1 - mix) + wet * mix


def fold_loop(x, bars_len):
    """Fold whatever rings past the loop length back onto the start."""
    core = x[:bars_len].copy()
    tail = x[bars_len:]
    n = min(len(tail), bars_len)
    core[:n] += tail[:n]
    return core


class Score:
    def __init__(self, bpm, bars, beats_per_bar=4):
        self.bpm = bpm
        self.beat = 60.0 / bpm
        self.bars = bars
        self.bpb = beats_per_bar
        self.length = int(bars * beats_per_bar * self.beat * SR)
        self.buf = np.zeros(self.length + int(4 * SR))

    def time(self, bar, beat):
        return (bar * self.bpb + beat) * self.beat

    def add(self, start_s, signal, gain=1.0):
        i = int(start_s * SR)
        if i >= len(self.buf):
            return
        n = min(len(signal), len(self.buf) - i)
        self.buf[i:i + n] += signal[:n] * gain

    # instruments ---------------------------------------------------------

    def pluck(self, freq, dur, gain=0.5, bright=1.0):
        n = int((dur + 0.6) * SR)
        t = np.arange(n) / SR
        tone = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(2 * np.pi * freq * 2 * t) * np.exp(-t * 6) + 0.12 * np.sin(2 * np.pi * freq * 3 * t) * np.exp(-t * 9)
        e = env(n, 0.004, 0.12, 0.35, 0.5, dur * SR)
        return tone * e * gain * bright

    def pad(self, freqs, dur, gain=0.18):
        n = int((dur + 1.2) * SR)
        t = np.arange(n) / SR
        tone = np.zeros(n)
        for f in freqs:
            tone += np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * (f * 1.005) * t) + 0.2 * np.sin(2 * np.pi * f * 0.5 * t)
        tone /= max(1, len(freqs))
        tone = lowpass_fast(tone, 900)
        e = env(n, 0.35, 0.2, 0.8, 1.0, dur * SR)
        return tone * e * gain

    def bass(self, freq, dur, gain=0.42):
        n = int((dur + 0.3) * SR)
        t = np.arange(n) / SR
        tri = 2 / np.pi * np.arcsin(np.sin(2 * np.pi * freq * t))
        tone = 0.7 * np.sin(2 * np.pi * freq * t) + 0.3 * tri
        tone = lowpass_fast(tone, 320)
        e = env(n, 0.006, 0.08, 0.6, 0.25, dur * SR)
        return tone * e * gain

    def marimba(self, freq, dur, gain=0.4):
        n = int((dur + 0.5) * SR)
        t = np.arange(n) / SR
        tone = np.sin(2 * np.pi * freq * t) * np.exp(-t * 4.0) + 0.3 * np.sin(2 * np.pi * freq * 4 * t) * np.exp(-t * 18)
        e = env(n, 0.002, 0.05, 0.4, 0.4, dur * SR)
        return tone * e * gain

    def bell(self, freq, dur, gain=0.25):
        n = int((dur + 1.5) * SR)
        t = np.arange(n) / SR
        tone = np.sin(2 * np.pi * freq * t) * np.exp(-t * 1.6) + 0.4 * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-t * 3.5)
        return tone * gain

    def kick(self, gain=0.9):
        n = int(0.28 * SR)
        t = np.arange(n) / SR
        f = 110 * np.exp(-t * 22) + 42
        tone = np.sin(2 * np.pi * np.cumsum(f) / SR)
        return tone * np.exp(-t * 9) * gain

    def snare(self, gain=0.35, brush=False):
        n = int(0.22 * SR)
        t = np.arange(n) / SR
        noise = np.random.default_rng(7).uniform(-1, 1, n)
        noise = lowpass_fast(noise, 3200 if brush else 5200)
        body = np.sin(2 * np.pi * 190 * t) * np.exp(-t * 30)
        return (noise * np.exp(-t * (14 if brush else 22)) * (0.6 if brush else 0.8) + body * 0.4) * gain

    def hat(self, gain=0.16, open_=False):
        n = int((0.18 if open_ else 0.06) * SR)
        t = np.arange(n) / SR
        noise = np.random.default_rng(11).uniform(-1, 1, n)
        noise = noise - lowpass_fast(noise, 6000)
        return noise * np.exp(-t * (16 if open_ else 60)) * gain

    def shaker(self, gain=0.1):
        n = int(0.09 * SR)
        t = np.arange(n) / SR
        noise = np.random.default_rng(3).uniform(-1, 1, n)
        noise = noise - lowpass_fast(noise, 4000)
        return noise * np.exp(-t * 40) * gain

    # render -------------------------------------------------------------

    def render(self, room=0.22, room_time=None, cutoff=None):
        x = self.buf
        if cutoff:
            x = lowpass_fast(x, cutoff)
        x = delay(x, room_time or (self.beat * 0.75), 0.32, room)
        x = fold_loop(x, self.length)
        peak = np.max(np.abs(x)) or 1.0
        x = x / peak * 0.84
        # Gentle soft clip for glue.
        x = np.tanh(x * 1.15) / math.tanh(1.15)
        return x


def chord(root_midi, kind):
    kinds = {"maj": [0, 4, 7], "min": [0, 3, 7], "maj7": [0, 4, 7, 11], "min7": [0, 3, 7, 10], "sus2": [0, 2, 7], "add9": [0, 4, 7, 14], "dom7": [0, 4, 7, 10], "min9": [0, 3, 7, 10, 14]}
    return [root_midi + i for i in kinds[kind]]


def write(name, x):
    os.makedirs(OUT, exist_ok=True)
    wav = os.path.join(OUT, name + ".wav")
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    stereo = np.repeat(data[:, None], 2, axis=1)
    with wave.open(wav, "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(stereo.tobytes())
    ogg = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "4", ogg], check=True)
    os.remove(wav)
    print("wrote", os.path.relpath(ogg))


# --- the pieces ----------------------------------------------------------

def box_by_box():
    """Marimba and brushes in F major: the unpacking afternoon. 84 bpm, 16 bars."""
    s = Score(84, 16)
    rng = np.random.default_rng(1)
    prog = [(65, "maj7"), (62, "min7"), (58, "maj7"), (60, "dom7")] * 4  # F, Dm, Bb, C
    for bar, (root, kind) in enumerate(prog):
        notes = chord(root, kind)
        s.add(s.time(bar, 0), s.pad([midi_hz(n) for n in notes], s.beat * 4), 0.6)
        s.add(s.time(bar, 0), s.bass(midi_hz(root - 24), s.beat * 1.5))
        s.add(s.time(bar, 2.5), s.bass(midi_hz(root - 24 + (7 if bar % 2 else 0)), s.beat * 1.0), 0.8)
        # Arpeggio on the marimba, eighths with a little swing and rests.
        for k in range(8):
            if rng.random() < 0.22:
                continue
            n = notes[k % len(notes)] + (12 if k >= 4 else 0)
            t = s.time(bar, k * 0.5 + (0.06 if k % 2 else 0))
            s.add(t, s.marimba(midi_hz(n), s.beat * 0.5, 0.32 if k % 2 == 0 else 0.22))
        # Brushes: soft kick on 1 and the and-of-2, snare on 2 and 4, hats on eighths.
        s.add(s.time(bar, 0), s.kick(0.5))
        s.add(s.time(bar, 2.5), s.kick(0.35))
        s.add(s.time(bar, 1), s.snare(0.28, brush=True))
        s.add(s.time(bar, 3), s.snare(0.3, brush=True))
        for k in range(8):
            s.add(s.time(bar, k * 0.5), s.hat(0.08 if k % 2 == 0 else 0.05))
        if bar % 4 == 3:
            s.add(s.time(bar, 3.5), s.hat(0.1, open_=True))
    # A melody that answers every four bars.
    tune = [69, 72, 74, 72, 69, 67, 65, 67]
    for phrase in range(4):
        for i, n in enumerate(tune):
            if phrase % 2 == 1 and i >= 6:
                continue
            t = s.time(phrase * 4 + 2 + i // 4, (i % 4) * 1.0)
            s.add(t, s.pluck(midi_hz(n + (12 if phrase == 3 else 0)), s.beat * 0.9, 0.3))
    return s.render(room=0.24, cutoff=7000)


def kettle_on():
    """A warm pluck waltz in G for the office: 3/4, 96 bpm, 24 bars."""
    s = Score(96, 24, 3)
    prog = [(67, "maj"), (64, "min"), (60, "maj"), (62, "maj")] * 6  # G Em C D
    rng = np.random.default_rng(5)
    for bar, (root, kind) in enumerate(prog):
        notes = chord(root, kind)
        s.add(s.time(bar, 0), s.bass(midi_hz(root - 24), s.beat * 2.0), 0.9)
        for b in (1, 2):
            for n in notes[1:]:
                s.add(s.time(bar, b + 0.02 * rng.random()), s.pluck(midi_hz(n), s.beat * 0.8, 0.22))
        s.add(s.time(bar, 0), s.pluck(midi_hz(notes[0]), s.beat * 0.9, 0.3))
        s.add(s.time(bar, 0), s.shaker(0.12))
        s.add(s.time(bar, 1), s.shaker(0.07))
        s.add(s.time(bar, 2), s.shaker(0.07))
        if bar >= 8:
            s.add(s.time(bar, 0), s.pad([midi_hz(n + 12) for n in notes], s.beat * 3), 0.35)
    tune = [71, 74, 78, 74, 71, 69, 67, 69, 71, 74, 76, 74, 71, 67, 64, 67]
    for i, n in enumerate(tune):
        bar = 8 + (i * 3) // 3 if i < 8 else 16 + ((i - 8) * 3) // 3
        bar = 8 + i if i < 8 else 16 + (i - 8)
        s.add(s.time(bar, 0), s.bell(midi_hz(n), s.beat * 2, 0.22))
        if i % 2 == 0:
            s.add(s.time(bar, 2), s.bell(midi_hz(n - 5), s.beat, 0.12))
    return s.render(room=0.3, room_time=s.beat * 2 / 3, cutoff=6500)


def open_road():
    """The drive: a steady motorik beat in A minor, 112 bpm, 16 bars, with a lead that climbs."""
    s = Score(112, 16)
    prog = [(57, "min7"), (57, "min7"), (65, "maj7"), (67, "maj")] * 4  # Am Am F G
    rng = np.random.default_rng(9)
    for bar, (root, kind) in enumerate(prog):
        notes = chord(root, kind)
        for k in range(8):
            s.add(s.time(bar, k * 0.5), s.bass(midi_hz(root - 24 + (0 if k < 6 else 7)), s.beat * 0.45, 0.4 if k % 2 == 0 else 0.3))
        s.add(s.time(bar, 0), s.pad([midi_hz(n) for n in notes], s.beat * 4), 0.5)
        for b in range(4):
            s.add(s.time(bar, b), s.kick(0.85))
        s.add(s.time(bar, 1), s.snare(0.4))
        s.add(s.time(bar, 3), s.snare(0.42))
        for k in range(8):
            s.add(s.time(bar, k * 0.5 + 0.25), s.hat(0.12))
        for k in range(4):
            s.add(s.time(bar, k + 0.5), s.hat(0.07, open_=bar % 4 == 3 and k == 3))
        # Stabs on the off beats from bar 4.
        if bar >= 4:
            for k in (1.5, 3.5):
                s.add(s.time(bar, k), s.pluck(midi_hz(notes[1] + 12), s.beat * 0.3, 0.18, bright=0.8))
    lead = [69, 72, 76, 74, 72, 69, 67, 69, 72, 76, 79, 76, 74, 72, 69, 72]
    for i, n in enumerate(lead):
        bar = 8 + i // 2
        s.add(s.time(bar, (i % 2) * 2), s.pluck(midi_hz(n), s.beat * 1.6, 0.34, bright=1.1))
        if rng.random() < 0.5:
            s.add(s.time(bar, (i % 2) * 2 + 1.5), s.pluck(midi_hz(n - 3), s.beat * 0.4, 0.16))
    return s.render(room=0.18, room_time=s.beat * 0.5, cutoff=9000)


def rain_on_the_cab():
    """The wet drive: slower, in D minor, electric-piano-ish pads and a brushed beat. 92 bpm, 16 bars."""
    s = Score(92, 16)
    prog = [(62, "min9"), (58, "maj7"), (60, "maj"), (57, "min7")] * 4  # Dm Bb C Am
    for bar, (root, kind) in enumerate(prog):
        notes = chord(root, kind)
        s.add(s.time(bar, 0), s.pad([midi_hz(n) for n in notes], s.beat * 4), 0.75)
        s.add(s.time(bar, 0), s.bass(midi_hz(root - 24), s.beat * 2.8), 0.9)
        s.add(s.time(bar, 3), s.bass(midi_hz(root - 24 + 5), s.beat * 0.8), 0.6)
        s.add(s.time(bar, 0), s.kick(0.6))
        s.add(s.time(bar, 2.5), s.kick(0.45))
        s.add(s.time(bar, 1), s.snare(0.25, brush=True))
        s.add(s.time(bar, 3), s.snare(0.27, brush=True))
        for k in range(8):
            s.add(s.time(bar, k * 0.5), s.hat(0.05))
        for k in (0, 2):
            s.add(s.time(bar, k + 0.5), s.marimba(midi_hz(notes[2] + 12), s.beat * 0.4, 0.14))
    tune = [74, 77, 81, 79, 77, 74, 72, 74, 77, 81, 84, 81, 79, 77, 74, 77]
    for i, n in enumerate(tune):
        bar = 4 + i // 2 + (4 if i >= 8 else 0)
        s.add(s.time(bar, (i % 2) * 2 + 0.5), s.bell(midi_hz(n), s.beat * 1.5, 0.2))
    return s.render(room=0.34, cutoff=5200)


def evening_shift():
    """The night move: a slow 6/8 in E minor, bass and a hushed bell. 70 bpm, 16 bars."""
    s = Score(70, 16, 6)
    prog = [(64, "min"), (60, "maj7"), (62, "maj"), (59, "min7")] * 4  # Em C D Bm
    rng = np.random.default_rng(13)
    for bar, (root, kind) in enumerate(prog):
        notes = chord(root, kind)
        s.add(s.time(bar, 0), s.pad([midi_hz(n - 12) for n in notes], s.beat * 6), 0.6)
        s.add(s.time(bar, 0), s.bass(midi_hz(root - 24), s.beat * 3), 0.8)
        s.add(s.time(bar, 3), s.bass(midi_hz(root - 24), s.beat * 3), 0.5)
        for k in range(6):
            if k in (0, 3):
                s.add(s.time(bar, k), s.kick(0.4))
            s.add(s.time(bar, k), s.shaker(0.07 if k % 3 else 0.1))
        if rng.random() < 0.7:
            s.add(s.time(bar, 2), s.pluck(midi_hz(notes[1] + 12), s.beat * 1.2, 0.16))
            s.add(s.time(bar, 5), s.pluck(midi_hz(notes[2] + 12), s.beat * 1.2, 0.14))
    tune = [76, 79, 83, 79, 76, 74, 71, 74]
    for i, n in enumerate(tune):
        s.add(s.time(8 + i, 0), s.bell(midi_hz(n), s.beat * 3, 0.18))
    return s.render(room=0.4, room_time=s.beat * 2, cutoff=4800)


def two_more_boxes():
    """A brighter loader for the truck and the pack: C major, 104 bpm, 16 bars, ukulele-ish plucks."""
    s = Score(104, 16)
    prog = [(60, "add9"), (69, "min7"), (65, "maj7"), (67, "maj")] * 4  # C Am F G
    rng = np.random.default_rng(21)
    for bar, (root, kind) in enumerate(prog):
        notes = chord(root, kind)
        for k in range(8):
            strum = notes if k % 2 == 0 else notes[1:]
            for j, n in enumerate(strum):
                s.add(s.time(bar, k * 0.5 + j * 0.012), s.pluck(midi_hz(n + 12), s.beat * 0.4, 0.13 if k % 2 else 0.17))
        s.add(s.time(bar, 0), s.bass(midi_hz(root - 24), s.beat * 0.9))
        s.add(s.time(bar, 1.5), s.bass(midi_hz(root - 24), s.beat * 0.5), 0.6)
        s.add(s.time(bar, 2), s.bass(midi_hz(root - 24 + 7), s.beat * 0.9), 0.8)
        s.add(s.time(bar, 3.5), s.bass(midi_hz(root - 24 + 5), s.beat * 0.5), 0.6)
        s.add(s.time(bar, 0), s.kick(0.7))
        s.add(s.time(bar, 2), s.kick(0.6))
        s.add(s.time(bar, 1), s.snare(0.3))
        s.add(s.time(bar, 3), s.snare(0.32))
        for k in range(8):
            s.add(s.time(bar, k * 0.5 + 0.25), s.shaker(0.09))
        if bar % 2 == 1:
            s.add(s.time(bar, 3.75), s.hat(0.08, open_=True))
    tune = [72, 76, 79, 76, 74, 72, 69, 72, 76, 79, 81, 79, 76, 74, 72, 74]
    for i, n in enumerate(tune):
        bar = 4 + i // 2 + (4 if i >= 8 else 0)
        s.add(s.time(bar, (i % 2) * 2), s.marimba(midi_hz(n), s.beat * 1.4, 0.3))
        if rng.random() < 0.6:
            s.add(s.time(bar, (i % 2) * 2 + 1), s.marimba(midi_hz(n - 4), s.beat * 0.6, 0.16))
    return s.render(room=0.2, cutoff=8000)


TRACKS = {
    "music_box_by_box": box_by_box,
    "music_kettle_on": kettle_on,
    "music_open_road": open_road,
    "music_rain_on_the_cab": rain_on_the_cab,
    "music_evening_shift": evening_shift,
    "music_two_more_boxes": two_more_boxes,
}


def main(argv):
    wanted = argv[1:] or list(TRACKS.keys())
    for name in wanted:
        key = name if name in TRACKS else "music_" + name
        if key not in TRACKS:
            print("no such track", name)
            continue
        write(key, TRACKS[key]())


if __name__ == "__main__":
    main(sys.argv)
