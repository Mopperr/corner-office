"""Corner Office - 8 regular customers, wordless babble voice sets (Created by Andrew's Helpers (Grok Bots)).
Output: ../sfx/vo_customers/sfx_vo_<name>_<variant>_NN.wav + voice_manifest.json/.md"""
import numpy as np, json, os, zlib
from scipy.io import wavfile
from voice_engine import Voice, render, active_level_db, SR
OUT = os.path.join(os.path.dirname(__file__), '..', 'sfx', 'vo_customers')
C = {
 'steve': dict(game_id='steve', desc='earnest, polite to a fault; clean mid voice, tidy even rhythm, small range',
     v=Voice(f0=138, k=1.03, breath=.12, tilt=2500, oq=.58, tempo=5.2, range=.75, jit=.005),
     on=['b','d','m','n','l','h','w'], vo=['eh','uh','a','o','e'], laugh='heh', okay='mmhm', lvl=0.0),
 'lorna': dict(game_id='lamp_lady', desc='sunny optimist; warm sing-song, wide melodic glides, bright laugh',
     v=Voice(f0=203, k=1.12, breath=.16, tilt=2900, oq=.62, tempo=5.0, range=1.5, vib_st=.12, port_ms=40),
     on=['l','m','w','y','h','b'], vo=['a','o','ae','e','oo'], laugh='ha', okay='mmhm', lvl=0.0),
 'kit': dict(game_id='keyclackr', desc='fast talker, bright and clicky, little stumbles (repeats a syllable)',
     v=Voice(f0=162, k=1.08, breath=.10, tilt=3300, oq=.55, tempo=8.0, range=1.0, port_ms=15),
     on=['t','k','d','b','n','s','y'], vo=['i','eh','a','uh','e'], laugh='hih', okay='uhhuh', lvl=0.0, stumble=True),
 'dottie': dict(game_id='dottie', desc='grandmotherly crossing guard; tremulous, breathy, slower, warm chuckle, a little creak',
     v=Voice(f0=196, k=1.10, breath=.30, tilt=2100, oq=.68, tempo=4.0, range=1.2, vib_hz=5.6, vib_st=.38,
             jit=.012, shim=.09, creak=.55, port_ms=35),
     on=['m','n','h','w','y','b','l'], vo=['o','a','e','oo','eh'], laugh='ho', okay='mmhm', lvl=-.5),
 'theo': dict(game_id='theo', desc='night-shift nurse; low, soft, breathy, small range, grateful sighs, dry',
     v=Voice(f0=126, k=.99, breath=.32, tilt=1750, oq=.7, tempo=4.2, range=.6, creak=.35, port_ms=30),
     on=['h','m','n','w','y','l'], vo=['uh','a','o','e'], laugh='heh', okay='mmhm', lvl=-1.5, sigh=True),
 'pippa': dict(game_id='pippa', desc='9-year-old lemonade critic; high, bouncy, big range, "ooh!" and giggles',
     v=Voice(f0=288, k=1.32, breath=.13, tilt=3400, oq=.6, tempo=6.5, range=1.9, port_ms=20, bwx=1.15),
     on=['b','p','d','w','y','m'], vo=['i','e','a','oo','o'], laugh='hih', okay='mmhm', lvl=-.5, ooh=True),
 'rocco': dict(game_id='rocco', desc='chatty mail carrier; low chesty voice, quick, never grumpy, big hearty laugh',
     v=Voice(f0=104, k=.90, breath=.08, tilt=2700, oq=.5, tempo=7.2, range=1.4, port_ms=18),
     on=['b','d','g','h','m','y','w'], vo=['a','o','eh','uh','ae'], laugh='ha', okay='uhhuh', lvl=+.5),
 'wren': dict(game_id='wren', desc='quiet poet; very breathy and soft, slow, tiny range, thoughtful "hm"',
     v=Voice(f0=182, k=1.09, breath=.40, tilt=1900, oq=.72, tempo=3.6, range=.5, port_ms=45),
     on=['h','m','n','l','w','f'], vo=['o','oo','e','uh','eh'], laugh='heh', okay='hm', lvl=-2.0),
}
TAKES_V1 = [('greet',1),('happy',1),('happy',2),('okay',1),('unhappy',1),('goodbye',1)]
# pass 4 (QA PR#20 follow-up): +2 takes per variant -> 3 greet, 4 happy, 3 okay, 3 unhappy, 3 goodbye per regular
TAKES_V2 = [('greet',2),('greet',3),('happy',3),('happy',4),('okay',2),('okay',3),
            ('unhappy',2),('unhappy',3),('goodbye',2),('goodbye',3)]
