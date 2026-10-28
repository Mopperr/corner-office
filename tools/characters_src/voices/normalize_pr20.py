"""PR #20 QA loudness pass (Created by Andrew's Helpers (Grok Bots)).
Targets (BS.1770-4 via ffmpeg ebur128, 0.6 s silence pad each side so gating/windows see the whole clip):
  ambience + shop murmur beds : -27.0 LUFS integrated, linear gain only (loops: no limiter -> seams untouched)
  SFX one-shots >= 0.4 s      : -21.0 LUFS integrated
  SFX one-shots <  0.4 s      : -22.0 LUFS momentary-max (400 ms window; integrated is meaningless/gated for clicks)
  customer VO                 : -21 base, softer characters/variants down to -22, Rocco -20.5 (all inside -20..-22)
  true peak <= -1.0 dBTP everywhere; where gain alone would exceed it, a transparent look-ahead peak limiter
  (1.5 ms look-ahead, 60 ms release) is used, capped at 10 dB GR (>=0.4 s) / 6 dB GR (clicks); shortfalls reported.
Music and positional WAV emitter loops (sfx_*_loop) are left at their mix levels (not in the brief)."""
import sys, os, json, subprocess, numpy as np
from multiprocessing import Pool
from scipy.io import wavfile
sys.path.insert(0, os.path.dirname(__file__)); sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'qa_pr20_work'))
from audio_qa import decode, measure, SR
from classify import kind
GAME = os.environ.get("NORM_GAME", "/workspace/game"); TMP = os.path.join(GAME, "tmp_norm"); os.makedirs(TMP, exist_ok=True)
def vo_target(b):
    n, v = b.split('_')[2], b.split('_')[3]
    off = {'wren': -1, 'theo': -.5, 'rocco': .5}.get(n, 0) + {'unhappy': -1, 'okay': -.5}.get(v, 0)
    return max(-22.0, min(-20.5, -21 + off))
def target(rel, dur):
    k = kind('/' + rel); b = os.path.basename(rel).rsplit('.', 1)[0]
    if k == 'amb_loop': return 'I', -27.0, 0.0
    if k == 'vo': return 'I', vo_target(b), 6.0
    if k == 'oneshot': return ('I', -21.0, 10.0) if dur >= .4 else ('M', -22.0, 6.0)
    return None
def limiter(x, ceil_lin):
    la = int(.0015*SR); rel = np.exp(-1/(.06*SR)); m = np.abs(x).max(0)
    r = np.minimum(1, ceil_lin/np.maximum(m, 1e-9))
    from scipy.ndimage import minimum_filter1d, uniform_filter1d
    g = minimum_filter1d(r, 2*la+1, mode='nearest'); g = uniform_filter1d(g, la+1, mode='nearest'); g = np.minimum(g, r)
    out = np.empty_like(g); s = 1.0
    for i in range(len(g)):   # instant attack (already look-ahead smoothed), exponential release
        s = g[i] if g[i] < s else g[i] + (s - g[i])*rel; out[i] = s
    return x*out, -20*np.log10(out.min())
def write(path, y):
    if path.endswith('.wav'):
        wavfile.write(path, SR, np.round(np.clip(y[0], -1, 32767/32768)*32767).astype(np.int16))
    else:
        t = path + '.tmp.wav'; wavfile.write(t, SR, np.round(np.clip(y.T, -1, 1)*32767).astype(np.int16))
        subprocess.run(['ffmpeg','-y','-loglevel','error','-i',t,'-c:a','libvorbis','-q:a','6',path], check=True); os.remove(t)
def job(rel):
    src = os.path.join(GAME, rel); before = measure(src); t = target(rel, before['dur'])
    if t is None: return dict(file=rel, action='skip', before=before)
    key, tgt, grcap = t; x = decode(src); tmp = os.path.join(TMP, os.path.basename(rel))
    cur = before['I'] if key == 'I' else before['Mmax']; g_db = tgt - cur; ceil = -1.4; gr = 0.0; m = before
    for it in range(6):
        y = x*10**(g_db/20)
        need = 20*np.log10(np.abs(y).max()) - ceil
        if grcap == 0 or need <= 0: gr = 0.0
        else:
            if need > grcap: g_db -= need - grcap; y = x*10**(g_db/20)
            y, gr = limiter(y, 10**(ceil/20))
        if grcap == 0 and 20*np.log10(np.abs(y).max()) > ceil:   # loops: gain-only, cap by peak
            g_db -= 20*np.log10(np.abs(y).max()) - ceil; y = x*10**(g_db/20)
        write(tmp, y); m = measure(tmp); got = m['I'] if key == 'I' else m['Mmax']
        if m['TP'] > -1.05: ceil -= (m['TP'] + 1.05) + .15; continue
        if abs(got - tgt) <= .25 or (gr >= grcap - .05 and got < tgt and grcap) : break
        g_db += tgt - got
    os.replace(tmp, src); after = measure(src)
    return dict(file=rel, action='norm', key=key, target=tgt, gain_db=round(g_db, 2), limiter_gr_db=round(gr, 2),
                before=before, after=after)
if __name__ == '__main__':
    files = [l.strip() for l in open(sys.argv[1]) if l.strip()]
    with Pool(8) as p: res = p.map(job, files, chunksize=2)
    with open(sys.argv[2], 'w') as f:
        for r in res: f.write(json.dumps(r) + '\n')
    print(len(res), sum(r['action'] == 'norm' for r in res))
