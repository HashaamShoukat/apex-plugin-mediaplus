/*!
 * MediaPlus for Oracle APEX - item plug-in v2.0.0
 * Record audio or video and take photos in the browser - review, crop and adjust them - and keep them in an
 * APEX collection until the page saves them.
 * (c) 2026 Hashaam Shoukat - MIT License
 */
/* global apex */
window.mediaPlus = (function ($) {
    "use strict";

    var VERSION = "2.0.0",
        PART_BYTES = 1572864,     // bytes per upload request (multiple of 3, so each part is clean base64)
        PIECE_CHARS = 32000,      // base64 characters per f01 element (multiple of 4)
        PARALLEL = 3,             // upload requests at a time
        MAX_TRANSCRIPT = 20000,
        DRAFT_DAYS = 7,           // unsaved recordings are kept in the browser this long
        PHOTO_SOURCE_MAX = 4096,  // photos are scaled to this longest side before editing (phone canvas limits)
        LANGS = ["en-US", "ar-SA"],   // transcription languages offered
        instances = {};

    // Quality presets: audio kbps, video kbps, video height, frames per second
    var PRESETS = {
        SMALL:    { audioKbps: 24,  videoKbps: 350,  videoHeight: 360, fps: 15 },
        BALANCED: { audioKbps: 48,  videoKbps: 900,  videoHeight: 480, fps: 24 },
        HIGH:     { audioKbps: 128, videoKbps: 2500, videoHeight: 720, fps: 30 }
    };

    // English texts; each one can be translated with an application text message MEDIAPLUS.<KEY>
    var TEXT = {
        AUDIO: "Audio",
        VIDEO: "Video",
        IMAGE: "Photo",
        KINDS: "What to add",
        RECORD: "Record",
        TAKE_PHOTO: "Take Photo",
        CAPTURE: "Capture",
        USE_PHOTO: "Use Photo",
        RETAKE: "Take Again",
        PHOTO_TITLE: "Crop, turn or adjust the photo, then use it.",
        ROTATE_LEFT: "Rotate Left",
        ROTATE_RIGHT: "Rotate Right",
        FLIP: "Flip",
        CROP: "Crop",
        CROP_FREE: "Free",
        CROP_ALL: "Whole Photo",
        ADJUST: "Adjust",
        BRIGHTNESS: "Brightness",
        CONTRAST: "Contrast",
        SATURATION: "Colour",
        GRAYSCALE: "Black and White",
        DRAW: "Draw",
        UNDO: "Undo",
        RESET: "Reset",
        SIZE: "Size",
        SIZE_FULL: "Full (%0 px)",
        SIZE_PX: "%0 px",
        PHOTO_META: "%0 × %1 px",
        PHOTO_SIZE: "about %0",
        PREPARING: "Preparing the photo...",
        PHOTO_FAILED: "This photo could not be opened. %0",
        PHOTO_TOO_LARGE: "Even made smaller, this photo is more than %0. Crop it or choose a smaller size.",
        VIEW: "View",
        HIDE: "Hide",
        OPEN_CAMERA: "Open Camera",
        START: "Start Recording",
        PAUSE: "Pause",
        RESUME: "Resume",
        STOP: "Stop",
        CANCEL: "Cancel",
        CLOSE_CAMERA: "Close Camera",
        SWITCH_CAMERA: "Switch Camera",
        CHOOSE_FILE: "Choose File",
        DEVICE_RECORDER: "Use Device Recorder",
        USE: "Use Recording",
        RETRY: "Try Again",
        AGAIN: "Record Again",
        DISCARD: "Discard",
        DOWNLOAD: "Download",
        PLAY: "Play",
        HIDE_PLAYER: "Hide Player",
        DELETE: "Delete",
        READY: "Ready",
        RECORDING: "Recording",
        PAUSED: "Paused",
        REVIEW: "Review",
        UPLOADING: "Saving",
        STARTING: "Starting",
        FINISHING: "Finishing",
        SAVED: "Saved",
        PENDING: "Attached",
        TRANSCRIBING_SERVER: "Transcribing",
        REVIEW_TITLE: "Listen to or watch your recording before you use it.",
        UPLOAD_PROGRESS: "Saving %0%",
        LIMIT_HINT: "Up to %0",
        LIMIT_HINT_TIME: "Up to %0 or %1",
        CAPACITY: "about %0 at this quality",
        METER: "about %0 left · %1 of %2",
        OF: "%0 of %1",
        WARN_SIZE: "Almost at the limit: %0 of %1 used. Recording stops automatically at %1.",
        WARN_TIME: "Almost at the limit: %0 of %1. Recording stops automatically at %1.",
        STOPPED_SIZE: "Recording stopped: the maximum size of %0 was reached.",
        STOPPED_TIME: "Recording stopped: the maximum length of %0 was reached.",
        DEVICE_ENDED: "The microphone or camera was stopped (for example by a call or the screen locking). What was recorded so far is kept.",
        MAX_COUNT: "The maximum of %0 has been reached. Delete one to add another.",
        MAX_COUNT_ONE: "One has already been added. Delete it to add another.",
        FILE_TOO_LARGE: "This file is %0, more than the maximum of %1.",
        TOO_LARGE_KEEP: "This recording came out at %0, more than the %1 allowed, so it cannot be used here. Download it so it is not lost, or record a shorter one.",
        FILE_WRONG_TYPE: "Choose a file of an allowed kind.",
        NO_PERMISSION: "Allow access to the microphone or camera in your browser settings, then try again.",
        NO_DEVICE: "No microphone or camera was found.",
        NOT_SUPPORTED: "The camera and microphone are not available here: they need a secure (https) page and a current browser.",
        BUSY: "Finish first: use or discard the recording or photo.",
        CONFIRM_DELETE: "Delete this?",
        CONFIRM_DISCARD: "Discard this?",
        UPLOAD_FAILED: "This could not be saved. %0 It is still here - try again, or download it.",
        NETWORK: "The connection was lost.",
        SESSION_ENDED: "Your session has ended, so this could not be saved. Download it now so it is not lost, then sign in again.",
        RECOVERED: "Something you had not used yet was recovered. Use it or discard it.",
        PLAY_FAILED: "The recording could not be played. %0",
        TRANSCRIPT: "Transcript",
        TRANSCRIPT_LANGUAGE: "Transcription language",
        TRANSCRIPT_PLACEHOLDER: "Nothing was recognised - type what was said, or leave it empty.",
        TRANSCRIBING: "Listening...",
        STT_UNSUPPORTED: "This browser cannot transcribe. You can type the text after recording.",
        STT_FAILED: "Live transcription stopped (%0). You can type or correct the text after recording.",
        KEYS: "P = pause / resume, S = stop",
        NO_SOUND: "No sound is reaching the recording. Check the microphone - if headphones or AirPods are connected, try again without them."
    };

    // ------------------------------------------------------------------ helpers
    function txt(key) {
        var full = "MEDIAPLUS." + key,
            t = apex.lang.getMessage(full),
            args = Array.prototype.slice.call(arguments, 1);
        if (!t || t === full) { t = TEXT[key] || key; }
        return t.replace(/%(\d)/g, function (m, n) { return args[n] !== undefined ? args[n] : m; });
    }

    function el(tag, cls, attrs, kids) {
        var e = document.createElement(tag);
        if (cls) { e.className = cls; }
        if (attrs) {
            Object.keys(attrs).forEach(function (k) {
                if (attrs[k] === null || attrs[k] === undefined || attrs[k] === false) { return; }
                if (k === "text") { e.textContent = attrs[k]; } else { e.setAttribute(k, attrs[k] === true ? "" : attrs[k]); }
            });
        }
        (kids || []).forEach(function (k) { if (k) { e.appendChild(k); } });
        return e;
    }

    function faIcon(name) { return el("span", "t-Icon fa " + name, { "aria-hidden": "true" }); }

    // icon-only Universal Theme button (list rows)
    function iconButton(cls, iconName, label) {
        return el("button", "t-Button t-Button--small t-Button--noUI t-Button--noLabel t-Button--icon " + cls,
                  { type: "button", title: label, "aria-label": label }, [faIcon(iconName)]);
    }

    // recorder control: a pill (or, with Button Style = Theme, a Universal Theme button) with a drawn
    // icon (rec, pause, stop, play) or a Font APEX icon (fa-...)
    var THEME_CLASS = { "mplus-btn--rec": "t-Button--danger", "mplus-btn--stop": "t-Button--danger", "mplus-btn--primary": "t-Button--hot",
                        "mplus-btn--ghost": "t-Button--noUI", "mplus-btn--icon": "t-Button--noLabel t-Button--icon" };
    function setCtl(b, iconName, label) {
        var i = b.querySelector(".mplus-i"), l = b.querySelector(".mplus-btn-label");
        i.className = "mplus-i " + (iconName.indexOf("fa-") === 0 ? "fa " + iconName : "mplus-i--" + iconName) + (b.mplusTheme ? " t-Icon t-Icon--left" : "");
        l.textContent = label;
        b.title = b.mplusKey ? label + " (" + b.mplusKey + ")" : label;
        if (b.mplusIconOnly) { b.setAttribute("aria-label", label); }
    }
    function ctl(cls, iconName, label, iconOnly, theme) {
        var mods = ((cls || "") + (iconOnly ? " mplus-btn--icon" : "")).split(" ").filter(Boolean),
            klass = "mplus-btn " + mods.join(" ");
        if (theme) {
            // Universal Theme button: the pill modifiers are swapped for theme ones, the mplus-b-* names stay
            klass = "mplus-btn--theme t-Button t-Button--small t-Button--iconLeft " +
                    mods.map(function (m) { return THEME_CLASS[m] || (m.indexOf("mplus-btn--") === 0 ? "" : m); }).join(" ");
        }
        var b = el("button", klass, { type: "button" },
                   [el("span", "mplus-i", { "aria-hidden": "true" }), el("span", "mplus-btn-label" + (theme ? " t-Button-label" : ""))]);
        b.mplusTheme = !!theme;
        b.mplusIconOnly = !!iconOnly;
        setCtl(b, iconName, label);
        return b;
    }

    function show(e, on) { if (e) { e.hidden = !on; } }

    function fmtBytes(b) {
        if (b < 1024) { return Math.round(b) + " B"; }
        if (b < 1048576) { return Math.round(b / 1024) + " KB"; }
        var mb = b / 1048576;
        return (mb < 10 ? mb.toFixed(1) : Math.round(mb)) + " MB";
    }

    function fmtTime(sec) {
        sec = Math.max(0, Math.round(sec || 0));
        var h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60), s = sec % 60;
        return (h ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(s).padStart(2, "0");
    }

    function fmtSpan(sec) {
        if (sec >= 3600) { return (sec / 3600).toFixed(1).replace(/\.0$/, "") + " h"; }
        if (sec >= 120) { return Math.round(sec / 60) + " min"; }
        return fmtTime(sec);
    }

    function token() {
        var a = new Uint8Array(16), s = "";
        window.crypto.getRandomValues(a);
        a.forEach(function (n) { s += n.toString(16).padStart(2, "0"); });
        return s;
    }

    function extFor(mime) {
        mime = (mime || "").split(";")[0];
        var map = { "image/jpeg": "jpg", "image/png": "png", "image/webp": "webp", "image/gif": "gif", "image/heic": "heic",
                    "audio/webm": "webm", "video/webm": "webm", "audio/mp4": "m4a", "video/mp4": "mp4", "audio/ogg": "ogg",
                    "audio/mpeg": "mp3", "audio/wav": "wav", "audio/x-wav": "wav", "video/quicktime": "mov", "audio/aac": "aac",
                    "video/x-matroska": "mkv", "audio/x-m4a": "m4a", "video/3gpp": "3gp", "audio/3gpp": "3gp" };
        return map[mime] || (mime.split("/")[1] || "bin").replace(/[^a-z0-9]/g, "");
    }

    // Which container to ask for. AUTO: MP4 - video MP4 (H.264 / AAC), audio M4A (AAC) - which opens everywhere
    // (iPhone, Mac, Windows Media Player, Android); Firefox, which cannot write MP4, records WebM.
    // WEBM: WebM / Opus, smallest, but saved files do not open on iPhones or in Windows Media Player.
    // No browser can record MP3. Every file is repaired after recording (fixMp4 / fixWebm), so it has a duration
    // and a seek index in every player.
    function pickMime(kind, format) {
        if (!window.MediaRecorder || !MediaRecorder.isTypeSupported) { return ""; }
        var lists = {
            audio: { WEBM: ["audio/webm;codecs=opus", "audio/webm"], MP4: ["audio/mp4;codecs=mp4a.40.2", "audio/mp4"], OGG: ["audio/ogg;codecs=opus"] },
            video: { WEBM: ["video/webm;codecs=vp8,opus", "video/webm;codecs=vp9,opus", "video/webm"],
                     MP4: ["video/mp4;codecs=avc1.42E01E,mp4a.40.2", "video/mp4;codecs=avc1,mp4a", "video/mp4"] }
        };
        var order = format === "WEBM" ? ["WEBM", "OGG", "MP4"] : ["MP4", "WEBM", "OGG"],
            found = "";
        order.some(function (f) {
            return (lists[kind][f] || []).some(function (m) {
                if (MediaRecorder.isTypeSupported(m)) { found = m; return true; }
                return false;
            });
        });
        return found;
    }

    // Seek to the end once when the player does not know the duration yet
    function fixDuration(media) {
        media.addEventListener("loadedmetadata", function () {
            if (media.duration === Infinity || isNaN(media.duration)) {
                var back = function () { media.removeEventListener("timeupdate", back); media.currentTime = 0; };
                media.addEventListener("timeupdate", back);
                media.currentTime = 1e101;
            }
        }, { once: true });
    }

    function readBase64(blob) {
        return new Promise(function (resolve, reject) {
            var r = new FileReader();
            r.onload = function () { resolve(String(r.result).split(",")[1] || ""); };
            r.onerror = function () { reject(r.error); };
            r.readAsDataURL(blob);
        });
    }

    function mediaDuration(blob) {
        return new Promise(function (resolve) {
            var kind = (blob.type || "").indexOf("video") === 0 ? "video" : "audio",
                m = document.createElement(kind), url = URL.createObjectURL(blob), done = false,
                finish = function (d) { if (!done) { done = true; URL.revokeObjectURL(url); resolve(isFinite(d) ? d : 0); } };
            m.preload = "metadata";
            m.onloadedmetadata = function () { finish(m.duration); };
            m.onerror = function () { finish(0); };
            setTimeout(function () { finish(0); }, 4000);
            m.src = url;
        });
    }

    // ------------------------------------------------------------------ drafts (IndexedDB)
    // A recording that is reviewed but not used yet, or that failed to upload, is kept in the browser,
    // so a reload, a crash or an expired session does not lose it.
    var drafts = (function () {
        var dbp = null;
        function db() {
            if (!dbp) {
                dbp = new Promise(function (resolve, reject) {
                    if (!window.indexedDB) { reject(new Error("no IndexedDB")); return; }
                    var req = indexedDB.open("mediaPlusDrafts", 1);
                    req.onupgradeneeded = function () { req.result.createObjectStore("drafts"); };
                    req.onsuccess = function () { resolve(req.result); };
                    req.onerror = function () { reject(req.error); };
                });
            }
            return dbp;
        }
        function run(mode, fn) {
            return db().then(function (d) {
                return new Promise(function (resolve, reject) {
                    var tx = d.transaction("drafts", mode), req = fn(tx.objectStore("drafts"));
                    tx.oncomplete = function () { resolve(req && req.result); };
                    tx.onerror = tx.onabort = function () { reject(tx.error); };
                });
            }).catch(function () { return null; });
        }
        return {
            get: function (key) { return run("readonly", function (s) { return s.get(key); }); },
            put: function (key, val) { return run("readwrite", function (s) { return s.put(val, key); }); },
            del: function (key) { return run("readwrite", function (s) { return s.delete(key); }); }
        };
    })();

    // ------------------------------------------------------------------ WebM repair
    // MediaRecorder writes "live" WebM: no Duration, clusters of unknown size and no Cues, so players such as VLC
    // cannot seek and some will not open the file. This rewrites it as a regular file: Duration in Info, sized
    // clusters, a SeekHead and a Cues index (on keyframe clusters). Anything unexpected returns the original.
    var EBML = {
        HEADER: 0x1A45DFA3, SEGMENT: 0x18538067, SEEKHEAD: 0x114D9B74, SEEK: 0x4DBB, SEEKID: 0x53AB, SEEKPOS: 0x53AC,
        INFO: 0x1549A966, SCALE: 0x2AD7B1, DURATION: 0x4489, TRACKS: 0x1654AE6B, TRACK: 0xAE, TRACKNO: 0xD7, TRACKTYPE: 0x83,
        CLUSTER: 0x1F43B675, TIMECODE: 0xE7, SIMPLEBLOCK: 0xA3, BLOCKGROUP: 0xA0, BLOCK: 0xA1, VOID: 0xEC,
        CUES: 0x1C53BB6B, CUEPOINT: 0xBB, CUETIME: 0xB3, CUEPOS: 0xB7, CUETRACK: 0xF7, CUECLUSTER: 0xF1
    };
    var LEVEL1 = [EBML.SEEKHEAD, EBML.INFO, EBML.TRACKS, EBML.CLUSTER, EBML.CUES, 0x1254C367, 0x1043A770, 0x1941A469];

    function readVint(b, p, isId) {
        var first = b[p], len = 1, mask = 0x80;
        while (len <= 8 && !(first & mask)) { len++; mask >>= 1; }
        if (len > 8) { throw new Error("bad vint"); }
        var v = isId ? first : first & (mask - 1), allOnes = (first & (mask - 1)) === mask - 1;
        for (var i = 1; i < len; i++) { v = v * 256 + b[p + i]; allOnes = allOnes && b[p + i] === 255; }
        return { v: v, len: len, unknown: !isId && allOnes };
    }
    function readUint(b, p, n) { var v = 0; for (var i = 0; i < n; i++) { v = v * 256 + b[p + i]; } return v; }
    function idBytes(id) { var a = []; while (id > 0) { a.unshift(id & 255); id = Math.floor(id / 256); } return new Uint8Array(a); }
    function size8(n) { var a = new Uint8Array(8); a[0] = 1; for (var i = 7; i >= 1; i--) { a[i] = n % 256; n = Math.floor(n / 256); } return a; }
    function uintBytes(n, len) { var a = new Uint8Array(len); for (var i = len - 1; i >= 0; i--) { a[i] = n % 256; n = Math.floor(n / 256); } return a; }
    function elem(id, parts) {   // parts: Uint8Array list -> { parts, size }
        var len = 0, out = [idBytes(id), size8(0)];
        parts.forEach(function (x) { len += x.length; out.push(x); });
        out[1] = size8(len);
        return { parts: out, size: out[0].length + 8 + len };
    }
    function uintElem(id, n, len) { return elem(id, [uintBytes(n, len || 8)]); }
    function flat(list) { var out = []; list.forEach(function (x) { Array.prototype.push.apply(out, x.parts); }); return out; }

    function fixWebm(blob, fallbackMs) {
        if (!/webm/i.test(blob.type || "")) { return Promise.resolve(blob); }
        return blob.arrayBuffer().then(function (buf) {
            var b = new Uint8Array(buf), p = 0, head, seg, segEnd, infoKids = [], scale = 1000000, tracks = null, others = [],
                clusters = [], track = 1, maxTime = 0;
            head = readVint(b, 0, true);
            if (head.v !== EBML.HEADER) { return blob; }
            var hs = readVint(b, head.len);
            p = head.len + hs.len + hs.v;
            var headerBytes = b.subarray(0, p);
            seg = readVint(b, p, true);
            if (seg.v !== EBML.SEGMENT) { return blob; }
            var ss = readVint(b, p + seg.len);
            p += seg.len + ss.len;
            segEnd = ss.unknown ? b.length : Math.min(b.length, p + ss.v);

            while (p < segEnd) {
                var id = readVint(b, p, true), sz = readVint(b, p + id.len), data = p + id.len + sz.len, end;
                if (id.v === EBML.CLUSTER) {
                    // the children are read for timestamps and keyframes; the cluster body is copied as one piece
                    var c = { time: 0 }, q = data, stop = sz.unknown ? segEnd : Math.min(segEnd, data + sz.v), cut = false;
                    while (q < stop) {
                        var cid = readVint(b, q, true);
                        if (LEVEL1.indexOf(cid.v) >= 0) { break; }
                        var cs = readVint(b, q + cid.len), cdata = q + cid.len + cs.len;
                        if (cs.unknown || cdata + cs.v > b.length) { cut = true; break; }   // cut-off tail: keep what is complete
                        if (cid.v === EBML.TIMECODE) { c.time = readUint(b, cdata, cs.v); }
                        var blk = cid.v === EBML.SIMPLEBLOCK ? cdata : cid.v === EBML.BLOCKGROUP && b[cdata] === EBML.BLOCK ? cdata + 1 + readVint(b, cdata + 1).len : -1;
                        if (blk >= 0) {
                            var tn = readVint(b, blk), rel = (b[blk + tn.len] << 8 | b[blk + tn.len + 1]);
                            if (rel > 32767) { rel -= 65536; }
                            maxTime = Math.max(maxTime, c.time + rel);
                            // does the cluster start with a keyframe of the cue track? (a BlockGroup counts as one)
                            if (c.key === undefined && tn.v === track) { c.key = cid.v !== EBML.SIMPLEBLOCK || (b[blk + tn.len + 2] & 0x80) !== 0; }
                        }
                        q = cdata + cs.v;
                    }
                    if (q > data) { c.body = b.subarray(data, q); clusters.push(c); }
                    if (cut || q === data) { break; }
                    p = q;
                    continue;
                }
                if (sz.unknown) { return blob; }
                end = data + sz.v;
                if (id.v === EBML.INFO) {
                    for (var r = data; r < end;) {
                        var iid = readVint(b, r, true), is = readVint(b, r + iid.len), idata = r + iid.len + is.len;
                        if (iid.v === EBML.SCALE) { scale = readUint(b, idata, is.v); }
                        if (iid.v !== EBML.DURATION) { infoKids.push(b.subarray(r, idata + is.v)); }
                        r = idata + is.v;
                    }
                } else if (id.v === EBML.TRACKS) {
                    tracks = b.subarray(p, end);
                    for (var t = data, firstNo = 0, videoNo = 0; t < end;) {
                        var tid = readVint(b, t, true), ts = readVint(b, t + tid.len), tdata = t + tid.len + ts.len;
                        if (tid.v === EBML.TRACK) {
                            var no = 0, type = 0;
                            for (var u = tdata; u < tdata + ts.v;) {
                                var eid = readVint(b, u, true), es = readVint(b, u + eid.len), edata = u + eid.len + es.len;
                                if (eid.v === EBML.TRACKNO) { no = readUint(b, edata, es.v); }
                                if (eid.v === EBML.TRACKTYPE) { type = readUint(b, edata, es.v); }
                                u = edata + es.v;
                            }
                            firstNo = firstNo || no;
                            if (type === 1 && !videoNo) { videoNo = no; }
                        }
                        t = tdata + ts.v;
                    }
                    track = videoNo || firstNo || 1;
                } else if (id.v !== EBML.SEEKHEAD && id.v !== EBML.VOID && id.v !== EBML.CUES) {
                    others.push(b.subarray(p, end));
                }
                p = end;
            }
            if (!tracks || !clusters.length) { return blob; }

            var durationMs = maxTime > 0 ? maxTime * scale / 1e6 : fallbackMs,
                dur = new DataView(new ArrayBuffer(8));
            dur.setFloat64(0, durationMs * 1e6 / scale);
            var info = elem(EBML.INFO, infoKids.concat([idBytes(EBML.DURATION), new Uint8Array([0x88]), new Uint8Array(dur.buffer)])),
                clusterEls = clusters.map(function (c) { return elem(EBML.CLUSTER, [c.body]); }),
                otherSize = others.reduce(function (s, x) { return s + x.length; }, 0),
                seekEntry = function (id, pos) { return elem(EBML.SEEK, flat([elem(EBML.SEEKID, [idBytes(id)]), uintElem(EBML.SEEKPOS, pos)])); },
                seekSize = elem(EBML.SEEKHEAD, flat([seekEntry(EBML.INFO, 0), seekEntry(EBML.TRACKS, 0), seekEntry(EBML.CUES, 0)])).size,
                infoPos = seekSize, tracksPos = infoPos + info.size, pos = tracksPos + tracks.length + otherSize, cuePoints = [];
            clusterEls.forEach(function (ce, i) {
                if (i === 0 || clusters[i].key) {
                    cuePoints.push(elem(EBML.CUEPOINT, flat([uintElem(EBML.CUETIME, clusters[i].time),
                        elem(EBML.CUEPOS, flat([uintElem(EBML.CUETRACK, track, 1), uintElem(EBML.CUECLUSTER, pos)]))])));
                }
                pos += ce.size;
            });
            var cues = elem(EBML.CUES, flat(cuePoints)),
                seekHead = elem(EBML.SEEKHEAD, flat([seekEntry(EBML.INFO, infoPos), seekEntry(EBML.TRACKS, tracksPos), seekEntry(EBML.CUES, pos)])),
                body = flat([seekHead, info]).concat([tracks], others, flat(clusterEls), cues.parts),
                bodySize = body.reduce(function (s, x) { return s + x.length; }, 0);
            return new Blob([headerBytes, idBytes(EBML.SEGMENT), size8(bodySize)].concat(body), { type: blob.type });
        }).catch(function (e) {
            if (window.console) { console.warn("MediaPlus: WebM left as recorded", e); }
            return blob;
        });
    }

    // ------------------------------------------------------------------ MP4 repair
    // Chrome and Edge write fragmented MP4: an empty moov, then moof + mdat fragments - one for the whole recording.
    // Windows Media Player seeks only from fragment to fragment, so it cannot seek at all, and Chrome's track
    // durations are wrong. This rewrites it as a regular MP4: moov first with the full sample tables (stts, ctts,
    // stss, stsz, stsc, stco) and correct durations, then one mdat. Anything unexpected returns the original.
    function u32(b, p) { return b[p] * 16777216 + (b[p + 1] << 16) + (b[p + 2] << 8) + b[p + 3]; }
    function boxes(b, start, end) {
        var out = [];
        for (var p = start; p + 8 <= end;) {
            var size = u32(b, p), data = p + 8;
            if (size === 1) { size = u32(b, p + 8) * 4294967296 + u32(b, p + 12); data = p + 16; } else if (size === 0) { size = end - p; }
            if (size < 8 || p + size > end) { throw new Error("bad box"); }
            out.push({ type: String.fromCharCode(b[p + 4], b[p + 5], b[p + 6], b[p + 7]), start: p, data: data, end: p + size });
            p += size;
        }
        return out;
    }
    function kids(b, box, type) { return boxes(b, box.data, box.end).filter(function (x) { return !type || x.type === type; }); }
    function mbox(type, parts) {
        var len = 8, out, p = 8;
        parts.forEach(function (x) { len += x.length; });
        out = new Uint8Array(len);
        out.set(uintBytes(len, 4), 0);
        for (var i = 0; i < 4; i++) { out[4 + i] = type.charCodeAt(i); }
        parts.forEach(function (x) { out.set(x, p); p += x.length; });
        return out;
    }
    function fbox(type, version, values) {   // full box of 32-bit values
        var a = new Uint8Array(4 + values.length * 4), dv = new DataView(a.buffer);
        a[0] = version;
        values.forEach(function (v, i) { dv.setUint32(4 + i * 4, v >>> 0); });
        return mbox(type, [a]);
    }
    function runs(list, out) {   // [count, value, count, value ...]
        list.forEach(function (v) {
            if (out.length && out[out.length - 1] === v) { out[out.length - 2]++; } else { out.push(1, v); }
        });
        return out;
    }

    function fixMp4(blob) {
        if (!/mp4|m4a|quicktime/i.test(blob.type || "")) { return Promise.resolve(blob); }
        return blob.arrayBuffer().then(function (buf) {
            var b = new Uint8Array(buf), dv = new DataView(buf), top = boxes(b, 0, b.length), moov, mvhd, tracks = {}, order = [], trex = {}, extra = [];
            moov = top.filter(function (x) { return x.type === "moov"; })[0];
            if (!moov || !top.some(function (x) { return x.type === "moof"; })) { return blob; }   // already a regular MP4
            kids(b, moov).forEach(function (k) {
                if (k.type === "mvhd") {
                    mvhd = k;
                } else if (k.type === "trak") {
                    var tkhd = kids(b, k, "tkhd")[0], mdia = kids(b, k, "mdia")[0], mdhd = kids(b, mdia, "mdhd")[0],
                        hdlr = kids(b, mdia, "hdlr")[0], minf = kids(b, mdia, "minf")[0], stbl = kids(b, minf, "stbl")[0],
                        id = u32(b, tkhd.data + (b[tkhd.data] === 1 ? 20 : 12));
                    tracks[id] = { trak: k, tkhd: tkhd, mdia: mdia, mdhd: mdhd, minf: minf, stsd: kids(b, stbl, "stsd")[0],
                        scale: u32(b, mdhd.data + (b[mdhd.data] === 1 ? 20 : 12)), video: hdlr && u32(b, hdlr.data + 8) === 0x76696465,
                        durs: [], sizes: [], ctos: [], sync: [], chunks: [] };
                    order.push(id);
                } else if (k.type === "mvex") {
                    kids(b, k, "trex").forEach(function (x) {
                        trex[u32(b, x.data + 4)] = { dur: u32(b, x.data + 12), size: u32(b, x.data + 16), flags: u32(b, x.data + 20) };
                    });
                } else {
                    extra.push(b.subarray(k.start, k.end));   // udta, meta ...
                }
            });
            if (!mvhd || !order.length) { return blob; }

            // samples of every fragment
            top.forEach(function (m) {
                if (m.type !== "moof") { return; }
                kids(b, m, "traf").forEach(function (tf) {
                    var tk = kids(b, tf), tfhd = tk.filter(function (x) { return x.type === "tfhd"; })[0],
                        fl = u32(b, tfhd.data) & 0xFFFFFF, q = tfhd.data + 8, id = u32(b, tfhd.data + 4), t = tracks[id], d = trex[id] || {},
                        base = m.start, dDur = d.dur || 0, dSize = d.size || 0, dFlags = d.flags || 0, pos;
                    if (fl & 1) { base = u32(b, q) * 4294967296 + u32(b, q + 4); q += 8; }
                    if (fl & 2) { q += 4; }
                    if (fl & 8) { dDur = u32(b, q); q += 4; }
                    if (fl & 0x10) { dSize = u32(b, q); q += 4; }
                    if (fl & 0x20) { dFlags = u32(b, q); }
                    if (!t) { return; }
                    pos = base;
                    tk.forEach(function (tr) {
                        if (tr.type !== "trun") { return; }
                        var v = b[tr.data], f = u32(b, tr.data) & 0xFFFFFF, n = u32(b, tr.data + 4), r = tr.data + 8, first = null, start;
                        if (f & 1) { pos = base + dv.getInt32(r); r += 4; }
                        if (f & 4) { first = u32(b, r); r += 4; }
                        start = pos;
                        for (var i = 0; i < n; i++) {
                            var sd = dDur, ss = dSize, sf = dFlags, c = 0;
                            if (f & 0x100) { sd = u32(b, r); r += 4; }
                            if (f & 0x200) { ss = u32(b, r); r += 4; }
                            if (f & 0x400) { sf = u32(b, r); r += 4; }
                            if (f & 0x800) { c = v ? dv.getInt32(r) : u32(b, r); r += 4; }
                            if (i === 0 && first !== null) { sf = first; }
                            t.durs.push(sd); t.sizes.push(ss); t.ctos.push(c); t.sync.push(!(sf & 0x10000));
                            pos += ss;
                        }
                        if (pos > b.length) { throw new Error("cut-off sample data"); }
                        if (n) { t.chunks.push({ from: start, size: pos - start, count: n }); }
                    });
                });
            });

            // the mdat keeps the original interleaving: chunks in file order
            var all = [], total = 0;
            order.forEach(function (id) { all = all.concat(tracks[id].chunks); });
            if (!all.length) { return blob; }
            all.sort(function (x, y) { return x.from - y.from; }).forEach(function (c) { c.at = total; total += c.size; });
            if (total > 4000000000) { return blob; }

            var mScale = u32(b, mvhd.data + (b[mvhd.data] === 1 ? 20 : 12)), mDur = 0;
            order.forEach(function (id) {
                var t = tracks[id];
                t.dur = t.durs.reduce(function (s, x) { return s + x; }, 0);
                t.mDur = Math.round(t.dur * mScale / t.scale);
                mDur = Math.max(mDur, t.mDur);
            });
            // copy of a box with its duration field replaced (mvhd / mdhd: after the timescale; tkhd: after the track id)
            var withDur = function (box, v0, v1, value) {
                var a = b.slice(box.start, box.end), d = new DataView(a.buffer), o = box.data - box.start;
                if (a[o] === 1) { d.setUint32(o + v1, Math.floor(value / 4294967296)); d.setUint32(o + v1 + 4, value >>> 0); } else { d.setUint32(o + v0, value >>> 0); }
                return a;
            };
            var copy = function (box) { return b.subarray(box.start, box.end); };
            // track header: enabled + in movie + in preview (Safari writes "enabled" only, which Apple's player of a
            // regular MP4 may not play), and full volume on sound tracks
            var trackHeader = function (box, t) {
                var a = withDur(box, 20, 28, t.mDur), o = box.data - box.start, d = new DataView(a.buffer);
                a[o + 3] = a[o + 3] | 7;
                if (!t.video) { d.setUint16(o + (a[o] === 1 ? 48 : 36), 0x0100); }
                return a;
            };
            var build = function (base) {
                var traks = order.map(function (id) {
                    var t = tracks[id], stts = runs(t.durs, []), ctts = runs(t.ctos, []), stsc = [], stco = [], stss = [], prev = -1,
                        tables = [copy(t.stsd), fbox("stts", 0, [stts.length / 2].concat(stts))];
                    if (t.ctos.some(function (x) { return x !== 0; })) {
                        tables.push(fbox("ctts", t.ctos.some(function (x) { return x < 0; }) ? 1 : 0, [ctts.length / 2].concat(ctts)));
                    }
                    t.sync.forEach(function (s, i) { if (s) { stss.push(i + 1); } });
                    if (t.video && stss.length < t.sync.length) { tables.push(fbox("stss", 0, [stss.length].concat(stss))); }
                    tables.push(fbox("stsz", 0, [0, t.sizes.length].concat(t.sizes)));
                    t.chunks.forEach(function (c, i) {
                        if (c.count !== prev) { stsc.push(i + 1, c.count, 1); prev = c.count; }
                        stco.push(base + c.at);
                    });
                    tables.push(fbox("stsc", 0, [stsc.length / 3].concat(stsc)), fbox("stco", 0, [stco.length].concat(stco)));
                    var minf = mbox("minf", kids(b, t.minf).filter(function (x) { return x.type !== "stbl"; }).map(copy).concat([mbox("stbl", tables)])),
                        mdia = mbox("mdia", kids(b, t.mdia).map(function (x) {
                            return x.type === "mdhd" ? withDur(x, 16, 24, t.dur) : x.type === "minf" ? minf : copy(x);
                        }));
                    // edts is left out: the edit lists of fragmented files describe the fragments
                    return mbox("trak", kids(b, t.trak).filter(function (x) { return x.type !== "edts"; }).map(function (x) {
                        return x.type === "tkhd" ? trackHeader(x, t) : x.type === "mdia" ? mdia : copy(x);
                    }));
                });
                return mbox("moov", [withDur(mvhd, 16, 24, mDur)].concat(traks, extra));
            };
            var ftyp = mbox("ftyp", ["isom", "\0\0\u0002\0", "isom", "iso2", "avc1", "mp41"].map(function (s) {
                    return new Uint8Array(s.split("").map(function (ch) { return ch.charCodeAt(0); }));
                })),
                size = build(0).length,
                moovBox = build(ftyp.length + size + 8),
                parts = [ftyp, moovBox, uintBytes(total + 8, 4), new Uint8Array([0x6D, 0x64, 0x61, 0x74])];
            all.forEach(function (c) { parts.push(b.subarray(c.from, c.from + c.size)); });
            return new Blob(parts, { type: blob.type });
        }).catch(function (e) {
            if (window.console) { console.warn("MediaPlus: MP4 left as recorded", e); }
            return blob;
        });
    }

    function fixMedia(blob, fallbackMs) {
        return /webm/i.test(blob.type || "") ? fixWebm(blob, fallbackMs) : fixMp4(blob);
    }

    // iOS (Safari 16.4+): while the microphone is open the page plays through the earpiece, as in a phone call,
    // and stays so after recording unless told otherwise - then a recording just made is not heard. The Audio
    // Session API switches between recording and normal playback; other browsers do not have it and need nothing.
    function audioSession(type) {
        try { if (navigator.audioSession && navigator.audioSession.type !== type) { navigator.audioSession.type = type; } } catch (e) { /* not supported */ }
    }

    function kindOf(mime) {
        var k = String(mime || "").split("/")[0].toUpperCase();
        return k === "VIDEO" || k === "IMAGE" ? k : "AUDIO";
    }

    // ------------------------------------------------------------------ photos
    // A photo is edited as a small set of settings (turn, flip, crop, adjustments, drawing) on its source picture;
    // the picture itself is only rendered for the preview and once more, at the output size, when it is used.
    var FILTER_OK = (function () {
        try { return typeof document.createElement("canvas").getContext("2d").filter === "string"; } catch (e) { return false; }
    })();

    function canvasOf(w, h) {
        var c = document.createElement("canvas");
        c.width = Math.max(1, Math.round(w));
        c.height = Math.max(1, Math.round(h));
        return c;
    }

    function encode(canvas, type, quality) {
        return new Promise(function (resolve, reject) {
            canvas.toBlob(function (b) { if (b) { resolve(b); } else { reject(new Error("encode")); } }, type, quality);
        });
    }

    // decodes a photo (the browser applies the EXIF orientation) into a canvas of at most PHOTO_SOURCE_MAX px
    function loadPhoto(blob) {
        return new Promise(function (resolve, reject) {
            var url = URL.createObjectURL(blob), img = new Image();
            img.onload = function () {
                URL.revokeObjectURL(url);
                var w = img.naturalWidth, h = img.naturalHeight, s = Math.min(1, PHOTO_SOURCE_MAX / Math.max(w, h));
                if (!w || !h) { reject(new Error("empty")); return; }
                var c = canvasOf(w * s, h * s), g = c.getContext("2d");
                g.imageSmoothingQuality = "high";
                g.drawImage(img, 0, 0, c.width, c.height);
                resolve(c);
            };
            img.onerror = function () { URL.revokeObjectURL(url); reject(new Error(blob.type || "")); };
            img.src = url;
        });
    }

    function filterOf(ed) {
        var f = [];
        if (ed.adj.b !== 100) { f.push("brightness(" + ed.adj.b + "%)"); }
        if (ed.adj.c !== 100) { f.push("contrast(" + ed.adj.c + "%)"); }
        if (ed.adj.s !== 100 && !ed.gray) { f.push("saturate(" + ed.adj.s + "%)"); }
        if (ed.gray) { f.push("grayscale(1)"); }
        return f.join(" ");
    }

    // the same adjustments by hand, for browsers without canvas filters (older Safari)
    function adjustPixels(g, w, h, ed) {
        var d = g.getImageData(0, 0, w, h), p = d.data, b = ed.adj.b / 100, k = ed.adj.c / 100, s = ed.gray ? 0 : ed.adj.s / 100;
        for (var i = 0; i < p.length; i += 4) {
            var r = (p[i] * b - 128) * k + 128, gr = (p[i + 1] * b - 128) * k + 128, bl = (p[i + 2] * b - 128) * k + 128,
                l = 0.2126 * r + 0.7152 * gr + 0.0722 * bl;
            p[i] = l + (r - l) * s;
            p[i + 1] = l + (gr - l) * s;
            p[i + 2] = l + (bl - l) * s;
        }
        g.putImageData(d, 0, 0);
    }

    // strokes are kept in source coordinates (0..1), so they turn and crop with the photo
    function drawStrokes(g, strokes, w, h) {
        strokes.forEach(function (st) {
            if (!st.pts.length) { return; }
            g.save();
            g.strokeStyle = st.colour;
            g.lineWidth = Math.max(1, st.w * Math.max(w, h));
            g.lineCap = g.lineJoin = "round";
            g.beginPath();
            g.moveTo(st.pts[0][0] * w, st.pts[0][1] * h);
            for (var i = 1; i < st.pts.length; i++) { g.lineTo(st.pts[i][0] * w, st.pts[i][1] * h); }
            if (st.pts.length === 1) { g.lineTo(st.pts[0][0] * w + 0.1, st.pts[0][1] * h); }
            g.stroke();
            g.restore();
        });
    }

    // the edited photo: adjustments and drawing on the source, then turned and flipped, then cropped (when asked),
    // scaled so that its longest side is at most maxSide
    function renderPhoto(ed, maxSide, cropped) {
        var sw = ed.src.width, sh = ed.src.height, turned = ed.rot % 180 !== 0,
            tw = turned ? sh : sw, th = turned ? sw : sh,
            c = cropped ? ed.crop : { x: 0, y: 0, w: 1, h: 1 },
            s = Math.min(1, maxSide / Math.max(c.w * tw, c.h * th)),
            layer = canvasOf(sw * s, sh * s), g = layer.getContext("2d"), f = filterOf(ed);
        g.imageSmoothingQuality = "high";
        if (f && FILTER_OK) { g.filter = f; }
        g.drawImage(ed.src, 0, 0, layer.width, layer.height);
        if (f && FILTER_OK) { g.filter = "none"; }
        if (f && !FILTER_OK) { adjustPixels(g, layer.width, layer.height, ed); }
        drawStrokes(g, ed.strokes, layer.width, layer.height);
        var out = canvasOf(c.w * tw * s, c.h * th * s), o = out.getContext("2d");
        o.imageSmoothingQuality = "high";
        o.translate(-c.x * tw * s + tw * s / 2, -c.y * th * s + th * s / 2);
        o.rotate(ed.rot * Math.PI / 180);
        o.scale(ed.flip ? -1 : 1, 1);
        o.drawImage(layer, -layer.width / 2, -layer.height / 2);
        return out;
    }

    // encodes the photo; while it is over maxBytes, first the quality goes down (to 0.5), then the size (by 20%)
    function encodeToFit(ed, maxSide, type, quality, maxBytes) {
        var side = maxSide, q = quality, tries = 0;
        var step = function () {
            var c = renderPhoto(ed, side, true);
            return encode(c, type, q).then(function (b) {
                // a browser that cannot write WebP returns PNG: use JPEG instead
                if (type === "image/webp" && b.type !== type) { type = "image/jpeg"; return step(); }
                if (b.size <= maxBytes || ++tries > 12) { return { blob: b, width: c.width, height: c.height, fits: b.size <= maxBytes }; }
                if (type !== "image/png" && q > 0.55) { q = Math.max(0.5, q - 0.1); } else { side = Math.round(Math.max(c.width, c.height) * 0.8); }
                return step();
            });
        };
        return step();
    }

    // ------------------------------------------------------------------ recorder
    function Recorder(cfg) {
        var self = this;
        this.cfg = cfg;
        this.input = document.getElementById(cfg.item);
        this.root = document.getElementById(cfg.item + "_MPLUS");
        this.features = (cfg.features || "").split(":");
        this.audioOpts = (cfg.audioOptions || "").split(":");
        // Mode: any of AUDIO, VIDEO, IMAGE (colon list); the first one is selected
        this.kinds = String(cfg.mode || "AUDIO").toLowerCase().split(":").filter(function (k) { return k === "audio" || k === "video" || k === "image"; });
        if (!this.kinds.length) { this.kinds = ["audio"]; }
        this.kind = this.kinds[0];
        this.tools = String(cfg.imageTools || "").split(":").filter(Boolean);
        this.facing = cfg.camera === "user" ? "user" : "environment";
        this.state = "idle";
        this.items = (cfg.items || []).map(function (r) { r.pending = true; return r; });
        this.saved = cfg.saved || [];
        this.initial = this.input.value;
        this.disabled = false;
        this.draftKey = "mplus:" + (cfg.appId || "") + ":" + (cfg.pageId || "") + ":" + cfg.item;
        this.supported = !!(window.MediaRecorder && navigator.mediaDevices && navigator.mediaDevices.getUserMedia && window.isSecureContext !== false);
        this.SR = window.SpeechRecognition || window.webkitSpeechRecognition;
        // English (US) and / or Arabic; without a choice the page language decides
        this.langs = String(cfg.transcriptLanguages || "").split(/[,;:\s]+/).filter(function (l) { return LANGS.indexOf(l) >= 0; });
        if (!this.langs.length) { this.langs = [/^ar/i.test(document.documentElement.lang || "") ? "ar-SA" : "en-US"]; }
        try { this.lang = localStorage.getItem("mplus-lang:" + cfg.item); } catch (e) { this.lang = null; }
        if (this.langs.indexOf(this.lang) < 0) { this.lang = this.langs[0]; }
        this.build();
        this.sync();
        if (this.has("switchCamera") && navigator.mediaDevices && navigator.mediaDevices.enumerateDevices) {
            navigator.mediaDevices.enumerateDevices().then(function (list) {
                self.cameras = list.filter(function (d) { return d.kind === "videoinput"; }).length;
                self.sync();
            }).catch(function () { /* no device list - keep the button hidden */ });
        }
        if (!cfg.readOnly) { this.recover(); }
    }

    Recorder.prototype.has = function (f) { return this.features.indexOf(f) >= 0; };

    Recorder.prototype.quality = function () {
        var q = this.cfg.quality === "CUSTOM" ? this.cfg : (PRESETS[this.cfg.quality] || PRESETS.BALANCED);
        return { audioKbps: +q.audioKbps || 48, videoKbps: +q.videoKbps || 900, videoHeight: +q.videoHeight || 480, fps: +q.fps || 24 };
    };

    // AAC (MP4 audio) sounds poor below 96 kbps, and Chrome records it at about 100 kbps whatever is asked;
    // Opus is fine at the preset rates
    Recorder.prototype.audioKbps = function (mime) {
        var q = this.quality().audioKbps;
        return /mp4/i.test(mime === undefined ? pickMime(this.kind, this.cfg.format) : mime) ? Math.max(96, q) : q;
    };

    Recorder.prototype.withSound = function () { return this.kind === "audio" || (this.kind === "video" && this.audioOpts.indexOf("videoSound") >= 0); };

    // video and photos use the camera
    Recorder.prototype.camera = function () { return this.kind !== "audio"; };

    // live transcription applies to audio recordings
    Recorder.prototype.transcribes = function () { return this.cfg.transcription === "LIVE" && this.kind === "audio"; };

    Recorder.prototype.build = function () {
        var self = this, c = this.cfg, r = this.root, th = c.buttons === "THEME";
        r.classList.add("mplus--" + (c.style === "COMPACT" ? "compact" : "full"));
        r.classList.toggle("mplus--theme-buttons", th);
        r.innerHTML = "";

        // top line: Audio / Video / Photo switch, transcription language, status
        this.seg = el("div", "mplus-seg", { role: "group", "aria-label": txt("KINDS") });
        this.segBtns = {};
        this.kinds.forEach(function (k) {
            var b = ctl("mplus-seg-btn mplus-seg-" + k, { audio: "fa-microphone", video: "fa-video-camera", image: "fa-camera" }[k], txt(k.toUpperCase()));
            b.addEventListener("click", function () { self.setKind(k); });
            self.segBtns[k] = b;
            self.seg.appendChild(b);
        });
        this.langSel = el("select", "mplus-lang", { "aria-label": txt("TRANSCRIPT_LANGUAGE"), title: txt("TRANSCRIPT_LANGUAGE") });
        this.langs.forEach(function (l) {
            var name = l;
            try { name = new Intl.DisplayNames([document.documentElement.lang || "en"], { type: "language" }).of(l) || l; } catch (e) { /* keep the code */ }
            self.langSel.appendChild(el("option", null, { value: l, text: name, selected: l === self.lang }));
        });
        this.status = el("span", "mplus-status", { "aria-live": "polite" });
        this.top = el("div", "mplus-top", null, [this.kinds.length > 1 && !c.readOnly ? this.seg : null, this.langSel, this.status]);

        // stage: live camera / waveform, timer, countdown
        this.video = el("video", "mplus-live", { playsinline: true, muted: true, autoplay: true });
        this.video.muted = true;
        this.canvas = el("canvas", "mplus-wave", { "aria-hidden": "true" });
        this.timer = el("span", "mplus-timer", { text: "0:00", role: "timer" });
        this.dot = el("span", "mplus-dot", { "aria-hidden": "true" });
        this.level = el("span", "mplus-level", { "aria-hidden": "true" }, [el("span")]);
        this.countdown = el("span", "mplus-countdown", { "aria-live": "assertive" });
        this.stage = el("div", "mplus-stage", null, [
            this.video, this.canvas,
            el("div", "mplus-overlay", null, [el("span", "mplus-rec", null, [this.dot, this.timer]), this.level]),
            this.countdown
        ]);
        this.video.addEventListener("resize", function () { self.fitStage(self.video.videoWidth, self.video.videoHeight); });

        // live transcript while recording
        this.sttFinalEl = el("span");
        this.sttInterimEl = el("span", "mplus-stt-interim");
        this.sttBox = el("div", "mplus-stt", { "aria-live": "polite" }, [this.sttFinalEl, this.sttInterimEl]);

        // time / size meter
        this.meterFill = el("span", "mplus-meter-fill");
        this.meterText = el("span", "mplus-meter-text");
        this.meterBar = el("span", "mplus-meter-track", { role: "progressbar", "aria-valuemin": 0, "aria-valuemax": 100 }, [this.meterFill]);
        this.meter = el("div", "mplus-meter", null, [this.meterBar, this.meterText]);

        this.notice = el("div", "mplus-notice", { role: "status" });

        // controls
        this.bRecord = ctl("mplus-btn--rec mplus-b-record", "rec", txt("RECORD"), false, th);
        this.bPause = ctl("mplus-b-pause", "pause", txt("PAUSE"), false, th);
        this.bPause.mplusKey = "P";
        this.bStop = ctl("mplus-btn--stop mplus-b-stop", "stop", txt("STOP"), false, th);
        this.bStop.mplusKey = "S";
        this.bSwitch = ctl("mplus-b-switch", "fa-refresh", txt("SWITCH_CAMERA"), true, th);
        this.bClose = ctl("mplus-btn--ghost mplus-b-close", "fa-times", txt("CLOSE_CAMERA"), false, th);
        this.bFile = ctl("mplus-btn--ghost mplus-b-file", "fa-upload", this.supported ? txt("CHOOSE_FILE") : txt("DEVICE_RECORDER"), false, th);
        this.file = el("input", "mplus-file", { type: "file", hidden: true, tabindex: "-1",
            accept: this.kinds.map(function (k) { return k + "/*"; }).join(","),
            // without camera access, the phone's own camera / recorder
            capture: this.supported ? null : (this.kinds[0] === "audio" ? "user" : "environment") });
        this.actions = el("div", "mplus-actions mplus-actions--main", null, [this.bRecord, this.bPause, this.bStop, this.bSwitch, this.bClose, this.bFile, this.file]);
        this.hint = el("div", "mplus-hint");

        // review after stop
        this.player = el("div", "mplus-review-player");
        this.bUse = ctl("mplus-btn--primary mplus-b-use", "fa-check", txt("USE"), false, th);
        this.bAgain = ctl("mplus-b-again", "fa-undo", txt("AGAIN"), false, th);
        this.bDiscard = ctl("mplus-btn--ghost mplus-b-discard", "fa-trash-o", txt("DISCARD"), false, th);
        this.aDownload = el("a", (th ? "mplus-btn--theme t-Button t-Button--small t-Button--noUI t-Button--iconLeft" : "mplus-btn mplus-btn--ghost") + " mplus-b-download", { href: "#" },
                            [el("span", "mplus-i fa fa-download" + (th ? " t-Icon t-Icon--left" : ""), { "aria-hidden": "true" }),
                             el("span", "mplus-btn-label" + (th ? " t-Button-label" : ""), { text: txt("DOWNLOAD") })]);
        this.reviewMeta = el("span", "mplus-review-meta");
        this.reviewText = el("textarea", "mplus-transcript text_field apex-item-textarea", { rows: 3, maxlength: MAX_TRANSCRIPT,
            placeholder: txt("TRANSCRIPT_PLACEHOLDER"), id: c.item + "_TRANSCRIPT" });
        this.reviewTextBox = el("div", "mplus-transcript-box", null, [
            el("label", "mplus-transcript-label", { for: c.item + "_TRANSCRIPT", text: txt("TRANSCRIPT") }), this.reviewText]);
        this.reviewTitle = el("div", "mplus-review-title", { text: txt("REVIEW_TITLE") });
        this.buildEditor(th);
        this.review = el("div", "mplus-review", null, [
            this.reviewTitle,
            this.player,
            this.photoBox,
            el("div", "mplus-review-bar", null, [this.reviewMeta]),
            this.reviewTextBox,
            el("div", "mplus-actions", null, [this.bUse, this.bAgain, this.bDiscard, this.aDownload])
        ]);

        this.list = el("ul", "mplus-list");

        [this.top, this.stage, this.sttBox, this.meter, this.notice, this.actions, this.review, this.hint, this.list].forEach(function (x) { r.appendChild(x); });

        // events
        this.langSel.addEventListener("change", function () {
            self.lang = self.langSel.value;
            try { localStorage.setItem("mplus-lang:" + c.item, self.lang); } catch (e) { /* not kept */ }
        });
        this.bRecord.addEventListener("click", function () { self.start(); });
        this.bPause.addEventListener("click", function () { self.togglePause(); });
        this.bStop.addEventListener("click", function () { self.stop(); });
        this.bSwitch.addEventListener("click", function () { self.switchCamera(); });
        this.bClose.addEventListener("click", function () { self.release(); self.setState("idle"); });
        this.bFile.addEventListener("click", function () { self.file.click(); });
        this.file.addEventListener("change", function () { if (self.file.files[0]) { self.useFile(self.file.files[0]); } self.file.value = ""; });
        this.bUse.addEventListener("click", function () { self.accept(); });
        this.bAgain.addEventListener("click", function () { self.discard(true); });
        this.bDiscard.addEventListener("click", function () { self.discard(false); });
        // a photo is downloaded as edited
        this.aDownload.addEventListener("click", function (e) {
            if (!self.ed || self.aDownload.mplusReady) { self.aDownload.mplusReady = false; return; }
            e.preventDefault();
            self.edExport().then(function (res) {
                if (self.dlUrl) { URL.revokeObjectURL(self.dlUrl); }
                self.dlUrl = URL.createObjectURL(res.blob);
                self.aDownload.href = self.dlUrl;
                self.aDownload.setAttribute("download", self.photoName(res.blob.type));
                self.aDownload.mplusReady = true;
                self.aDownload.click();
            });
        });
        // keyboard, while the focus is in the item: P pauses / resumes, S stops
        r.addEventListener("keydown", function (e) {
            if (e.ctrlKey || e.metaKey || e.altKey || /^(TEXTAREA|INPUT|SELECT)$/.test(e.target.tagName)) { return; }
            var k = (e.key || "").toLowerCase();
            if (k === "p" && (self.state === "recording" || self.state === "paused")) { e.preventDefault(); self.togglePause(); }
            if (k === "s" && (self.state === "recording" || self.state === "paused")) { e.preventDefault(); self.stop(); }
        });

        this.renderList();
    };

    // ---------------------------------------------------------------- state & display
    Recorder.prototype.setState = function (s) {
        this.state = s;
        this.root.setAttribute("data-state", s);
        this.sync();
    };

    Recorder.prototype.setKind = function (k) {
        if (this.state !== "idle" || this.kind === k || this.kinds.indexOf(k) < 0) { return; }
        this.kind = k;
        this.sync();
    };

    Recorder.prototype.full = function () { return this.items.length >= Math.max(1, this.cfg.maxCount || 1); };

    // the camera picture keeps its own shape: portrait on phones, landscape on laptops
    Recorder.prototype.fitStage = function (w, h) {
        if (!this.camera() || !w || !h) {
            this.stage.style.aspectRatio = "";
            this.stage.style.maxWidth = "";
            return;
        }
        this.stage.style.aspectRatio = w + " / " + h;
        this.stage.style.maxWidth = "calc(60vh * " + (w / h).toFixed(4) + ")";
    };

    Recorder.prototype.sync = function () {
        var s = this.state, c = this.cfg, ro = c.readOnly || this.disabled,
            live = s === "opening" || s === "ready" || s === "countdown" || s === "recording" || s === "paused" || s === "stopping",
            rolling = s === "opening" || s === "countdown" || s === "recording" || s === "paused" || s === "stopping",
            video = this.kind === "video", image = this.kind === "image", cam = this.camera(), self = this;

        // the camera kinds share the video stage
        this.root.classList.toggle("mplus--video", cam);
        this.root.classList.toggle("mplus--image", image);
        this.root.classList.toggle("mplus--audio", !cam);
        this.root.classList.toggle("mplus--disabled", this.disabled);
        this.root.classList.toggle("mplus--mirror", cam && this.facing === "user" && this.has("mirror"));
        Object.keys(this.segBtns).forEach(function (k) {
            self.segBtns[k].setAttribute("aria-pressed", String(k === self.kind));
            self.segBtns[k].disabled = s !== "idle" || self.disabled;
        });
        show(this.langSel, !ro && this.transcribes() && this.langs.length > 1 && !!this.SR);
        this.langSel.disabled = s !== "idle" && s !== "ready";

        var status = { opening: txt("STARTING"), ready: txt("READY"), countdown: txt("READY"), recording: txt("RECORDING"),
                       paused: txt("PAUSED"), stopping: txt("FINISHING"), review: txt("REVIEW"),
                       uploading: c.transcription === "SERVER" && this.uploadingAudio ? txt("TRANSCRIBING_SERVER") : txt("UPLOADING") }[s] || "";
        this.status.textContent = status;
        this.status.className = "mplus-status mplus-status--" + s;
        show(this.status, !!status);
        show(this.top, !ro && (this.kinds.length > 1 || !!status || !this.langSel.hidden));

        show(this.stage, !ro && live);
        show(this.video, cam);
        show(this.canvas, !cam && this.has("levelMeter"));
        show(this.level, video && this.has("levelMeter") && this.withSound());
        show(this.stage.querySelector(".mplus-rec"), !image);
        show(this.sttBox, !ro && this.transcribes() && (s === "recording" || s === "paused" || s === "stopping") && !!(this.sttFinalEl.textContent || this.sttInterimEl.textContent || this.stt));
        // the meter keeps its place from the moment Record is pressed, so nothing jumps
        show(this.meter, !ro && rolling);

        var canRecord = this.supported && !ro && !this.full();
        show(this.actions, !ro && s !== "review" && s !== "uploading");
        show(this.bRecord, canRecord && (s === "idle" || s === "ready"));
        if (image) {
            setCtl(this.bRecord, "fa-camera", s === "ready" ? txt("CAPTURE") : txt("TAKE_PHOTO"));
        } else {
            setCtl(this.bRecord, s !== "ready" && video ? "fa-video-camera" : "rec", s === "ready" ? txt("START") : video ? txt("OPEN_CAMERA") : txt("RECORD"));
        }
        this.bRecord.classList.toggle("mplus-btn--shutter", image && s === "ready");
        show(this.bPause, this.has("pause") && rolling);
        this.bPause.disabled = s !== "recording" && s !== "paused";
        setCtl(this.bPause, s === "paused" ? "play" : "pause", s === "paused" ? txt("RESUME") : txt("PAUSE"));
        this.bPause.classList.toggle("mplus-btn--primary", s === "paused" && !this.bPause.mplusTheme);
        show(this.bStop, rolling);
        this.bStop.disabled = s === "stopping";
        setCtl(this.bStop, "stop", s === "opening" || s === "countdown" ? txt("CANCEL") : txt("STOP"));
        show(this.bSwitch, cam && s === "ready" && this.has("switchCamera") && this.cameras > 1);
        show(this.bClose, s === "ready");
        show(this.bFile, !ro && !this.full() && s === "idle" && (this.has("upload") || !this.supported));
        var photo = !!this.ed;
        show(this.review, s === "review");
        show(this.player, !photo);
        show(this.photoBox, photo);
        this.reviewTitle.textContent = photo ? txt("PHOTO_TITLE") : txt("REVIEW_TITLE");
        show(this.reviewTextBox, !photo && (this.transcribes() || !!this.reviewText.value));
        // a recording over the limit can only be downloaded; a failed upload can be tried again
        this.bUse.disabled = !!this.tooBig || !!this.edWorking;
        setCtl(this.bUse, this.failed ? "fa-refresh" : "fa-check", this.failed ? txt("RETRY") : photo ? txt("USE_PHOTO") : txt("USE"));
        setCtl(this.bAgain, photo ? "fa-camera" : "fa-undo", photo ? txt("RETAKE") : txt("AGAIN"));
        show(this.bAgain, !photo || this.supported);
        show(this.aDownload, this.has("download") || !!this.failed || !!this.tooBig);
        if (!cam) { this.fitStage(0, 0); }
        if (this.bPause.mplusTheme) { this.bPause.classList.toggle("t-Button--hot", s === "paused"); }

        var hint = "";
        if (!ro && s === "idle") {
            if (this.full()) {
                hint = c.maxCount > 1 ? txt("MAX_COUNT", c.maxCount) : txt("MAX_COUNT_ONE");
            } else if (!this.supported) {
                hint = txt("NOT_SUPPORTED");
            } else if (image) {
                hint = txt("LIMIT_HINT", fmtBytes(c.maxBytes));
            } else {
                var q = this.quality(),
                    kbps = (this.withSound() ? this.audioKbps() : 0) + (video ? q.videoKbps : 0),
                    secs = kbps ? c.maxBytes * 8 / (kbps * 1000) : 0,
                    limit = c.maxDuration ? txt("LIMIT_HINT_TIME", fmtTime(c.maxDuration), fmtBytes(c.maxBytes)) : txt("LIMIT_HINT", fmtBytes(c.maxBytes));
                hint = limit + (secs && (!c.maxDuration || secs < c.maxDuration) ? " · " + txt("CAPACITY", fmtSpan(secs)) : "");
            }
        }
        this.hint.textContent = hint;
        show(this.hint, !!hint);
    };

    Recorder.prototype.say = function (text, type) {
        this.notice.textContent = "";
        if (text) {
            this.notice.appendChild(faIcon(type === "error" ? "fa-exclamation-circle" : type === "warn" ? "fa-exclamation-triangle" : "fa-info-circle"));
            this.notice.appendChild(el("span", null, { text: text }));
        }
        this.notice.className = "mplus-notice" + (type ? " mplus-notice--" + type : "");
        // errors and warnings interrupt a screen reader, information waits
        this.notice.setAttribute("role", type === "error" || type === "warn" ? "alert" : "status");
        show(this.notice, !!text);
    };

    Recorder.prototype.fire = function (name, data) {
        apex.event.trigger(this.input, "mediaplus" + name, $.extend({ item: this.cfg.item }, data || {}));
    };

    Recorder.prototype.focusNext = function () {
        var target = !this.bRecord.hidden ? this.bRecord : this.list.querySelector(".mplus-row:last-child button");
        if (target) { target.focus(); }
    };

    // ---------------------------------------------------------------- devices
    Recorder.prototype.constraints = function () {
        var q = this.quality(), a = this.audioOpts, audio = false, video = false;
        if (this.withSound()) {
            audio = {
                echoCancellation: a.indexOf("echoCancellation") >= 0,
                noiseSuppression: a.indexOf("noiseSuppression") >= 0,
                autoGainControl: a.indexOf("autoGainControl") >= 0
            };
            if (a.indexOf("mono") >= 0) { audio.channelCount = { ideal: 1 }; }
        }
        if (this.kind === "video") {
            video = {
                facingMode: { ideal: this.facing },
                height: { ideal: q.videoHeight },
                width: { ideal: Math.round(q.videoHeight * 16 / 9) },
                frameRate: { ideal: q.fps, max: q.fps }
            };
        } else if (this.kind === "image") {
            // photos: as sharp as the output needs, in the camera's own 4:3 shape
            var side = Math.max(1280, this.cfg.imageMaxSide || 1920);
            video = { facingMode: { ideal: this.facing }, width: { ideal: side }, height: { ideal: Math.round(side * 3 / 4) } };
        }
        return { audio: audio, video: video };
    };

    Recorder.prototype.open = function () {
        var self = this;
        this.say("");
        this.cancelled = false;
        this.timer.textContent = "0:00";
        this.meterFill.style.width = "0";
        this.meterText.textContent = txt("OF", fmtBytes(0), fmtBytes(this.cfg.maxBytes));
        this.setState("opening");
        audioSession("play-and-record");
        return navigator.mediaDevices.getUserMedia(this.constraints()).then(function (stream) {
            if (self.cancelled) {
                stream.getTracks().forEach(function (t) { t.stop(); });
                throw new Error("cancelled");
            }
            self.stream = stream;
            // a call, the screen locking or an unplugged device ends the tracks
            stream.getTracks().forEach(function (t) { t.addEventListener("ended", function () { self.trackEnded(stream); }); });
            if (self.camera()) {
                var st = stream.getVideoTracks()[0] && stream.getVideoTracks()[0].getSettings ? stream.getVideoTracks()[0].getSettings() : {};
                self.fitStage(st.width, st.height);
                self.video.srcObject = stream;
                self.video.controls = false;
                self.video.play().catch(function () { /* autoplay blocked - stays on first frame */ });
            }
            if (stream.getAudioTracks().length) {
                self.meterStart();
                // iOS mutes the microphone when something else takes it (a call, Siri, speech recognition on a headset)
                stream.getAudioTracks().forEach(function (t) { t.addEventListener("mute", function () { self.soundLost(stream); }); });
            }
            self.countCameras();
        }).catch(function (e) {
            if (self.cancelled) { throw e; }
            self.release();
            self.setState("idle");
            var notAllowed = e && (e.name === "NotAllowedError" || e.name === "SecurityError"),
                noDevice = e && (e.name === "NotFoundError" || e.name === "OverconstrainedError");
            self.say(notAllowed ? txt("NO_PERMISSION") : noDevice ? txt("NO_DEVICE") : (e && e.message) || txt("NOT_SUPPORTED"), "error");
            self.fire("error", { reason: e && e.name, message: e && e.message });
            throw e;
        });
    };

    Recorder.prototype.trackEnded = function (stream) {
        if (stream !== this.stream) { return; }
        if (this.state === "recording" || this.state === "paused") {
            this.say(txt("DEVICE_ENDED"), "warn");
            this.stop("device");
        } else if (this.state === "ready" || this.state === "countdown") {
            clearInterval(this.cdTimer);
            this.countdown.textContent = "";
            this.release();
            this.setState("idle");
            this.say(txt("DEVICE_ENDED"), "warn");
        }
    };

    Recorder.prototype.release = function () {
        var had = !!this.stream;
        if (this.stream) { this.stream.getTracks().forEach(function (t) { t.stop(); }); }
        this.stream = null;
        this.video.srcObject = null;
        this.meterStop();
        // back to normal playback, so the review player is heard on the loudspeaker (iOS)
        if (had) { audioSession("playback"); }
    };

    Recorder.prototype.switchCamera = function () {
        var self = this;
        if (this.state !== "ready") { return; }
        this.facing = this.facing === "user" ? "environment" : "user";
        this.release();
        this.open().then(function () { self.setState("ready"); }).catch(function () { /* message shown */ });
    };

    // Safari lists only one camera until the page may use the camera: count them again once it may
    Recorder.prototype.countCameras = function () {
        var self = this;
        if (!navigator.mediaDevices || !navigator.mediaDevices.enumerateDevices) { return; }
        navigator.mediaDevices.enumerateDevices().then(function (list) {
            self.cameras = list.filter(function (d) { return d.kind === "videoinput"; }).length;
            self.sync();
        }).catch(function () { /* keep the count */ });
    };

    // no sound reaches the recording (microphone muted by the system, or silent): say so while there is time
    Recorder.prototype.soundLost = function (stream) {
        if ((stream && stream !== this.stream) || this.soundWarned || (this.state !== "recording" && this.state !== "paused" && this.state !== "ready")) { return; }
        this.soundWarned = true;
        this.say(txt("NO_SOUND"), "warn");
        this.fire("warning", { reason: "nosound", seconds: this.seconds ? this.seconds() : 0 });
    };

    // Level meter, waveform and silence check (Web Audio). The AudioContext is made once the microphone is open:
    // made before, iOS can keep the old audio route (e.g. with headphones connected) and the recording stays
    // silent. While a page captures, Safari and Chrome let it start without another tap.
    Recorder.prototype.meterStart = function () {
        var self = this, AC = window.AudioContext || window.webkitAudioContext,
            track = this.stream && this.stream.getAudioTracks()[0], rate = track && track.getSettings ? track.getSettings().sampleRate : 0;
        if (!AC || !track) { return; }
        try {
            try { this.ac = new AC(rate ? { sampleRate: rate } : undefined); } catch (e1) { this.ac = new AC(); }
            if (this.ac.state === "suspended") { this.ac.resume().catch(function () { /* stays still */ }); }
            var src = this.ac.createMediaStreamSource(this.stream);
            this.analyser = this.ac.createAnalyser();
            this.analyser.fftSize = 1024;
            src.connect(this.analyser);
        } catch (e) { this.ac = null; return; }
        var fl = typeof this.analyser.getFloatTimeDomainData === "function",
            data = fl ? new Float32Array(this.analyser.fftSize) : new Uint8Array(this.analyser.fftSize),
            bars = [], last = 0, shown = 0;
        var draw = function (ts) {
            if (!self.analyser) { return; }
            self.raf = requestAnimationFrame(draw);
            // peak level in dB, shown from -54 dB (quiet room) to -6 dB (loud): speech moves the bars clearly
            var peak = 0, i, v;
            if (fl) { self.analyser.getFloatTimeDomainData(data); for (i = 0; i < data.length; i++) { v = Math.abs(data[i]); if (v > peak) { peak = v; } } }
            else { self.analyser.getByteTimeDomainData(data); for (i = 0; i < data.length; i++) { v = Math.abs(data[i] - 128) / 128; if (v > peak) { peak = v; } } }
            var db = peak > 0 ? 20 * Math.log(peak) / Math.LN10 : -100,
                lvl = Math.max(0, Math.min(1, (db + 54) / 48));
            shown = Math.max(lvl, shown * 0.85);
            // silence check: nothing above -60 dB for 3.5 seconds of recording
            if (self.state === "recording" && self.ac && self.ac.state === "running") {
                if (db > -60) { self.heard = true; } else if (!self.heard && self.seconds() > 3.5) { self.soundLost(); }
            }
            if (!self.has("levelMeter")) { return; }
            self.level.firstChild.style.width = Math.round(shown * 100) + "%";
            if (self.kind !== "audio") { return; }
            var cv = self.canvas, w = cv.clientWidth, h = cv.clientHeight, dpr = window.devicePixelRatio || 1;
            if (!w || !h) { return; }
            if (cv.width !== Math.round(w * dpr) || cv.height !== Math.round(h * dpr)) { cv.width = Math.round(w * dpr); cv.height = Math.round(h * dpr); }
            var bw = 3, gap = 2, max = Math.floor(w / (bw + gap));
            if (ts - last > 70 && self.state !== "paused") {
                last = ts;
                bars.push(self.state === "recording" ? shown : shown * 0.6);
                while (bars.length > max) { bars.shift(); }
            }
            var g = cv.getContext("2d"), cs = getComputedStyle(self.root);
            g.setTransform(dpr, 0, 0, dpr, 0, 0);
            g.clearRect(0, 0, w, h);
            g.fillStyle = self.state === "recording" ? cs.getPropertyValue("--mplus-wave").trim() || "#cb1100" : cs.getPropertyValue("--mplus-wave-idle").trim() || "#999";
            for (var j = 0; j < bars.length; j++) {
                var bh = Math.max(2, bars[j] * (h - 4)), x = w - (bars.length - j) * (bw + gap);
                g.fillRect(x, (h - bh) / 2, bw, bh);
            }
        };
        this.raf = requestAnimationFrame(draw);
    };

    Recorder.prototype.meterStop = function () {
        if (this.raf) { cancelAnimationFrame(this.raf); }
        this.raf = null;
        this.analyser = null;
        if (this.ac) { this.ac.close().catch(function () { /* already closed */ }); }
        this.ac = null;
        this.level.firstChild.style.width = "0";
    };

    // ---------------------------------------------------------------- live transcription (Web Speech API)
    Recorder.prototype.sttStart = function () {
        var self = this;
        this.sttText = "";
        this.sttInterim = "";
        this.sttError = null;
        this.sttFinalEl.textContent = "";
        this.sttInterimEl.textContent = "";
        if (!this.transcribes()) { return; }
        if (!this.SR) { this.say(txt("STT_UNSUPPORTED"), "info"); return; }
        var rec = new this.SR();
        rec.lang = this.lang;
        rec.continuous = true;
        rec.interimResults = true;
        rec.onresult = function (e) {
            var interim = "";
            for (var i = e.resultIndex; i < e.results.length; i++) {
                var t = e.results[i][0].transcript;
                if (e.results[i].isFinal) {
                    t = t.trim();
                    if (t) { self.sttText += (self.sttText ? " " : "") + t; }
                } else {
                    interim += t;
                }
            }
            self.sttInterim = interim;
            self.sttFinalEl.textContent = self.sttText + (self.sttText && interim ? " " : "");
            self.sttInterimEl.textContent = interim;
            self.sync();
        };
        rec.onerror = function (e) {
            if (e.error === "no-speech" || e.error === "aborted") { return; }
            self.sttError = e.error;
            self.sttWanted = false;
            self.say(txt("STT_FAILED", e.error), "info");
        };
        rec.onend = function () {
            // browsers end a session after a silence: carry on while still recording
            if (self.sttWanted && self.state === "recording") {
                try { rec.start(); } catch (x) { /* already running */ }
            } else if (self.sttDone) {
                self.sttDone();
            }
        };
        this.stt = rec;
        this.sttWanted = true;
        this.sttInterimEl.textContent = txt("TRANSCRIBING");
        try { rec.start(); } catch (e) { /* started already */ }
        this.sync();
    };

    Recorder.prototype.sttPause = function (on) {
        if (!this.stt || this.sttError) { return; }
        this.sttWanted = !on;
        try { if (on) { this.stt.stop(); } else { this.stt.start(); } } catch (e) { /* state already right */ }
    };

    // stop listening and wait (briefly) for the last words
    Recorder.prototype.sttFinish = function () {
        var self = this, rec = this.stt;
        this.stt = null;
        if (!rec) { return Promise.resolve(); }
        this.sttWanted = false;
        return new Promise(function (resolve) {
            var done = function () { self.sttDone = null; resolve(); };
            self.sttDone = done;
            setTimeout(done, 1500);
            try { rec.stop(); } catch (e) { done(); }
        }).then(function () {
            // make sure it has let go of the microphone (iOS keeps the audio in recording mode until it has)
            rec.onend = rec.onresult = rec.onerror = null;
            try { rec.abort(); } catch (e) { /* ended */ }
            if (self.sttInterim) { self.sttText += (self.sttText ? " " : "") + self.sttInterim.trim(); }
            self.sttInterim = "";
        });
    };

    Recorder.prototype.sttAbort = function () {
        if (this.stt) { this.sttWanted = false; try { this.stt.abort(); } catch (e) { /* stopped */ } }
        this.stt = null;
    };

    // ---------------------------------------------------------------- recording
    Recorder.prototype.start = function () {
        var self = this;
        if (this.disabled || this.full() || !this.supported) { return; }
        if (this.state === "idle") {
            this.open().then(function () {
                if (self.camera()) { self.setState("ready"); } else { self.begin(); }
            }).catch(function () { /* message shown, or cancelled */ });
        } else if (this.state === "ready") {
            if (this.kind === "image") { this.capture(); } else { this.begin(); }
        }
    };

    // photo: the current camera frame, at the camera's full resolution (not mirrored)
    Recorder.prototype.capture = function () {
        var self = this, v = this.video, w = v.videoWidth, h = v.videoHeight;
        if (this.state !== "ready" || !w || !h) { return; }
        var c = canvasOf(w, h);
        c.getContext("2d").drawImage(v, 0, 0, w, h);
        this.stage.classList.add("is-flash");
        setTimeout(function () { self.stage.classList.remove("is-flash"); }, 200);
        this.setState("stopping");
        this.rawBlob = null;
        encode(c, "image/jpeg", 0.95).then(function (b) {
            self.release();
            self.uploadName = null;
            self.pendingName = null;
            self.fire("capture", { width: w, height: h });
            self.take(b, null, "");
        });
    };

    Recorder.prototype.begin = function () {
        var self = this;
        if (this.has("countdown")) {
            var n = 3;
            this.setState("countdown");
            this.countdown.textContent = n;
            this.cdTimer = setInterval(function () {
                n--;
                if (n > 0) { self.countdown.textContent = n; return; }
                clearInterval(self.cdTimer);
                self.countdown.textContent = "";
                if (self.state === "countdown") { self.record(); }
            }, 1000);
        } else {
            this.record();
        }
    };

    Recorder.prototype.record = function () {
        var self = this, q = this.quality(), opts = {},
            mime = pickMime(this.kind, this.cfg.format);
        var akbps = this.audioKbps(mime);
        if (mime) { opts.mimeType = mime; }
        if (this.withSound()) { opts.audioBitsPerSecond = akbps * 1000; }
        if (this.kind === "video") { opts.videoBitsPerSecond = q.videoKbps * 1000; }
        this.heard = false;
        this.soundWarned = false;
        try {
            this.rec = new MediaRecorder(this.stream, opts);
        } catch (e) {
            try { this.rec = new MediaRecorder(this.stream); } catch (e2) {
                this.release(); this.setState("idle"); this.say(txt("NOT_SUPPORTED"), "error"); return;
            }
        }
        this.chunks = [];
        this.bytes = 0;
        this.lastChunk = 0;
        this.chunkAt = 0;
        // bytes per second asked for - covers data the recorder has not handed over yet (Chrome delivers MP4 late)
        this.bps = ((this.withSound() ? akbps : 0) + (this.kind === "video" ? q.videoKbps : 0)) * 1000 / 8;
        this.elapsed = 0;
        this.since = Date.now();
        this.warned = false;
        this.stopReason = null;
        this.rec.ondataavailable = function (e) {
            if (e.data && e.data.size) {
                self.chunks.push(e.data);
                self.bytes += e.data.size;
                self.lastChunk = e.data.size;
                self.chunkAt = self.seconds();
                self.check();
            }
        };
        this.rec.onstop = function () { self.finished(); };
        this.rec.onerror = function (e) { self.say((e.error && e.error.message) || txt("NOT_SUPPORTED"), "error"); };
        this.rec.start(1000);
        this.say("");
        this.setState("recording");
        this.sttStart();
        this.tick = setInterval(function () { self.check(); }, 250);
        this.check();
        this.fire("start", { kind: this.kind, mimeType: this.rec.mimeType });
    };

    Recorder.prototype.seconds = function () {
        return (this.elapsed + (this.state === "recording" ? Date.now() - this.since : 0)) / 1000;
    };

    // size / length limits, warning, meter
    Recorder.prototype.check = function () {
        if (this.state !== "recording" && this.state !== "paused") { return; }
        var c = this.cfg, sec = this.seconds(), lag = Math.max(0, sec - this.chunkAt),
            size = this.bytes + lag * this.bps,
            // while the size is only estimated (no data for a while: MP4), stop a little early
            target = c.maxBytes * (lag > 1.5 ? 0.94 : 1),
            sizeRatio = size / target,
            timeRatio = c.maxDuration ? sec / c.maxDuration : 0,
            ratio = Math.min(1, Math.max(sizeRatio, timeRatio)),
            warnAt = (c.warnPct || 80) / 100,
            rate = sec > 2 ? size / sec : 0,
            left = rate ? (target - size) / rate : 0;
        if (c.maxDuration) { left = left ? Math.min(left, c.maxDuration - sec) : c.maxDuration - sec; }

        this.timer.textContent = fmtTime(sec);
        this.meterFill.style.width = (ratio * 100).toFixed(1) + "%";
        this.meterBar.setAttribute("aria-valuenow", Math.round(ratio * 100));
        this.meter.classList.toggle("is-warn", ratio >= warnAt);
        // time first - that is what people think in; the size after it
        this.meterText.textContent = left > 0 && sec > 2 ? txt("METER", fmtTime(left), fmtBytes(size), fmtBytes(c.maxBytes)) : txt("OF", fmtBytes(size), fmtBytes(c.maxBytes));

        if (!this.warned && ratio >= warnAt && warnAt < 1) {
            this.warned = true;
            this.say(timeRatio > sizeRatio ? txt("WARN_TIME", fmtTime(sec), fmtTime(c.maxDuration)) : txt("WARN_SIZE", fmtBytes(size), fmtBytes(c.maxBytes)), "warn");
            if (navigator.vibrate) { navigator.vibrate(200); }
            this.fire("warning", { bytes: size, seconds: sec, maxBytes: c.maxBytes, maxDuration: c.maxDuration });
        }
        // stop while the next one-second part still fits
        var next = Math.max(this.lastChunk, rate) * 1.5;
        if (this.state === "recording" && size + next >= target) {
            this.stop("size");
        } else if (this.state === "recording" && c.maxDuration && sec >= c.maxDuration) {
            this.stop("duration");
        }
    };

    Recorder.prototype.togglePause = function () {
        if (this.state === "paused") { this.resume(); } else { this.pause(); }
    };

    Recorder.prototype.pause = function () {
        if (this.state !== "recording" || !this.rec) { return; }
        this.rec.pause();
        this.elapsed += Date.now() - this.since;
        this.sttPause(true);
        this.setState("paused");
        this.fire("pause", { seconds: this.seconds() });
    };

    Recorder.prototype.resume = function () {
        if (this.state !== "paused" || !this.rec) { return; }
        this.rec.resume();
        this.since = Date.now();
        this.setState("recording");
        this.sttPause(false);
        this.fire("resume", { seconds: this.seconds() });
    };

    Recorder.prototype.stop = function (reason) {
        if (this.state === "opening") {
            this.cancelled = true;
            this.release();
            this.setState("idle");
            return;
        }
        if (this.state === "countdown") {
            clearInterval(this.cdTimer);
            this.countdown.textContent = "";
            this.release();
            this.setState("idle");
            return;
        }
        if (!this.rec || (this.state !== "recording" && this.state !== "paused")) { return; }
        if (this.state === "recording") { this.elapsed += Date.now() - this.since; }
        this.stopReason = typeof reason === "string" ? reason : null;
        clearInterval(this.tick);
        this.setState("stopping");
        try { this.rec.stop(); } catch (e) { this.finished(); }
    };

    Recorder.prototype.finished = function () {
        var self = this, c = this.cfg, mime = ((this.rec && this.rec.mimeType) || (this.chunks[0] && this.chunks[0].type) || (this.kind + "/webm")).split(";")[0],
            blob = new Blob(this.chunks, { type: mime }), sec = this.elapsed / 1000;
        this.release();
        this.chunks = [];
        this.rec = null;
        if (this.stopReason === "size") {
            this.say(txt("STOPPED_SIZE", fmtBytes(c.maxBytes)), "warn");
            this.fire("limit", { reason: "size", bytes: blob.size, seconds: sec });
        } else if (this.stopReason === "duration") {
            this.say(txt("STOPPED_TIME", fmtTime(c.maxDuration)), "warn");
            this.fire("limit", { reason: "duration", bytes: blob.size, seconds: sec });
        } else if (this.stopReason !== "device" && !this.sttError) {
            this.say("");
        }
        Promise.all([fixMedia(blob, sec * 1000), this.sttFinish()]).then(function (res) {
            var fixed = res[0];
            audioSession("playback");
            // the recording as the browser wrote it - used if this browser cannot play the repaired file
            self.rawBlob = fixed !== blob ? blob : null;
            if (apex.debug) { apex.debug.info("MediaPlus", self.cfg.item, mime, "recorded", blob.size, "repaired", fixed !== blob ? fixed.size : "no"); }
            self.fire("stop", { bytes: fixed.size, seconds: sec, mimeType: mime });
            if (!fixed.size) { self.setState("idle"); return; }
            // never throw a recording away: one over the limit is offered for download
            self.tooBig = fixed.size > c.maxBytes * (c.allowance || 1);
            if (self.tooBig) { self.say(txt("TOO_LARGE_KEEP", fmtBytes(fixed.size), fmtBytes(c.maxBytes)), "error"); }
            self.take(fixed, sec, self.transcribes() ? self.sttText : "", self.tooBig);
        });
    };

    // a finished recording or a chosen file: review it or save it straight away
    Recorder.prototype.take = function (blob, sec, transcript, mustReview) {
        var self = this;
        this.pendingBlob = blob;
        this.pendingSec = sec;
        this.failed = false;
        this.reviewText.value = (transcript || "").slice(0, MAX_TRANSCRIPT);
        if ((blob.type || "").indexOf("image/") === 0) {
            // a photo always goes through the editor: it is resized and compressed there, even without review
            this.kind = "image";
            this.edLoad(blob).then(function () {
                if (self.has("preview") || self.tools.length || mustReview) { self.showReview(); } else { self.accept(); }
            }).catch(function (e) {
                self.ed = null;
                self.pendingBlob = null;
                self.setState("idle");
                self.say(txt("PHOTO_FAILED", (e && e.message) || ""), "error");
            });
            return;
        }
        this.ed = null;
        if (this.has("preview") || mustReview) {
            this.showReview();
        } else {
            this.accept();
        }
    };

    Recorder.prototype.fileName = function (mime, kind) {
        var d = new Date(), p = function (n) { return String(n).padStart(2, "0"); },
            stamp = d.getFullYear() + p(d.getMonth() + 1) + p(d.getDate()) + "-" + p(d.getHours()) + p(d.getMinutes()) + p(d.getSeconds());
        return (this.cfg.fileName || "#ITEM#-#TIMESTAMP#")
            .replace(/#ITEM#/g, this.cfg.item.toLowerCase())
            .replace(/#TIMESTAMP#/g, stamp)
            .replace(/#KIND#/g, kind)
            .replace(/#N#/g, this.items.length + 1)
            .replace(/[^\w.\- ]+/g, "_") + "." + extFor(mime);
    };

    Recorder.prototype.showReview = function () {
        if (this.ed) {
            this.pendingName = this.pendingName || (this.uploadName ? this.uploadName.replace(/\.[^.]*$/, "").replace(/[^\w.\- ]+/g, "_") : null);
            this.aDownload.href = "#";
            this.setState("review");
            this.saveDraft();
            this.edRender();
            (this.tooBig ? this.aDownload : this.bUse).focus();
            return;
        }
        var self = this, blob = this.pendingBlob, kind = blob.type.indexOf("video") === 0 ? "video" : "audio",
            m = el(kind, "mplus-media", { controls: true, playsinline: kind === "video" ? true : null, preload: "metadata" });
        if (this.reviewUrl) { URL.revokeObjectURL(this.reviewUrl); }
        this.reviewUrl = URL.createObjectURL(blob);
        m.addEventListener("play", function () { audioSession("playback"); });
        m.addEventListener("error", function () { self.playError(m, blob); });
        fixDuration(m);
        m.src = this.reviewUrl;
        this.player.innerHTML = "";
        this.player.appendChild(m);
        this.reviewMeta.textContent = (this.pendingSec ? fmtTime(this.pendingSec) + " · " : "") + fmtBytes(blob.size);
        this.pendingName = this.pendingName || (this.uploadName ? this.uploadName.replace(/\.[^.]*$/, "").replace(/[^\w.\- ]+/g, "_") + "." + extFor(blob.type) : this.fileName(blob.type, kind));
        this.aDownload.href = this.reviewUrl;
        this.aDownload.setAttribute("download", this.pendingName);
        this.setState("review");
        this.saveDraft();
        (this.tooBig ? this.aDownload : this.bUse).focus();
    };

    // the review player cannot play the file: use the recording as the browser wrote it, if it was repaired;
    // otherwise say so (Download still works)
    Recorder.prototype.playError = function (m, blob) {
        var code = m.error ? m.error.code : 0, msg = (m.error && m.error.message) || "";
        if (apex.debug) { apex.debug.warn("MediaPlus", this.cfg.item, "review cannot play", blob.type, blob.size, "code", code, msg); }
        if (blob !== this.pendingBlob || this.state !== "review") { return; }
        if (this.rawBlob && this.rawBlob !== blob) {
            this.pendingBlob = this.rawBlob;
            this.rawBlob = null;
            this.showReview();
            return;
        }
        this.say(txt("PLAY_FAILED", "(" + (msg || "code " + code) + ")"), "warn");
    };

    Recorder.prototype.saveDraft = function () {
        if (!this.pendingBlob || this.tooBig) { return; }
        drafts.put(this.draftKey, { blob: this.pendingBlob, raw: this.rawBlob || null, type: this.pendingBlob.type, sec: this.pendingSec, name: this.pendingName,
                                    transcript: this.reviewText.value, at: Date.now() });
    };

    Recorder.prototype.dropDraft = function () { drafts.del(this.draftKey); };

    // a recording reviewed but never used (reload, crash, expired session) comes back
    Recorder.prototype.recover = function () {
        var self = this, skip = null;
        // the page was submitted with an allowed request (e.g. CANCEL): the unfinished recording was dropped on purpose
        try { skip = sessionStorage.getItem("mplus-nodraft:" + this.draftKey); sessionStorage.removeItem("mplus-nodraft:" + this.draftKey); } catch (e) { /* no storage */ }
        if (skip) { this.dropDraft(); return; }
        drafts.get(this.draftKey).then(function (d) {
            if (!d || !d.blob || self.state !== "idle" || self.full()) { return; }
            if (Date.now() - d.at > DRAFT_DAYS * 864e5) { self.dropDraft(); return; }
            // copied into memory: Safari cannot always play a file straight from IndexedDB
            var copy = function (b) { return b ? b.arrayBuffer().then(function (x) { return new Blob([x], { type: b.type || d.type }); }) : Promise.resolve(null); };
            Promise.all([copy(d.blob), copy(d.raw)]).then(function (res) {
                if (self.state !== "idle") { return; }
                self.pendingName = d.name;
                self.rawBlob = res[1];
                self.take(res[0], d.sec, d.transcript, true);
                self.say(txt("RECOVERED"), "info");
            }).catch(function () { self.dropDraft(); });
        });
    };

    Recorder.prototype.clearReview = function () {
        var m = this.player.querySelector("audio,video");
        if (m) { m.pause(); }
        this.player.innerHTML = "";
        if (this.reviewUrl) { URL.revokeObjectURL(this.reviewUrl); }
        if (this.dlUrl) { URL.revokeObjectURL(this.dlUrl); }
        this.reviewUrl = this.dlUrl = null;
        this.ed = null;
        this.edCache = this.edBusy = null;
    };

    // name of a photo: the chosen file's name or the File Name pattern, with the output format's extension
    Recorder.prototype.photoName = function (mime) {
        return (this.pendingName ? this.pendingName.replace(/\.[^.]*$/, "") + "." + extFor(mime) : this.fileName(mime, "image"));
    };

    Recorder.prototype.discard = function (again) {
        var self = this,
            go = function () {
                self.clearReview();
                self.pendingBlob = null;
                self.rawBlob = null;
                self.pendingName = null;
                self.tooBig = false;
                self.failed = false;
                self.reviewText.value = "";
                self.dropDraft();
                self.say("");
                self.setState("idle");
                self.fire("discard");
                if (again) { self.start(); }
            };
        if (this.state !== "review") { return; }
        if (!again && this.has("confirmDelete")) {
            apex.message.confirm(txt("CONFIRM_DISCARD"), function (ok) { if (ok) { go(); } });
        } else {
            go();
        }
    };

    Recorder.prototype.useFile = function (file) {
        var self = this, c = this.cfg, type = (file.type || "").toLowerCase(), kind = type.split("/")[0];
        if (this.kinds.indexOf(kind) < 0) { this.say(txt("FILE_WRONG_TYPE"), "error"); return; }
        // photos are made smaller in the editor, so a large photo is fine; recordings must fit as they are
        if (kind !== "image" && file.size > c.maxBytes) { this.say(txt("FILE_TOO_LARGE", fmtBytes(file.size), fmtBytes(c.maxBytes)), "error"); return; }
        this.say("");
        this.kind = kind;
        this.rawBlob = null;
        if (kind === "image") {
            this.uploadName = file.name;
            this.pendingName = null;
            this.take(file, null, "");
            return;
        }
        mediaDuration(file).then(function (sec) {
            self.uploadName = file.name;
            self.pendingName = null;
            self.take(file, sec, "");
        });
    };

    // ---------------------------------------------------------------- photo editor
    var RATIOS = { "1:1": 1, "4:3": 4 / 3, "3:4": 3 / 4, "16:9": 16 / 9, "9:16": 9 / 16 },
        COLOURS = ["#e53935", "#fdd835", "#ffffff", "#212121"];

    Recorder.prototype.buildEditor = function (th) {
        var self = this, c = this.cfg, t = this.tools, has = function (x) { return t.indexOf(x) >= 0; },
            tb = function (cls, icon, label) { return ctl("mplus-btn--ghost " + cls, icon, label, true, th); },
            fixed = RATIOS[c.cropRatio];
        this.edCanvas = el("canvas", "mplus-ed-canvas");
        this.edCrop = el("div", "mplus-ed-crop", { tabindex: "0", role: "group", "aria-label": txt("CROP") },
            ["nw", "n", "ne", "e", "se", "s", "sw", "w"].map(function (h) { return el("span", "mplus-ed-h mplus-ed-h--" + h, { "data-h": h }); }));
        this.edWrap = el("div", "mplus-ed-wrap", null, [this.edCanvas, this.edCrop]);

        this.bRotL = tb("mplus-e-rotl", "fa-rotate-left", txt("ROTATE_LEFT"));
        this.bRotR = tb("mplus-e-rotr", "fa-rotate-right", txt("ROTATE_RIGHT"));
        this.bFlip = tb("mplus-e-flip", "fa-arrows-h", txt("FLIP"));
        this.bAdjust = tb("mplus-e-adjust", "fa-sliders", txt("ADJUST"));
        this.bGray = tb("mplus-e-gray", "fa-adjust", txt("GRAYSCALE"));
        this.bDraw = tb("mplus-e-draw", "fa-pencil", txt("DRAW"));
        this.bUndo = tb("mplus-e-undo", "fa-eraser", txt("UNDO"));
        this.bReset = ctl("mplus-btn--ghost mplus-e-reset", "fa-refresh", txt("RESET"), false, th);
        this.edRatio = el("select", "mplus-ed-select mplus-e-ratio", { "aria-label": txt("CROP"), title: txt("CROP") },
            [["FREE", txt("CROP_FREE")], ["1:1", "1:1"], ["4:3", "4:3"], ["3:4", "3:4"], ["16:9", "16:9"], ["9:16", "9:16"], ["ALL", txt("CROP_ALL")]]
                .map(function (o) { return el("option", null, { value: o[0], text: o[1] }); }));
        var max = c.imageMaxSide || 1920;
        this.edSize = el("select", "mplus-ed-select mplus-e-size", { "aria-label": txt("SIZE"), title: txt("SIZE") },
            [max].concat([1600, 1280, 1024, 800, 640].filter(function (s) { return s < max; }))
                .map(function (s, i) { return el("option", null, { value: s, text: i ? txt("SIZE_PX", s) : txt("SIZE_FULL", s) }); }));
        this.edColours = el("span", "mplus-ed-colours", { role: "group", "aria-label": txt("DRAW") }, COLOURS.map(function (col) {
            var b = el("button", "mplus-ed-colour", { type: "button", "aria-label": col, title: col, "aria-pressed": String(col === COLOURS[0]) });
            b.style.background = col;
            b.addEventListener("click", function () {
                self.ed.colour = col;
                Array.prototype.forEach.call(self.edColours.children, function (x) { x.setAttribute("aria-pressed", String(x === b)); });
            });
            return b;
        }));
        this.edTools = el("div", "mplus-ed-tools", { role: "toolbar", "aria-label": txt("ADJUST") }, [
            has("crop") && !fixed ? this.edRatio : null,
            has("rotate") ? this.bRotL : null, has("rotate") ? this.bRotR : null,
            has("flip") ? this.bFlip : null,
            has("adjust") ? this.bAdjust : null, has("adjust") ? this.bGray : null,
            has("draw") ? this.bDraw : null, has("draw") ? this.edColours : null, has("draw") ? this.bUndo : null,
            has("resize") ? this.edSize : null,
            t.length ? this.bReset : null
        ]);
        var slider = function (key, label, min, max) {
            var i = el("input", "mplus-ed-range mplus-e-" + key, { type: "range", min: min, max: max, value: 100, "aria-label": label });
            i.addEventListener("input", function () { self.ed.adj[key] = +i.value; self.edChanged(); });
            return { input: i, box: el("label", "mplus-ed-slider", null, [el("span", null, { text: label }), i]) };
        };
        this.sB = slider("b", txt("BRIGHTNESS"), 40, 160);
        this.sC = slider("c", txt("CONTRAST"), 40, 160);
        this.sS = slider("s", txt("SATURATION"), 0, 200);
        this.edAdjust = el("div", "mplus-ed-adjust", { hidden: true }, [this.sB.box, this.sC.box, this.sS.box]);
        this.edMeta = el("span", "mplus-ed-meta", { "aria-live": "polite" });
        this.photoBox = el("div", "mplus-ed", { hidden: true }, [el("div", "mplus-ed-stage", null, [this.edWrap]), this.edTools, this.edAdjust, this.edMeta]);
        show(this.edCrop, has("crop") || !!fixed);

        this.bRotL.addEventListener("click", function () { self.edRotate(-90); });
        this.bRotR.addEventListener("click", function () { self.edRotate(90); });
        this.bFlip.addEventListener("click", function () { self.edFlip(); });
        this.bAdjust.addEventListener("click", function () {
            var on = self.edAdjust.hidden;
            show(self.edAdjust, on);
            self.bAdjust.setAttribute("aria-pressed", String(on));
        });
        this.bGray.addEventListener("click", function () { self.ed.gray = !self.ed.gray; self.bGray.setAttribute("aria-pressed", String(self.ed.gray)); self.edChanged(); });
        this.bDraw.addEventListener("click", function () { self.edSetDrawing(!self.ed.drawing); });
        this.bUndo.addEventListener("click", function () { self.ed.strokes.pop(); self.edChanged(); });
        this.bReset.addEventListener("click", function () { self.edReset(); });
        this.edRatio.addEventListener("change", function () { self.edSetRatio(self.edRatio.value); });
        this.edSize.addEventListener("change", function () { self.ed.side = +self.edSize.value; self.edChanged(true); });
        this.edCrop.addEventListener("pointerdown", function (e) { self.edPointer(e, e.target.getAttribute("data-h") || "move"); });
        this.edCanvas.addEventListener("pointerdown", function (e) { if (self.ed && self.ed.drawing) { self.edDrawStart(e); } });
        // the crop box by keyboard: arrows move it, Shift + arrows resize it
        this.edCrop.addEventListener("keydown", function (e) {
            var d = { ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1] }[e.key];
            if (!d || !self.ed) { return; }
            e.preventDefault();
            var start = $.extend({}, self.ed.crop);
            self.edDrag(e.shiftKey ? (d[0] ? "e" : "s") : "move", start, d[0] * 0.02, d[1] * 0.02);
            self.edPlaceCrop();
            self.edChanged(true);
        });
        window.addEventListener("resize", function () { if (self.ed && self.state === "review") { self.edRender(); } });
    };

    Recorder.prototype.edTW = function () { return this.ed.rot % 180 ? this.ed.src.height : this.ed.src.width; };
    Recorder.prototype.edTH = function () { return this.ed.rot % 180 ? this.ed.src.width : this.ed.src.height; };

    Recorder.prototype.edLoad = function (blob) {
        var self = this;
        return loadPhoto(blob).then(function (src) {
            self.ed = { src: src, rot: 0, flip: false, crop: { x: 0, y: 0, w: 1, h: 1 }, ratio: 0, adj: { b: 100, c: 100, s: 100 }, gray: false,
                        strokes: [], colour: COLOURS[0], drawing: false, side: self.cfg.imageMaxSide || 1920 };
            self.edVersion = 0;
            self.edCache = self.edBusy = null;
            self.edEstimate = null;
            self.edControlsReset();
            if (RATIOS[self.cfg.cropRatio]) { self.edSetRatio(self.cfg.cropRatio, true); }
        });
    };

    Recorder.prototype.edControlsReset = function () {
        var self = this;
        [this.sB, this.sC, this.sS].forEach(function (s) { s.input.value = 100; });
        this.edRatio.value = "FREE";
        this.edSize.selectedIndex = 0;
        show(this.edAdjust, false);
        [this.bAdjust, this.bGray, this.bDraw].forEach(function (b) { b.setAttribute("aria-pressed", "false"); });
        Array.prototype.forEach.call(this.edColours.children, function (x, i) { x.setAttribute("aria-pressed", String(!i)); });
        show(this.edColours, false);
        show(this.bUndo, false);
        this.photoBox.classList.remove("is-drawing");
        if (self.edCrop) { self.edCrop.style.pointerEvents = ""; }
    };

    Recorder.prototype.edReset = function () {
        var ed = this.ed;
        ed.rot = 0; ed.flip = false; ed.crop = { x: 0, y: 0, w: 1, h: 1 }; ed.ratio = 0;
        ed.adj = { b: 100, c: 100, s: 100 }; ed.gray = false; ed.strokes = []; ed.drawing = false; ed.side = this.cfg.imageMaxSide || 1920;
        this.edControlsReset();
        if (RATIOS[this.cfg.cropRatio]) { this.edSetRatio(this.cfg.cropRatio, true); }
        this.edChanged();
    };

    // the preview: the whole (turned, adjusted) photo; the crop is the box on top of it
    Recorder.prototype.edRender = function () {
        if (!this.ed) { return; }
        var dpr = window.devicePixelRatio || 1,
            side = Math.min(2048, Math.max(640, Math.round((this.root.clientWidth || 800) * dpr))),
            p = renderPhoto(this.ed, side, false), cv = this.edCanvas;
        cv.width = p.width;
        cv.height = p.height;
        cv.getContext("2d").drawImage(p, 0, 0);
        this.edPlaceCrop();
        this.edMetaUpdate();
    };

    Recorder.prototype.edPlaceCrop = function () {
        var c = this.ed.crop, s = this.edCrop.style;
        s.left = c.x * 100 + "%";
        s.top = c.y * 100 + "%";
        s.width = c.w * 100 + "%";
        s.height = c.h * 100 + "%";
    };

    // cropOnly: the preview does not change (crop box, output size)
    Recorder.prototype.edChanged = function (cropOnly) {
        var self = this;
        this.edVersion++;
        this.edEstimate = null;
        if (!cropOnly) {
            if (!this.edRaf) { this.edRaf = requestAnimationFrame(function () { self.edRaf = null; self.edRender(); }); }
        } else {
            this.edMetaUpdate();
        }
        // the file size, once the user stops changing things
        clearTimeout(this.edTimer);
        this.edTimer = setTimeout(function () {
            var v = self.edVersion;
            if (!self.ed) { return; }
            self.edExport().then(function (r) { if (self.ed && v === self.edVersion) { self.edEstimate = r.blob.size; self.edMetaUpdate(); } });
        }, 700);
    };

    Recorder.prototype.edMetaUpdate = function () {
        var ed = this.ed, c = ed.crop, cw = c.w * this.edTW(), ch = c.h * this.edTH(), s = Math.min(1, ed.side / Math.max(cw, ch));
        this.edMeta.textContent = txt("PHOTO_META", Math.round(cw * s), Math.round(ch * s)) + (this.edEstimate ? " · " + txt("PHOTO_SIZE", fmtBytes(this.edEstimate)) : "");
    };

    Recorder.prototype.edExport = function () {
        var self = this, v = this.edVersion, c = this.cfg,
            type = { PNG: "image/png", WEBP: "image/webp" }[c.imageFormat] || "image/jpeg";
        if (this.edCache && this.edCache.v === v) { return Promise.resolve(this.edCache.r); }
        if (this.edBusy && this.edBusy.v === v) { return this.edBusy.p; }
        var p = encodeToFit(this.ed, this.ed.side, type, Math.min(1, Math.max(0.3, (c.imageQuality || 85) / 100)), c.maxBytes)
            .then(function (r) { self.edCache = { v: v, r: r }; return r; });
        this.edBusy = { v: v, p: p };
        return p;
    };

    // turn by 90 degrees; the crop turns with the photo (a crop shape is fitted again)
    Recorder.prototype.edRotate = function (deg) {
        var ed = this.ed, c = ed.crop;
        ed.rot = (ed.rot + deg + 360) % 360;
        ed.crop = deg > 0 ? { x: 1 - (c.y + c.h), y: c.x, w: c.h, h: c.w } : { x: c.y, y: 1 - (c.x + c.w), w: c.h, h: c.w };
        if (ed.ratio) { this.edFit(ed.ratio); }
        this.edChanged();
    };

    // mirror what is shown: drawn as turn(flip(source)), so a flip of the turned photo is flip + the opposite turn
    Recorder.prototype.edFlip = function () {
        var ed = this.ed;
        ed.flip = !ed.flip;
        ed.rot = (360 - ed.rot) % 360;
        ed.crop = { x: 1 - ed.crop.x - ed.crop.w, y: ed.crop.y, w: ed.crop.w, h: ed.crop.h };
        this.edChanged();
    };

    // largest centred crop of the given shape (width / height in pixels)
    Recorder.prototype.edFit = function (ratio) {
        var n = ratio * this.edTH() / this.edTW(), w = n >= 1 ? 1 : n, h = n >= 1 ? 1 / n : 1;
        this.ed.crop = { x: (1 - w) / 2, y: (1 - h) / 2, w: w, h: h };
    };

    Recorder.prototype.edSetRatio = function (v, quiet) {
        var ed = this.ed;
        if (v === "ALL") {
            ed.ratio = 0;
            ed.crop = { x: 0, y: 0, w: 1, h: 1 };
            this.edRatio.value = "FREE";
        } else {
            ed.ratio = RATIOS[v] || 0;
            if (ed.ratio) { this.edFit(ed.ratio); }
        }
        if (!quiet) { this.edPlaceCrop(); this.edChanged(true); }
    };

    Recorder.prototype.edSetDrawing = function (on) {
        this.ed.drawing = on;
        this.bDraw.setAttribute("aria-pressed", String(on));
        this.photoBox.classList.toggle("is-drawing", on);
        this.edCrop.style.pointerEvents = on ? "none" : "";
        show(this.edColours, on);
        show(this.bUndo, on);
    };

    // drag the crop box (mode "move") or one of its handles (n, ne, e ...); du / dv are fractions of the photo
    Recorder.prototype.edDrag = function (mode, start, du, dv) {
        var ed = this.ed, MIN = 0.05, r = ed.ratio ? ed.ratio * this.edTH() / this.edTW() : 0,
            x0 = start.x, y0 = start.y, x1 = start.x + start.w, y1 = start.y + start.h;
        if (mode === "move") {
            ed.crop = { x: Math.min(1 - start.w, Math.max(0, x0 + du)), y: Math.min(1 - start.h, Math.max(0, y0 + dv)), w: start.w, h: start.h };
            return;
        }
        if (mode.indexOf("w") >= 0) { x0 = Math.min(x1 - MIN, Math.max(0, x0 + du)); }
        if (mode.indexOf("e") >= 0) { x1 = Math.max(x0 + MIN, Math.min(1, x1 + du)); }
        if (mode.indexOf("n") >= 0) { y0 = Math.min(y1 - MIN, Math.max(0, y0 + dv)); }
        if (mode.indexOf("s") >= 0) { y1 = Math.max(y0 + MIN, Math.min(1, y1 + dv)); }
        var w = x1 - x0, h = y1 - y0;
        if (r) {
            // keep the shape: the dragged side decides; the opposite side (or the centre) stays
            if (mode === "n" || mode === "s") { w = h * r; } else { h = w / r; }
            if (w > 1) { w = 1; h = w / r; }
            if (h > 1) { h = 1; w = h * r; }
            x0 = mode.indexOf("w") >= 0 ? x1 - w : mode.indexOf("e") >= 0 ? x0 : start.x + start.w / 2 - w / 2;
            y0 = mode.indexOf("n") >= 0 ? y1 - h : mode.indexOf("s") >= 0 ? y0 : start.y + start.h / 2 - h / 2;
            x0 = Math.min(Math.max(0, x0), 1 - w);
            y0 = Math.min(Math.max(0, y0), 1 - h);
        }
        ed.crop = { x: x0, y: y0, w: w, h: h };
    };

    Recorder.prototype.edPointer = function (e, mode) {
        if (!this.ed || e.button > 0) { return; }
        var self = this, box = this.edWrap.getBoundingClientRect(), start = $.extend({}, this.ed.crop), x = e.clientX, y = e.clientY, t = e.target;
        e.preventDefault();
        try { t.setPointerCapture(e.pointerId); } catch (x2) { /* old browser */ }
        var move = function (ev) { self.edDrag(mode, start, (ev.clientX - x) / box.width, (ev.clientY - y) / box.height); self.edPlaceCrop(); },
            up = function () {
                t.removeEventListener("pointermove", move);
                t.removeEventListener("pointerup", up);
                t.removeEventListener("pointercancel", up);
                self.edChanged(true);
            };
        t.addEventListener("pointermove", move);
        t.addEventListener("pointerup", up);
        t.addEventListener("pointercancel", up);
    };

    // a point of the preview (0..1 of the turned photo) in source coordinates (0..1)
    Recorder.prototype.edToSource = function (u, v) {
        var ed = this.ed, sw = ed.src.width, sh = ed.src.height, X = (u - 0.5) * this.edTW(), Y = (v - 0.5) * this.edTH(),
            t = ed.rot * Math.PI / 180, cs = Math.round(Math.cos(t)), sn = Math.round(Math.sin(t)),
            a = X * cs + Y * sn, b = -X * sn + Y * cs;
        if (ed.flip) { a = -a; }
        return [(a + sw / 2) / sw, (b + sh / 2) / sh];
    };

    Recorder.prototype.edDrawStart = function (e) {
        var self = this, ed = this.ed, cv = this.edCanvas, rect = cv.getBoundingClientRect(), g = cv.getContext("2d"),
            st = { colour: ed.colour, w: 0.006, pts: [] }, last = null;
        e.preventDefault();
        try { cv.setPointerCapture(e.pointerId); } catch (x) { /* old browser */ }
        var add = function (ev) {
                var u = Math.min(1, Math.max(0, (ev.clientX - rect.left) / rect.width)), v = Math.min(1, Math.max(0, (ev.clientY - rect.top) / rect.height)),
                    px = u * cv.width, py = v * cv.height;
                st.pts.push(self.edToSource(u, v));
                g.strokeStyle = st.colour;
                g.lineWidth = Math.max(1, st.w * Math.max(cv.width, cv.height));
                g.lineCap = g.lineJoin = "round";
                g.beginPath();
                g.moveTo(last ? last[0] : px, last ? last[1] : py);
                g.lineTo(px + (last ? 0 : 0.1), py);
                g.stroke();
                last = [px, py];
            },
            up = function () {
                cv.removeEventListener("pointermove", add);
                cv.removeEventListener("pointerup", up);
                cv.removeEventListener("pointercancel", up);
                if (st.pts.length) { ed.strokes.push(st); }
                self.edChanged();
            };
        add(e);
        cv.addEventListener("pointermove", add);
        cv.addEventListener("pointerup", up);
        cv.addEventListener("pointercancel", up);
    };

    // ---------------------------------------------------------------- upload to the collection
    Recorder.prototype.joined = function () {
        return this.items.filter(function (r) { return r.seq; }).map(function (r) { return r.transcript; }).filter(Boolean).join("\n\n");
    };

    Recorder.prototype.accept = function () {
        var self = this, blob = this.pendingBlob;
        if (!blob || this.tooBig || this.edWorking) { return; }
        if (!this.ed) { this.send(blob, null); return; }
        // a photo: the edited picture, resized and compressed until it fits the Maximum File Size
        this.edWorking = true;
        this.sync();
        this.say(txt("PREPARING"), "info");
        this.edExport().then(function (res) {
            self.edWorking = false;
            if (!res.fits) {
                self.say(txt("PHOTO_TOO_LARGE", fmtBytes(self.cfg.maxBytes)), "error");
                if (self.state === "review") { self.sync(); } else { self.showReview(); }
                return;
            }
            self.send(res.blob, { name: self.photoName(res.blob.type), width: res.width, height: res.height });
        }).catch(function (e) {
            self.edWorking = false;
            self.sync();
            self.say(txt("PHOTO_FAILED", (e && e.message) || ""), "error");
        });
    };

    Recorder.prototype.send = function (blob, photo) {
        var self = this,
            kind = blob.type.split("/")[0] === "video" ? "video" : blob.type.split("/")[0] === "image" ? "image" : "audio",
            mime = (blob.type || kind + "/webm").split(";")[0],
            name = photo ? photo.name : this.pendingName || (this.uploadName ? this.uploadName.replace(/\.[^.]*$/, "").replace(/[^\w.\- ]+/g, "_") + "." + extFor(mime) : this.fileName(mime, kind)),
            transcript = photo ? "" : this.reviewText.value.trim().slice(0, MAX_TRANSCRIPT),
            sec = photo ? null : this.pendingSec,
            row = { name: name, mime: mime, kind: kind.toUpperCase(), size: blob.size, duration: sec, blob: blob, uploading: 0, transcript: transcript,
                    width: photo ? photo.width : null, height: photo ? photo.height : null };
        this.pendingName = name;
        this.saveDraft();
        this.clearReview();
        this.pendingBlob = null;
        this.say("");
        this.items.push(row);
        this.uploadingAudio = kind === "audio";
        this.setState("uploading");
        this.renderList();
        this.upload(blob, row).then(function (res) {
            var before = self.joined();
            row.seq = res.seq;
            row.name = res.name;
            row.uploading = null;
            row.pending = true;
            if (res.transcript) { row.transcript = res.transcript; }
            self.pendingName = null;
            self.uploadName = null;
            self.rawBlob = null;
            self.failed = false;
            self.reviewText.value = "";
            self.dropDraft();
            self.setState("idle");
            self.renderList();
            self.writeValue(before, row);
            self.focusNext();
            self.fire("saved", { seq: res.seq, name: res.name, mimeType: res.mime, kind: res.kind, bytes: res.size, seconds: res.duration,
                                 width: row.width, height: row.height, transcript: row.transcript });
        }).catch(function (err) {
            // keep it: back to review, with Try Again and Download (a photo comes back as edited)
            var msg = err && err.session ? txt("SESSION_ENDED") : txt("UPLOAD_FAILED", (err && err.message) || "");
            self.items.splice(self.items.indexOf(row), 1);
            self.renderList();
            self.pendingBlob = blob;
            self.pendingSec = sec;
            self.reviewText.value = transcript;
            self.failed = true;
            if (photo) {
                self.pendingName = name;
                self.edLoad(blob).then(function () { self.failed = true; self.showReview(); self.say(msg, "error"); });
            } else {
                self.showReview();
                self.say(msg, "error");
            }
            self.fire("error", { reason: err && err.session ? "session" : "upload", message: err && err.message });
        });
    };

    Recorder.prototype.call = function (data) {
        var ajax = this.cfg.ajax;
        return new Promise(function (resolve, reject) {
            apex.server.plugin(ajax, data, { dataType: "json" }).then(function (res) {
                if (res && res.error) {
                    var e = new Error(res.error);
                    e.session = /session/i.test(res.error) && /(expired|ended|invalid|timed? ?out)/i.test(res.error);
                    reject(e);
                } else {
                    resolve(res || {});
                }
            }, function (xhr, status, err) {
                var msg = (xhr && xhr.responseJSON && xhr.responseJSON.error) || (xhr && xhr.status === 0 ? txt("NETWORK") : err || status || txt("NETWORK")),
                    e = new Error(msg);
                // an expired session answers with a sign-in page (not JSON) or 401 / 403
                e.session = !!xhr && (xhr.status === 401 || xhr.status === 403 ||
                    (status === "parsererror" && /<html|login|sign.?in/i.test(xhr.responseText || "")) || /session/i.test(msg));
                reject(e);
            });
        });
    };

    Recorder.prototype.upload = function (blob, row) {
        var self = this, tok = token(), parts = Math.max(1, Math.ceil(blob.size / PART_BYTES)), next = 0, done = 0;
        var worker = function () {
            if (next >= parts) { return Promise.resolve(); }
            var i = next++;
            return readBase64(blob.slice(i * PART_BYTES, Math.min(blob.size, (i + 1) * PART_BYTES))).then(function (b64) {
                var f01 = [];
                for (var p = 0; p < b64.length; p += PIECE_CHARS) { f01.push(b64.substr(p, PIECE_CHARS)); }
                return self.call({ x01: "PART", x02: tok, x03: i, f01: f01 });
            }).then(function () {
                done++;
                row.uploading = Math.round(done / parts * 100);
                self.renderProgress(row);
                return worker();
            });
        };
        var pool = [];
        for (var w = 0; w < Math.min(PARALLEL, parts); w++) { pool.push(worker()); }
        return Promise.all(pool).then(function () {
            return self.call({ x01: "FINISH", x02: tok, x04: parts,
                x05: self.items.filter(function (r) { return r.seq; }).map(function (r) { return r.seq; }).join(":"),
                x06: self.lang,
                x03: JSON.stringify({ name: row.name, mime: row.mime, duration: row.duration ? Math.round(row.duration * 10) / 10 : null,
                                      width: row.width || null, height: row.height || null, transcript: row.transcript || null }) });
        });
    };

    // value, and the Transcript Item: the transcripts are only rewritten while the user has not edited them;
    // after an edit, a new transcript is added at the end and nothing is taken away
    Recorder.prototype.writeValue = function (before, added) {
        var v = this.items.filter(function (r) { return r.seq; }).map(function (r) { return r.seq; }).join(":");
        if (this.input.value !== v) {
            this.input.value = v;
            $(this.input).trigger("change");
        }
        var ti = this.cfg.transcriptItem && apex.item(this.cfg.transcriptItem);
        if (ti && ti.node) {
            var cur = String(ti.getValue() || ""), now = this.joined();
            if (cur.trim() === String(before || "").trim()) {
                ti.setValue(now);
            } else if (added && added.transcript) {
                ti.setValue(cur.replace(/\s+$/, "") + (cur.trim() ? "\n\n" : "") + added.transcript);
            }
        }
    };

    // ---------------------------------------------------------------- list of recordings
    Recorder.prototype.mediaUrl = function (r) {
        if (r.blob) {
            if (!r.url) { r.url = URL.createObjectURL(r.blob); }
            return Promise.resolve(r.url);
        }
        if (r.url) { return Promise.resolve(r.url); }
        // fetch the whole file once: Safari cannot stream media without byte ranges
        var src = apex.server.pluginUrl(this.cfg.ajax, r.row ? { x01: "SAVED", x02: r.row } : { x01: "GET", x02: r.seq });
        return fetch(src, { credentials: "same-origin" }).then(function (res) {
            if (!res.ok) { throw new Error(res.status + " " + res.statusText); }
            return res.blob();
        }).then(function (b) {
            r.url = URL.createObjectURL(b.type ? b : new Blob([b], { type: r.mime || "" }));
            return r.url;
        });
    };

    Recorder.prototype.renderProgress = function (r) {
        if (!r.li) { return; }
        var bar = r.li.querySelector(".mplus-row-progress span"), meta = r.li.querySelector(".mplus-row-meta");
        if (bar) { bar.style.width = (r.uploading || 0) + "%"; }
        if (meta) { meta.textContent = r.uploading >= 100 && this.cfg.transcription === "SERVER" && r.kind === "AUDIO" ? txt("TRANSCRIBING_SERVER") + "..." : txt("UPLOAD_PROGRESS", r.uploading || 0); }
    };

    Recorder.prototype.renderList = function () {
        var self = this, ro = this.cfg.readOnly || this.disabled,
            rows = this.saved.map(function (s) { s.isSaved = true; s.kind = s.kind || kindOf(s.mime); return s; }).concat(this.items);
        this.list.innerHTML = "";
        rows.forEach(function (r, idx) {
            var video = r.kind === "VIDEO", image = r.kind === "IMAGE",
                name = r.name || (txt(r.kind || "AUDIO") + " " + (idx + 1)),
                meta = [r.duration ? fmtTime(r.duration) : null, r.width && r.height ? txt("PHOTO_META", r.width, r.height) : null,
                        r.size ? fmtBytes(r.size) : null].filter(Boolean).join(" · "),
                uploading = r.uploading !== undefined && r.uploading !== null,
                ico = el("span", "mplus-row-ico", { "aria-hidden": "true" }, [el("span", "fa " + (image ? "fa-camera" : video ? "fa-video-camera" : "fa-microphone"))]),
                bPlay = image ? iconButton("mplus-r-play", "fa-eye", txt("VIEW")) : iconButton("mplus-r-play", "fa-play", txt("PLAY")),
                bDel = iconButton("mplus-r-del", "fa-trash-o", txt("DELETE")),
                aDown = el("a", "t-Button t-Button--small t-Button--noUI t-Button--noLabel t-Button--icon mplus-r-down",
                           { href: "#", title: txt("DOWNLOAD"), "aria-label": txt("DOWNLOAD"), download: name }, [faIcon("fa-download")]),
                player = el("div", "mplus-row-player", { hidden: true }),
                li = el("li", "mplus-row" + (uploading ? " is-uploading" : "") + (image ? " mplus-row--image" : ""), null, [
                    ico,
                    el("div", "mplus-row-main", null, [
                        el("span", "mplus-row-name", { text: name, title: name }),
                        el("span", "mplus-row-meta", { text: meta }),
                        r.isSaved ? el("span", "mplus-tag mplus-tag--saved", { text: txt("SAVED") }) : (r.seq && !ro ? el("span", "mplus-tag", { text: txt("PENDING") }) : null),
                        uploading ? el("span", "mplus-row-progress", null, [el("span")]) : null
                    ]),
                    el("span", "mplus-row-btns", null, [
                        r.seq || r.row ? bPlay : null,
                        (r.seq || r.row) && self.has("download") ? aDown : null,
                        r.seq && !r.isSaved && !ro ? bDel : null
                    ]),
                    r.transcript ? el("div", "mplus-row-text", { text: r.transcript, title: r.transcript }) : null,
                    player
                ]);
            r.li = li;
            // a photo added on this page shows its thumbnail at once
            if (image && (r.blob || r.url)) {
                self.mediaUrl(r).then(function (u) { ico.innerHTML = ""; ico.appendChild(el("img", "mplus-row-thumb", { src: u, alt: "" })); });
            }
            bPlay.addEventListener("click", function () { self.togglePlay(r, bPlay, player); });
            aDown.addEventListener("click", function (e) {
                if (aDown.getAttribute("href") !== "#") { return; }
                e.preventDefault();
                self.mediaUrl(r).then(function (u) { aDown.href = u; aDown.click(); });
            });
            bDel.addEventListener("click", function () { self.remove(r); });
            self.list.appendChild(li);
            if (uploading) { self.renderProgress(r); }
        });
        show(this.list, rows.length > 0);
    };

    Recorder.prototype.togglePlay = function (r, b, box) {
        var self = this, image = r.kind === "IMAGE", setIcon = function (icon, label) {
            b.querySelector(".t-Icon").className = "t-Icon fa " + icon;
            b.title = label;
            b.setAttribute("aria-label", label);
        };
        if (!box.hidden) {
            var old = box.querySelector("audio,video");
            if (old) { old.pause(); }
            box.hidden = true;
            box.innerHTML = "";
            setIcon(image ? "fa-eye" : "fa-play", image ? txt("VIEW") : txt("PLAY"));
            return;
        }
        b.disabled = true;
        this.mediaUrl(r).then(function (u) {
            var video = r.kind === "VIDEO", m;
            box.innerHTML = "";
            if (image) {
                m = el("img", "mplus-photo", { src: u, alt: r.name || "" });
                box.appendChild(m);
                var thumb = r.li && r.li.querySelector(".mplus-row-ico");
                if (thumb && !thumb.querySelector("img")) { thumb.innerHTML = ""; thumb.appendChild(el("img", "mplus-row-thumb", { src: u, alt: "" })); }
            } else {
                m = el(video ? "video" : "audio", "mplus-media", { controls: true, playsinline: video ? true : null, preload: "metadata" });
                m.addEventListener("play", function () { audioSession("playback"); });
                fixDuration(m);
                m.src = u;
                box.appendChild(m);
                m.play().catch(function () { /* user can press play */ });
            }
            box.hidden = false;
            setIcon("fa-chevron-up", image ? txt("HIDE") : txt("HIDE_PLAYER"));
        }).catch(function (e) {
            self.say(txt("PLAY_FAILED", e.message), "error");
        }).finally(function () { b.disabled = false; });
    };

    Recorder.prototype.remove = function (r) {
        var self = this,
            go = function () {
                self.call({ x01: "DELETE", x02: r.seq }).then(function () {
                    var before = self.joined();
                    if (r.url) { URL.revokeObjectURL(r.url); }
                    self.items.splice(self.items.indexOf(r), 1);
                    self.renderList();
                    self.writeValue(before, null);
                    self.sync();
                    self.focusNext();
                    self.fire("delete", { seq: r.seq, name: r.name });
                }).catch(function (e) { self.say(e.session ? txt("SESSION_ENDED") : e.message, "error"); });
            };
        if (this.has("confirmDelete")) {
            apex.message.confirm(txt("CONFIRM_DELETE"), function (ok) { if (ok) { go(); } });
        } else {
            go();
        }
    };

    // value set from outside (e.g. Set Value / Clear): keep only the recordings still named in it
    Recorder.prototype.setValue = function (v) {
        var keep = String(v || "").split(":");
        this.items = this.items.filter(function (r) { return r.seq && keep.indexOf(String(r.seq)) >= 0; });
        this.input.value = this.items.map(function (r) { return r.seq; }).join(":");
        this.renderList();
        this.sync();
    };

    Recorder.prototype.busy = function () {
        return ["opening", "countdown", "recording", "paused", "stopping", "review", "uploading"].indexOf(this.state) >= 0;
    };

    Recorder.prototype.setDisabled = function (d) {
        this.disabled = !!d;
        if (d && this.busy() && this.state !== "uploading") {
            if (this.rec) { this.rec.onstop = null; try { this.rec.stop(); } catch (e) { /* stopped */ } this.rec = null; }
            clearInterval(this.tick);
            clearInterval(this.cdTimer);
            this.cancelled = true;
            this.sttAbort();
            this.release();
            this.clearReview();
            this.state = "idle";
        }
        this.renderList();
        this.sync();
    };

    // ---------------------------------------------------------------- public
    function init(cfg, initFn) {
        if (typeof initFn === "function") { cfg = initFn(cfg) || cfg; }
        if (cfg.texts) { $.extend(TEXT, cfg.texts); }
        var rec = new Recorder(cfg), input = rec.input;
        instances[cfg.item] = rec;
        rec.root.setAttribute("data-state", "idle");

        apex.item.create(cfg.item, {
            getValue: function () { return input.value; },
            setValue: function (v) { rec.setValue(v); },
            isChanged: function () { return input.value !== rec.initial || rec.busy(); },
            enable: function () { rec.setDisabled(false); },
            disable: function () { rec.setDisabled(true); },
            isDisabled: function () { return rec.disabled; },
            setFocusTo: function () { return $(rec.root).find("button:visible:enabled").first(); },
            displayValueFor: function () { return rec.items.map(function (r) { return r.name; }).join(", "); }
        });
    }

    // A recording that is still running or not used yet blocks the page submit - except for the requests
    // listed in "Allow Submit for Requests" (e.g. CANCEL, DELETE), which drop the unfinished recording.
    $(document).on("apexbeforepagesubmit", function (e, request) {
        Object.keys(instances).forEach(function (k) {
            var r = instances[k], allowed = String(r.cfg.allowRequests || "").toUpperCase().split(/[\s,:]+/);
            if (!document.body.contains(r.root) || !r.busy()) { return; }
            if (request && allowed.indexOf(String(request).toUpperCase()) >= 0) {
                // the IndexedDB delete may not finish before the page unloads: leave a note for the next load too
                try { sessionStorage.setItem("mplus-nodraft:" + r.draftKey, "1"); } catch (x) { /* no storage */ }
                r.dropDraft();
                return;
            }
            apex.event.gCancelFlag = true;
            r.say(txt("BUSY"), "warn");
            apex.message.clearErrors();
            apex.message.showErrors([{ type: "error", location: "page", message: (r.cfg.label ? r.cfg.label + ": " : "") + txt("BUSY"), unsafe: false }]);
        });
    });

    return {
        version: VERSION,
        init: init,
        presets: PRESETS,
        texts: TEXT,
        fixWebm: fixWebm,
        fixMp4: fixMp4,
        get: function (item) {
            var r = instances[item];
            return r && {
                start: function () { r.start(); },
                pause: function () { r.pause(); },
                resume: function () { r.resume(); },
                stop: function () { r.stop(); },
                capture: function () { r.capture(); },
                kind: function (k) { if (k) { r.setKind(k); } return r.kind; },
                use: function () { r.accept(); },
                discard: function () { r.discard(false); },
                state: function () { return r.state; },
                isBusy: function () { return r.busy(); },
                recordings: function () {
                    return r.items.map(function (x) {
                        return { seq: x.seq, name: x.name, mimeType: x.mime, kind: x.kind, bytes: x.size, seconds: x.duration,
                                 width: x.width, height: x.height, transcript: x.transcript };
                    });
                }
            };
        }
    };
})(apex.jQuery);
