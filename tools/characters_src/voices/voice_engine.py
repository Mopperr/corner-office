"""Klatt-style cascade/parallel formant synthesizer for wordless babble (Corner Office).
Improvements over gen_vo_wordless.py: 5-formant cascade with exact time-varying state handoff,
pitch-synchronous aspiration, voiced/voiceless stops with bursts + formant transitions, fricatives,
nasal pole/zero branch, coarticulation smoothing, micro-prosody, jitter/shimmer/tremor/creak."""
import numpy as np, scipy.signal as ss
SR = 44100; BLK = 32
# F1..F5 (adult reference); vowels and consonant loci
PH = {
 'a':(730,1090,2440,3400,4200),'ae':(660,1720,2410,3400,4200),'e':(480,1950,2550,3400,4200),
 'eh':(560,1800,2480,3400,4200),'i':(300,2250,3000,3500,4300),'o':(500,880,2500,3350,4200),
 'oo':(340,900,2300,3300,4100),'uh':(620,1190,2390,3350,4200),'ax':(500,1400,2450,3400,4200),
 'm':(280,1100,2200,3300,4200),'n':(280,1600,2600,3300,4200),'l':(360,1100,2600,3300,4200),
 'w':(300,700,2200,3300,4100),'y':(280,2200,2900,3400,4200),
 'b':(220,900,2100,3300,4200),'d':(220,1700,2600,3300,4200),'g':(220,1900,2200,3300,4200),
 'p':(220,900,2100,3300,4200),'t':(220,1700,2600,3300,4200),'k':(220,1900,2200,3300,4200),
}
BURST = {'b':700,'p':700,'d':3600,'t':4200,'g':1900,'k':2100}
FRIC = {'s':(5600,1800,.55),'sh':(2900,1300,.6),'f':(5000,4000,.25)}
VOWELS = {'a','ae','e','eh','i','o','oo','uh','ax'}
def _res_ab(f, bw):
    r = np.exp(-np.pi*bw/SR); B = 2*r*np.cos(2*np.pi*f/SR); C = -r*r; return 1-B-C, B, C
def tv_res(x, f, bw):
    y = np.empty_like(x); y1 = y2 = 0.0
    for i in range(0, len(x), BLK):
        j = min(i+BLK, len(x)); A, B, C = _res_ab(f[i], bw[i])
        y[i:j], _ = ss.lfilter([A], [1, -B, -C], x[i:j], zi=[B*y1 + C*y2, C*y1])
        y1 = y[j-1]; y2 = y[j-2] if j-i > 1 else y1
    return y
def tv_antires(x, f, bw):
    y = np.empty_like(x); x1 = x2 = 0.0
    for i in range(0, len(x), BLK):
        j = min(i+BLK, len(x)); A, B, C = _res_ab(f[i], bw[i]); b = np.array([1, -B, -C])/A
        y[i:j], _ = ss.lfilter(b, [1], x[i:j], zi=[b[1]*x1 + b[2]*x2, b[2]*x1])
        x1 = x[j-1]; x2 = x[j-2] if j-i > 1 else x1
    return y
def smooth(x, ms):
    n = max(1, int(ms*SR/1000)); k = np.hanning(2*n+1); k /= k.sum()
    return np.convolve(np.pad(x, n, mode='edge'), k, 'valid')
def lpn(rng, n, fc):  # low-passed noise, unit-ish std
    b, a = ss.butter(1, fc/(SR/2)); z = ss.lfilter(b, a, rng.standard_normal(n)); return z/(z.std()+1e-9)

class Voice:
    def __init__(s, **kw):
        s.f0 = 150; s.k = 1.0; s.breath = .15; s.tilt = 2400; s.oq = .6; s.jit = .006; s.shim = .05
        s.vib_hz = 5.0; s.vib_st = 0.0; s.creak = 0.0; s.bwx = 1.0; s.port_ms = 25; s.tempo = 5.0
        s.range = 1.0; s.gain_db = 0.0
        s.__dict__.update(kw)