TAKES = TAKES_V1 + TAKES_V2
LAUGHV = {'ha':'a','heh':'eh','hih':'i','ho':'o'}

def syl(c, rng, onset=None, vowel=None, d=1.0, st=0, amp=1.0, to=None, bend=0):
    sd = 1.0/c['v'].tempo
    on = onset if onset is not None else rng.choice(c['on']); vw = vowel or rng.choice(c['vo'])
    out = []
    if on:
        cd = {'b':.07,'d':.06,'g':.07,'p':.08,'t':.07,'k':.08,'h':.07,'s':.09,'sh':.09,'f':.08}.get(on, .06)
        out.append(dict(ph=on, dur=cd*min(1.2, 5.5/c['v'].tempo)**.5, amp=amp, st=st, next=vw))
    out.append(dict(ph=vw, dur=max(.06, sd*d - (out[0]['dur'] if out else 0)), amp=amp, st=st, to=to, bend=bend))
    return out

def laugh(c, rng, n=3, st=3, amp=.8):
    vw = LAUGHV[c['laugh']]; out = []; sd = .9/c['v'].tempo
    for i in range(n):
        out += [dict(ph='h', dur=.05+.02*rng.random(), amp=amp, next=vw),
                dict(ph=vw, dur=max(.07, sd*.55), amp=amp*(1-.12*i), st=st - 1.2*i, bend=-.8)]
    return out

def take_voice(name, variant, take):
    """v1 takes use the base voice unchanged (bit-identical re-render); v2 takes get a small per-take
    performance variation (pitch +-0.6 st, tempo x0.94-1.06, breath x0.9-1.1) so repeats don't sound cloned."""
    v = C[name]['v']
    if (variant, take) in TAKES_V1: return v
    r = np.random.default_rng(zlib.crc32(f'perf{name}{variant}{take}'.encode()))
    d = dict(v.__dict__); d['f0'] = v.f0*2**(r.uniform(-.6, .6)/12); d['tempo'] = v.tempo*r.uniform(.94, 1.06)
    d['breath'] = min(.5, v.breath*r.uniform(.9, 1.1)); d['jit'] = v.jit*r.uniform(.9, 1.15)
    return Voice(**d)

