const fs = require("fs"), b = fs.readFileSync(process.argv[2]);
const u32 = p => b.readUInt32BE(p), typ = p => b.toString("latin1", p + 4, p + 8);
function walk(s, e, d) {
  for (let p = s; p + 8 <= e;) {
    let size = u32(p); const t = typ(p); if (size === 1) size = Number(b.readBigUInt64BE(p + 8)); if (size === 0) size = e - p;
    let x = "";
    const D = p + 8;
    if (t === "ftyp") x = " " + b.toString("latin1", D, D + 4) + " compat:" + b.toString("latin1", D + 8, p + size);
    if (t === "tkhd") { const v = b[D], fl = b.readUIntBE(D + 1, 3); x = ` v${v} flags=${fl} id=${u32(D + (v ? 20 : 12))} dur=${v ? b.readBigUInt64BE(D + 28) : u32(D + 20)} volume=${b.readUInt16BE(D + (v ? 76 : 64)) / 256}`; }
    if (t === "mvhd" || t === "mdhd") { const v = b[D]; x = ` v${v} ts=${u32(D + (v ? 20 : 12))} dur=${v ? b.readBigUInt64BE(D + 24) : u32(D + 16)}`; }
    if (t === "hdlr") x = " " + b.toString("latin1", D + 8, D + 12);
    if (["stts", "stsz", "stsc", "stco", "stss", "ctts"].includes(t)) { const n = t === "stsz" ? u32(D + 8) : u32(D + 4); x = " entries=" + n + (t === "stsz" ? " fixed=" + u32(D + 4) + " first=" + u32(D + 12) : "") + (t === "stco" ? " first=" + u32(D + 8) + " last=" + u32(D + 4 + n * 4) : "") + (t === "stts" ? " [" + u32(D + 8) + "x" + u32(D + 12) + "]" : "") + (t === "stsc" ? " [" + u32(D + 8) + "," + u32(D + 12) + "," + u32(D + 16) + "]" : ""); }
    if (t === "stsd") x = " entries=" + u32(D + 4) + " fmt=" + b.toString("latin1", D + 12, D + 16) + " (" + u32(D + 8) + " bytes)";
    console.log("  ".repeat(d) + t + " " + size + x);
    if (["moov", "trak", "mdia", "minf", "stbl", "edts", "dinf", "udta"].includes(t)) walk(p + 8, p + size, d + 1);
    p += size;
  }
}
walk(0, b.length, 0);