def render(v, segs, contour, rng, room=0.1):
    """segs: list of dicts {ph, dur, amp, st(accent semitones), to(optional glide target ph), av_scale}
       contour: fn(t_norm)->semitones (phrase intonation)."""
    n = int(sum(sg['dur'] for sg in segs)*SR) + int(.25*SR)
    F = np.zeros((5, n)); AV = np.zeros(n); AH = np.zeros(n); AF = np.zeros(n); FF = np.full(n, 4000.); FB = np.full(n, 1500.)
    NAS = np.zeros(n); NZ = np.full(n, 1200.); ST = np.zeros(n); bursts = []
    i = 0; last_v = 'ax'
    for sg in segs:
        L = int(sg['dur']*SR); ph = sg['ph']; amp = sg.get('amp', 1.0); sl = slice(i, i+L)
        tgt = ph if ph in PH else last_v
        if ph in ('h', 's', 'sh', 'f', 'sil'): tgt = sg.get('next', last_v)
        f_a = np.array(PH.get(tgt, PH['ax'])); f_b = np.array(PH.get(sg.get('to', tgt), f_a))
        ramp = np.linspace(0, 1, L)[None, :]
        F[:, sl] = (f_a[:, None]*(1-ramp) + f_b[:, None]*ramp)
        ST[sl] = sg.get('st', 0.0) + np.linspace(0, sg.get('bend', 0.0), L)
        if ph in VOWELS: AV[sl] = amp; last_v = sg.get('to', ph)
        elif ph in ('m', 'n'):
            AV[sl] = .45*amp; NAS[sl] = 1.0; NZ[sl] = 1100*v.k if ph == 'm' else 1700*v.k; ST[sl] -= .4
        elif ph in ('l', 'w', 'y'): AV[sl] = .6*amp; ST[sl] -= .3
        elif ph in ('b', 'd', 'g'):
            cl = int(.7*L); AV[i:i+cl] = .1*amp; AV[i+cl:i+L] = .7*amp; ST[sl] -= .8
            bursts.append((i+cl, BURST[ph], .25*amp, .006))
        elif ph in ('p', 't', 'k'):
            cl = int(.5*L); bursts.append((i+cl, BURST[ph], .45*amp, .008)); AH[i+cl:i+L] = .35*amp; ST[sl] += .8
        elif ph == 'h': AH[sl] = .45*amp*np.sin(np.pi*np.linspace(0, 1, L))**.5
        elif ph in FRIC:
            ff, fb, a = FRIC[ph]; AF[sl] = a*amp*np.sin(np.pi*np.linspace(0, 1, L)); FF[sl] = ff; FB[sl] = fb
        i += L
    # coarticulation smoothing
    for r in range(5): F[r] = smooth(F[r], 22)
    AV = smooth(AV, 9); AH = smooth(AH, 6); AF = smooth(AF, 6); NAS = smooth(NAS, 12); NZ = smooth(NZ, 12)
    tn = np.arange(n)/max(1, i)
    semis = smooth(ST*v.range + np.array([contour(min(t, 1.0)) for t in tn[::64]]).repeat(64)[:n]*v.range, v.port_ms)
    semis += v.vib_st*np.sin(2*np.pi*v.vib_hz*np.arange(n)/SR + rng.uniform(0, 6.28))
    f0 = v.f0*2**(semis/12)*(1 + v.jit*lpn(rng, n, 40))
    # creak at phrase end: drop f0 + irregular pulses
    if v.creak > 0:
        endw = np.clip((tn - .78)/.22, 0, 1)*v.creak; f0 *= (1 - .45*endw); f0 *= 1 + endw*.08*rng.standard_normal(n)
    f0 = np.clip(f0, 50, 700)
    ph_ = np.cumsum(f0/SR) % 1.0; oq = v.oq
    g = np.where(ph_ < oq*.7, .5-.5*np.cos(np.pi*ph_/(oq*.7)), np.where(ph_ < oq, np.cos(.5*np.pi*(ph_-oq*.7)/(oq*.3)), 0))
    src = np.diff(g, prepend=0)*SR/(f0*8)
    b, a = ss.butter(1, v.tilt/(SR/2)); src = ss.lfilter(b, a, src)
    src *= AV*(1 + v.shim*lpn(rng, n, 25))
    openmod = .35 + .65*(ph_ < oq)
    noise = ss.lfilter(*ss.butter(2, 300/(SR/2), 'high'), rng.standard_normal(n))
    asp = noise*(v.breath*AV*openmod + AH)*.6
    x = src + asp
    bw = np.array([60, 90, 130, 190, 260])*v.bwx
    casc = x
    for r in range(5):
        casc = tv_res(casc, F[r]*v.k*(0.93 if r == 0 else 1.0), np.full(n, bw[r]*(1.6 if r == 0 else 1)))
    nas = tv_antires(casc, NZ, np.full(n, 220.))
    nas = tv_res(nas, np.full(n, 260.), np.full(n, 90.))*.6
    nas = ss.lfilter(*ss.butter(2, 1800/(SR/2)), nas)
    y = casc*(1-NAS) + nas*NAS*1.4
    fr = tv_res(rng.standard_normal(n)*AF, FF*min(1.15, max(.9, v.k)), FB)
    y += fr*.9
    for (at, fc, a_, d) in bursts:
        L = int(d*SR); bn = rng.standard_normal(L)*np.exp(-np.arange(L)/(L/4))
        bn = ss.lfilter(*ss.butter(2, [max(200, fc*.6)/(SR/2), min(fc*1.5, 9000)/(SR/2)], 'band'), bn)
        e = min(n, at+L); y[at:e] += bn[:e-at]*a_*.5
    y = ss.lfilter(*ss.butter(2, 70/(SR/2), 'high'), y)
    if room > 0:
        Lr = int(.3*SR); ir = rng.standard_normal(Lr)*np.exp(-np.arange(Lr)/SR/.055)
        ir = ss.lfilter(*ss.butter(2, 3500/(SR/2)), ir); ir[:int(.008*SR)] = 0
        wet = ss.fftconvolve(y, ir)[:n]; y = y + room*wet*np.std(y)/(np.std(wet)+1e-9)
    # trim trailing silence (keep 60 ms tail), fades
    env_ = np.abs(y); thr = env_.max()*10**(-50/20); last = np.nonzero(env_ > thr)[0][-1]
    y = y[:min(n, last+int(.06*SR))]
    f = int(.004*SR); y[:f] *= np.linspace(0, 1, f); fo = int(.04*SR); y[-fo:] *= np.linspace(1, 0, fo)**2
    return y

