// Checks a repaired WebM: Duration value, SeekHead and Cue positions point at the right elements.
//   node qa/verify-webm.js <file> ...
const fs = require("fs");
function vint(b, p, id) {
    let len = 1, mask = 0x80; while (!(b[p] & mask)) { len++; mask >>= 1; }
    let v = id ? b[p] : b[p] & (mask - 1); for (let i = 1; i < len; i++) v = v * 256 + b[p + i];
    return { v, len };
}
function kids(b, start, end) {
    const out = [];
    for (let p = start; p < end;) { const id = vint(b, p, true), s = vint(b, p + id.len), d = p + id.len + s.len; out.push({ id: id.v, p, d, size: s.v }); p = d + s.v; }
    return out;
}
const uint = (b, p, n) => { let v = 0; for (let i = 0; i < n; i++) v = v * 256 + b[p + i]; return v; };
for (const f of process.argv.slice(2)) {
    const b = fs.readFileSync(f), top = kids(b, 0, b.length), seg = top.find(e => e.id === 0x18538067), base = seg.d;
    const lvl1 = kids(b, seg.d, seg.d + seg.size), at = pos => (lvl1.find(e => e.p === base + pos) || {}).id;
    const info = lvl1.find(e => e.id === 0x1549A966), dur = kids(b, info.d, info.d + info.size).find(e => e.id === 0x4489);
    const errors = [];
    if (seg.d + seg.size !== b.length) errors.push("segment size " + seg.size + " does not reach the end");
    for (const seek of kids(b, lvl1[0].d, lvl1[0].d + lvl1[0].size)) {
        const k = kids(b, seek.d, seek.d + seek.size), id = uint(b, k[0].d, k[0].size), pos = uint(b, k[1].d, k[1].size);
        if (at(pos) !== id) errors.push("seek 0x" + id.toString(16) + " -> " + pos + " is 0x" + (at(pos) || 0).toString(16));
    }
    const cues = lvl1.find(e => e.id === 0x1C53BB6B), times = [];
    for (const cp of kids(b, cues.d, cues.d + cues.size)) {
        const k = kids(b, cp.d, cp.d + cp.size), t = uint(b, k[0].d, k[0].size), tp = kids(b, k[1].d, k[1].d + k[1].size), pos = uint(b, tp[1].d, tp[1].size);
        times.push(t);
        if (at(pos) !== 0x1F43B675) errors.push("cue " + t + " -> " + pos + " is not a cluster");
    }
    console.log(f.split(/[\\/]/).pop(), "duration ms:", new DataView(b.buffer, b.byteOffset + dur.d, 8).getFloat64(0).toFixed(1),
        "clusters:", lvl1.filter(e => e.id === 0x1F43B675).length, "cue times:", times.join(","), errors.length ? "ERRORS: " + errors.join("; ") : "OK");
}
