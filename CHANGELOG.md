# Changelog

## 2.0.0 (2026-11-01)

First public release on GitHub, internal name `COM.HASHAAM.MEDIAPLUS`. Successor of Media Recorder 1.x (`COM.HASHAAM.MEDIA_RECORDER`, never published): import MediaPlus, switch the items to it and set Mode again.

- **Photos.** Mode is now Audio, Video and Photo in any combination. Take a photo with the camera or choose a file, then crop (free or a fixed 1:1, 4:3, 3:4, 16:9, 9:16), rotate, flip, adjust brightness, contrast and colour, black and white, draw in four colours with Undo, and choose the size. Saved as JPEG, WebP or PNG, compressed until it fits the Maximum File Size, EXIF data (location) removed. Settings: Image Format, Image Quality, Maximum Photo Size, Editing Tools, Crop Shape. N003 / N004 hold the width and height.
- **MP4 and M4A everywhere.** File Format Automatic records video as MP4 and audio as M4A (AAC), which open on iPhones, Macs, Windows Media Player and Android; Smallest (WebM) stays available. No browser can record MP3.
- **MP4 repair.** Chrome and Edge write fragmented MP4 with a length of 0 in longer recordings, so Windows Media Player could not seek; Safari's MP4 is fragmented too. Every MP4 is rewritten as a regular file (sample tables, keyframes, correct durations, standard track flags). If a browser cannot play the repaired file, the review uses the recording as the browser wrote it.
- **iPhone.** Audio Session API: after recording, playback goes back to the loudspeaker (the review player was silent). The audio level meter starts only once the microphone is open. Cameras are counted again after permission, so Switch Camera shows on iPhones.
- **No-sound warning** when nothing reaches the recording for 3.5 seconds or the system mutes the microphone (headsets, calls).
- **Waveform** on a decibel scale, so speech moves it clearly.
- **Transcription** in English (US) and / or Arabic.
- Echo Cancellation is off by default (it gives phone-call quality on iPhones); AAC gets at least 96 kbps.
- Renamed: JavaScript `mediaPlus`, CSS `mplus-`, text messages `MEDIAPLUS.<KEY>`, default collection `MEDIAPLUS`, events Recording Started ... Photo Taken, Media Saved, Media Discarded, Media Deleted, Media Error; Maximum Recordings is Maximum Files, Saved Recordings Query is Saved Files Query.

## 1.2.0 (2026-11-01, as Media Recorder)

- The server checks every limit again: size, number of recordings, Mode and the file content (magic bytes); at most 3 uploads at a time.
- Drafts in IndexedDB: a recording not used yet survives a reload, a crash or a lost connection; failed uploads offer Try Again and Download; an expired session is detected.
- Transcription = Server: your own PL/SQL (OCI Speech, Azure, Whisper ...) with `:COLLECTION_NAME`, `:SEQ_ID`, `:MIME_TYPE`, `:LANGUAGE`, `:TRANSCRIPT`.
- Allow Submit for Requests, Button Style (Rounded / Theme), keyboard (P / S), screen-reader notices, compact one-line voice-note bar, optional `db/mediaplus_pkg.sql`.

## 1.1.0 (2026-10-29, as Media Recorder)

- Pill controls with drawn icons; controls shown at once after Record.
- WebM repair (Duration, sized clusters, SeekHead, Cues), so recordings seek in VLC.
- Live transcription with the browser's speech recognition; Transcript Item.

## 1.0.0 (2026-10-29, as Media Recorder)

- Audio, video or both; record, pause, resume, stop, review; size and length limits with warning and automatic stop; quality presets; several recordings per item; APEX collection storage; chunked upload; Saved Recordings Query; dynamic action events.
