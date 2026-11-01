// Prints the container structure that matters to players: WebM Duration / Cues, MP4 boxes and durations.
//   node qa/inspect.js <file> ...
const fs = require("fs");

function vint(b, p, keepMarker) {
    const first = b[p]; let len = 1, mask = 0x80;
    while (len <= 8 && !(first & mask)) { len++; mask >>= 1; }
    let v = keepMarker ? first : first & (mask - 1);
    for (let i = 1; i < len; i++) v = v * 256 + b[p + i];
    const unknown = !keepMarker && v === Math.pow(2, 7 * len) - 1;
    return { v, len, unknown };
}
const NAMES = { 0x1A45DFA3: "EBML", 0x18538067: "Segment", 0x114D9B74: "SeekHead", 0x1549A966: "Info", 0x1654AE6B: "Tracks", 0x1F43B675: "Cluster",
                0x1C53BB6B: "Cues", 0xEC: "Void", 0x2AD7B1: "TimecodeScale", 0x4489: "Duration", 0x4D80: "MuxingApp", 0x5741: "WritingApp", 0x1254C367: "Tags" };
function webm(b) {
    const out = []; let clusters = 0;
    const walk = (p, end, depth) => {
        while (p < end) {
            const id = vint(b, p, true), size = vint(b, p + id.len), data = p + id.len + size.len;
            const name = NAMES[id.v] || "0x" + id.v.toString(16);
            if (id.v === 0x1F43B675) { clusters++; } else if (depth < 2 && !(depth === 1 && name.startsWith("0x"))) {
                let extra = "";
                if (id.v === 0x4489) extra = " = " + (size.v === 8 ? new DataView(b.buffer, b.byteOffset + data, 8).getFloat64(0) : new DataView(b.buffer, b.byteOffset + data, 4).getFloat32(0));
                out.push("  ".repeat(depth) + name + " size=" + (size.unknown ? "unknown" : size.v) + extra);
            }
            if ((id.v === 0x18538067 || id.v === 0x1549A966) && depth < 2) { walk(data, size.unknown ? end : data + size.v, depth + 1); }
            if (size.unknown) { if (id.v !== 0x18538067) { out.push("  ".repeat(depth) + "(unknown size, stop)"); } return; }
            p = data + size.v;
        }
    };
    walk(0, b.length, 0);
    out.push("clusters: " + clusters);
    return out.join("\n");
}
function mp4(b) {
    const out = [];
    const walk = (p, end, depth) => {
        while (p + 8 <= end) {
            let size = b.readUInt32BE(p); const type = b.toString("latin1", p + 4, p + 8); let hdr = 8;
            if (size === 1) { size = Number(b.readBigUInt64BE(p + 8)); hdr = 16; } else if (size === 0) { size = end - p; }
            let extra = "";
            if (type === "mvhd" || type === "mdhd") {
                const v = b[p + hdr]; const o = p + hdr + 4;
                const ts = v === 1 ? b.readUInt32BE(o + 16) : b.readUInt32BE(o + 8), dur = v === 1 ? Number(b.readBigUInt64BE(o + 20)) : b.readUInt32BE(o + 12);
                extra = ` timescale=${ts} duration=${dur} (${(dur / ts).toFixed(2)} s)`;
            }
            if (type === "mehd") { const v = b[p + hdr]; extra = " fragment_duration=" + (v === 1 ? Number(b.readBigUInt64BE(p + hdr + 4)) : b.readUInt32BE(p + hdr + 4)); }
            if (depth < 3 && type !== "moof" || out.filter(l => l.includes("moof")).length < 2) out.push("  ".repeat(depth) + type + " " + size + extra);
            if (["moov", "trak", "mdia", "mvex"].includes(type)) walk(p + hdr, p + size, depth + 1);
            p += size;
        }
    };
    walk(0, b.length, 0);
    const moofs = (b.toString("latin1").match(/moof/g) || []).length;
    out.push("moof boxes: " + moofs);
    return out.join("\n");
}
for (const f of process.argv.slice(2)) {
    const b = fs.readFileSync(f);
    console.log("== " + f + " (" + b.length + " bytes)");
    console.log(b.readUInt32BE(0) === 0x1A45DFA3 ? webm(b) : mp4(b));
}