def phrase_v2(name, variant, take):
    c = C[name]; rng = np.random.default_rng(zlib.crc32(f'v2{name}{variant}{take}'.encode()))
    S = []; A = take % 2 == 0   # A/B shapes per variant (greet 2/3, happy 4/3, okay 2/3, unhappy 2/3, goodbye 2/3)
    if variant == 'greet':
        if A:   # two-syllable "hel-lo!" - small up then bright peak, falling tail
            S += syl(c, rng, onset='h', vowel=rng.choice(['eh','e']), d=.9, st=1)
            S += syl(c, rng, onset='l', vowel=rng.choice(['o','oo']), d=1.4, st=4, bend=-1.8)
            contour = lambda t: 1 + 2.2*np.sin(np.pi*min(1, t*1.2)) - 1.2*t
        else:   # drawn-out "hiii!" + a quick friendly tag syllable
            S += syl(c, rng, onset=rng.choice(['h','y']), vowel='a', d=1.7, st=3, to='i', bend=1.0)
            S += syl(c, rng, d=.8, st=1.5, amp=.8)
            if c.get('stumble'): S = S[:2] + S[:2] + S[2:]
            S[-1]['bend'] = -1.2
            contour = lambda t: 2.5 - 2.5*t**1.5
        room = .1
    elif variant == 'happy':
        if A:   # "yay!" upward leap, then laugh/giggle
            if c.get('ooh'): S += [dict(ph='w', dur=.05, st=5, amp=1, next='i'), dict(ph='i', dur=.3, st=7, amp=1, bend=3)]
            elif c.get('sigh'): S += [dict(ph='h', dur=.12, amp=.8, next='a'), dict(ph='a', dur=.26, st=3, amp=.85, to='o', bend=-2),
                                      dict(ph='y', dur=.05, st=3, amp=.9, next='eh'), dict(ph='eh', dur=.2, st=4, amp=.9, bend=1)]
            else: S += syl(c, rng, onset='y', vowel='a', d=1.5, st=4, to='i', bend=2.5)
            S += laugh(c, rng, n=2 if name in ('theo', 'wren') else 3, st=4.5, amp=.75)
            contour = lambda t: 2 + 2.5*t - 1.2*t*t
        else:   # "mm!" appreciative hum, then "oh!" and a quick bouncy run
            S += [dict(ph='m', dur=.22, st=2, amp=1.0, bend=2.5), dict(ph='sil', dur=.05)]
            S += syl(c, rng, onset='', vowel='o', d=1.1, st=5, bend=-1.5)
            for k in range(rng.integers(2, 4)): S += syl(c, rng, d=rng.uniform(.7, 1.0), st=3 + (1.5 if k % 2 else 0))
            if c.get('stumble'): S = S[:3] + S[1:3] + S[3:]
            if name in ('rocco', 'lorna', 'dottie', 'pippa'): S += laugh(c, rng, n=2, st=3.5, amp=.65)
            contour = lambda t: 2.5 + 1.2*np.sin(5*np.pi*t)
        room = .1
    elif variant == 'okay':
        if A:   # short "yeah" with a little level nod
            S += [dict(ph='y', dur=.06, st=1, amp=.9, next='eh'), dict(ph='eh', dur=.24, st=1, amp=.95, to='a', bend=-.8)]
            contour = lambda t: .6 - .6*t
        else:   # "o-kay" two-note, lightly rising
            S += [dict(ph='o', dur=.15, st=0, amp=.9), dict(ph='k', dur=.06, amp=.8, next='eh'),
                  dict(ph='eh', dur=.26, st=1.8, amp=.95, to='i', bend=.6 if c['okay'] != 'hm' else 1.5)]
            if c['okay'] == 'hm': S = [dict(ph='h', dur=.07, amp=.5, next='uh'), dict(ph='m', dur=.3, st=0, amp=1.0, bend=1.2)] + S[1:]
            contour = lambda t: .2 + .6*t
        room = .08
    elif variant == 'unhappy':   # soft, unhurried but not slow; always ends on a gentle upward lift (accepting, never sulky)
        if A:   # "oh... hm?" - small dip then a kind lift
            S += [dict(ph='o', dur=.26, st=1.2, amp=.72, bend=-1.6), dict(ph='sil', dur=.07),
                  dict(ph='h', dur=.08, amp=.4, next='uh'), dict(ph='m', dur=.26, st=-.6, amp=.7, bend=2.6)]
            contour = lambda t: -.4 - 1.2*t + 4.0*max(0, t-.7)
        else:   # "aw, mm-hm" - rueful but accepting, rising finish
            S += [dict(ph='w', dur=.05, st=1.5, amp=.7, next='a'), dict(ph='a', dur=.28, st=1.5, amp=.72, to='o', bend=-1.8),
                  dict(ph='sil', dur=.06), dict(ph='m', dur=.16, st=-.8, amp=.7),
                  dict(ph='h', dur=.05, amp=.4, next='uh'), dict(ph='m', dur=.2, st=.6, amp=.7, bend=1.4)]
            contour = lambda t: -.6 - .8*t + 3.0*max(0, t-.65)
        room = .12
    elif variant == 'goodbye':
        if A:   # "see-ya!" bright then falling
            S += syl(c, rng, onset='s', vowel='i', d=1.1, st=3.5)
            S += syl(c, rng, onset='y', vowel='a', d=1.4, st=0.5, bend=-1.2)
            contour = lambda t: 1.2 - 1.6*t
        else:   # rising-then-settling "bye-bye" with a warm hum tail for quiet characters
            S += syl(c, rng, onset='b', vowel='a', d=.9, st=1, to='i')
            S += syl(c, rng, onset='b', vowel='a', d=1.4, st=3.5, to='i', bend=-1.5)
            if name in ('theo', 'wren', 'dottie'): S += [dict(ph='m', dur=.22, st=1, amp=.6, bend=-.5)]
            contour = lambda t: .5 + 1.5*np.sin(np.pi*t) - .5*t
        room = .12 + .03*(take == 3)
    for sg in S:
        if sg['ph'] == 'sil': sg['next'] = 'uh'
    return S, contour, rng, room

