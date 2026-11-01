// Runs the plug-in's WebM / MP4 repair on files and writes <name>.fixed.<ext> next to them.
//   node qa/fixtest.js <file.webm|.mp4|.m4a> ...
const fs = require("fs");
global.window = {};
global.document = {};
global.apex = { jQuery: () => ({ on() {} }) };
require("../src/mediaPlus.js");

(async () => {
    for (const f of process.argv.slice(2)) {
        const ext = f.split(".").pop(), kind = f.includes("video") ? "video" : "audio",
            type = kind + "/" + (ext === "webm" ? "webm" : "mp4"),
            lib = window.mediaPlus,
            out = ext === "webm" ? await lib.fixWebm(new Blob([fs.readFileSync(f)], { type }), 4000) : await lib.fixMp4(new Blob([fs.readFileSync(f)], { type })),
            name = f.replace(/\.(\w+)$/, ".fixed.$1");
        fs.writeFileSync(name, Buffer.from(await out.arrayBuffer()));
        console.log(f, fs.statSync(f).size, "->", name, out.size);
    }
})();