# ---- K-weighting (BS.1770) for level matching ----
def _kweight(x):
    # RBJ high-shelf ~ +4 dB @1681 Hz and HPF 38 Hz, matched at 44.1k
    A = 10**(3.999843853973347/40); w0 = 2*np.pi*1681.974450955533/SR; al = np.sin(w0)/(2*0.7071752369554196)
    cw = np.cos(w0); sA = 2*np.sqrt(A)*al
    b = [A*((A+1)+(A-1)*cw+sA), -2*A*((A-1)+(A+1)*cw), A*((A+1)+(A-1)*cw-sA)]
    a = [(A+1)-(A-1)*cw+sA, 2*((A-1)-(A+1)*cw), (A+1)-(A-1)*cw-sA]
    x = ss.lfilter(b, a, x); b2, a2 = ss.butter(2, 38.13547087602444/(SR/2), 'high'); return ss.lfilter(b2, a2, x)
def active_level_db(x):
    k = _kweight(x); w = int(.1*SR); fr = [np.mean(k[i:i+w]**2) for i in range(0, max(1, len(k)-w), w//2)]
    fr = np.array(fr)+1e-12; top = fr.max(); act = fr[fr > top*10**(-2.0)]   # frames within 20 dB of loudest
    return -0.691 + 10*np.log10(act.mean())