def phrase(name, variant, take):
    if (variant, take) not in TAKES_V1: return phrase_v2(name, variant, take)
    c = C[name]; rng = np.random.default_rng(zlib.crc32(f'{name}{variant}{take}'.encode()))
    S = []
    if variant == 'greet':   # rise-fall "hey-ya!" / "hi-ii"
        S += syl(c, rng, onset=rng.choice(['h','y','w']), vowel=rng.choice(['e','ae','a']), d=1.3, st=2, to='i' if rng.random()<.5 else None)
        for k in range(rng.integers(1, 3)): S += syl(c, rng, d=1.0, st=4-2*k)
        if c.get('stumble'): S = S[:2] + S[:2] + S[2:]   # Kit's "mild typo" double-start
        S[-1]['bend'] = -1.5
        contour = lambda t: 3*np.sin(np.pi*min(1, t*1.4))*(1-.3*t) - 1.0*t
        room = .1
    elif variant == 'happy':
        if c.get('ooh') and take == 1: S += [dict(ph='oo', dur=.34, st=6, amp=1, bend=4)]
        if c.get('sigh') and take == 1:   # Theo: warm grateful sigh then "mm"
            S += [dict(ph='h', dur=.14, amp=.9, next='a'), dict(ph='a', dur=.30, st=2, amp=.8, to='uh', bend=-3),
                  dict(ph='m', dur=.28, st=1, amp=.9, bend=1.5)]
        else:
            n = rng.integers(3, 5)
            for k in range(n): S += syl(c, rng, d=rng.uniform(.8, 1.2), st=3 + (2 if k % 2 == 0 else 0) + k*.6)
            if c.get('stumble') and take == 2: S = S[:2] + S[:2] + S[2:]
        if take == 2 or name in ('rocco', 'lorna'): S += laugh(c, rng, n=4 if name == 'rocco' else 3, st=4)
        if name == 'dottie' and take == 1: S += laugh(c, rng, n=3, st=2, amp=.7)
        contour = lambda t: 2 + 2*t + .8*np.sin(6*np.pi*t)
        room = .1
    elif variant == 'okay':
        o = c['okay']
        if o == 'mmhm': S += [dict(ph='m', dur=.2, st=0, amp=1.1), dict(ph='h', dur=.06, amp=.5, next='uh'),
                              dict(ph='m', dur=.24, st=2, amp=1.1, bend=.5)]
        elif o == 'uhhuh': S += [dict(ph='uh', dur=.15, st=0), dict(ph='h', dur=.06, amp=.6, next='uh'),
                                 dict(ph='uh', dur=.2, st=2.5, bend=-.6)]
        else: S += [dict(ph='h', dur=.08, amp=.6, next='uh'), dict(ph='m', dur=.38, st=0, amp=1.1, bend=-1.2)]
        contour = lambda t: .5 - .8*t
        room = .08
    elif variant == 'unhappy':  # gentle "aww... mm" - lower, slower, falling, then small hopeful lift
        sl = 1.25
        S += [dict(ph='w', dur=.05*sl, st=2, amp=.8, next='a'), dict(ph='a', dur=.34*sl, st=2, amp=.85, to='o', bend=-3),
              dict(ph='oo', dur=.12*sl, st=-1.2, amp=.7, bend=-.6)]
        S += [dict(ph='sil', dur=.08), dict(ph='h', dur=.1, amp=.45, next='uh'),
              dict(ph='m', dur=.26*sl, st=-1.5, amp=.75, bend=1.3)]
        contour = lambda t: -1.0 - 1.5*t
        room = .12
    elif variant == 'goodbye':  # descending two-note sing-song "ba-bye" / "bye-bye", warm
        on1 = rng.choice(['b','w','y']); S += syl(c, rng, onset=on1, vowel='a', d=1.0, st=4, to='i')
        S += syl(c, rng, onset='b' if on1 != 'w' else 'w', vowel='a', d=1.6, st=0, to='i', bend=-1)
        if name in ('lorna', 'pippa', 'rocco'): S += syl(c, rng, onset='', vowel='i', d=.7, st=2.5, amp=.6)
        contour = lambda t: 1 - 1.5*t
        room = .12
    for sg in S:
        if sg['ph'] == 'sil': sg['next'] = 'uh'
    return S, contour, rng, room

def main():
    os.makedirs(OUT, exist_ok=True); man = []
    for name, c in C.items():
        for variant, take in TAKES:
            v = take_voice(name, variant, take)
            S, contour, rng, room = phrase(name, variant, take)
            y = render(v, S, contour, rng, room=room)
            lvl = active_level_db(y); tgt = -24.0 + c['lvl'] + {'unhappy': -1.5, 'okay': -1.0}.get(variant, 0)
            y = y*10**((tgt-lvl)/20)
            pk = 20*np.log10(np.abs(y).max())
            if pk > -10.5:  # gentle soft-clip toward ceiling, then hard-set peak to -10.5 dBFS
                ceil = 10**(-9.0/20); y = ceil*np.tanh(y/ceil); y *= 10**(-10.5/20)/np.abs(y).max()
            fn = f'sfx_vo_{name}_{variant}_{take:02d}.wav'
            wavfile.write(os.path.join(OUT, fn), SR, np.round(np.clip(y, -1, 1)*32767).astype(np.int16))
            man.append(dict(file=f'sfx/vo_customers/{fn}', character=name, customer_id=c['game_id'], variant=variant,
                            take=take, duration_s=round(len(y)/SR, 3), peak_dbfs=round(20*np.log10(np.abs(y).max()), 2),
                            active_level_dbk=round(active_level_db(y), 1), f0_hz=v.f0, formant_scale=v.k,
                            tempo_syl_s=v.tempo, breath=v.breath, pitch_range=v.range))
    json.dump(dict(set='customer_voices_v2', format='WAV 44.1 kHz 16-bit mono', license="Created by Andrew's Helpers (Grok Bots)",
                   generator='assets/audio/src/gen_customer_voices.py + voice_engine.py',
                   characters={n: dict(customer_id=c['game_id'], voice=c['desc'], f0_hz=c['v'].f0, formant_scale=c['v'].k,
                                       tempo_syl_s=c['v'].tempo, breath=c['v'].breath, pitch_range=c['v'].range,
                                       tremor_st=c['v'].vib_st, creak=c['v'].creak) for n, c in C.items()},
                   variants=dict(greet='rise-fall hello (customer arrives); t1 "hey-ya", t2 "hel-lo!", t3 drawn "hiii!" + tag',
                                 happy='bright, higher, laughs (great order); t1/t2 babble+laugh, t3 "yay!"+giggle, t4 "mm! oh!" run',
                                 okay='acknowledgement (fine order); t1 "mm-hm"/"uh-huh"/"hm", t2 "yeah", t3 "o-kay"',
                                 unhappy='gentle soft, never sulky - ends on a hopeful lift; t1 "aww... mm", t2 "oh... hm?", t3 "aw, mm-hm"',
                                 goodbye='t1 descending "bye-bye", t2 "see-ya!", t3 rising-settling "bye-bye" (+hum for Theo/Wren/Dottie)'),
                   files=man), open(os.path.join(OUT, 'voice_manifest.json'), 'w'), indent=1)
    print(len(man))
main()
