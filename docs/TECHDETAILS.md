## 🔧 Technical Details

### Supported Framerates

| Framerate | Type | Drop-Frame | Common Usage |
|-----------|------|------------|--------------|
| 23.976 fps | NTSC Film | Yes (`;`) | Film transferred to NTSC |
| 24.000 fps | Film | No (`:`) | Cinema, digital film |
| 25.000 fps | PAL | No (`:`) | European broadcast |
| 29.97 fps | NTSC | Yes (`;`) | North American SD broadcast |
| 30.000 fps | NTSC Progressive | No (`:`) | Progressive scan NTSC |
| 50.000 fps | PAL Progressive | No (`:`) | European HD broadcast |
| 59.94 fps | NTSC HD | Yes (`;`) | North American HD broadcast |
| 60.000 fps | Progressive HD | No (`:`) | High framerate progressive |
| 119.88 fps | HFR NTSC | Yes (`;`) | High framerate NTSC-derived |
| 120.00 fps | HFR Progressive | No (`:`) | High framerate progressive |

**Note:** Drop-frame timecode "drops" frame **numbers** (not actual frames) at the start of each minute except every 10th minute. This keeps timecode synchronised with real clock time for NTSC framerates.

### Audio Format Compatibility

| Format | Channel Routing | Loudness Normalisation | Notes |
|--------|----------------|------------------------|-------|
| PCM (WAV/AIF) | ✅ Full support | ✅ Full support | Recommended for QC work |
| AAC (Multi-channel) | ✅ Full support | ✅ Full support | Common in MP4/MOV containers |
| FLAC (Multi-channel) | ✅ Full support | ✅ Full support | Lossless compression |
| AC3/E-AC3 | ⚠️ Limited | ✅ Full support | Use default downmix for routing |
| DTS | ⚠️ Limited | ✅ Full support | Use default downmix for routing |
| Opus | ✅ Full support | ✅ Full support | Modern codec support |

**Recommendation:** For maximum compatibility with channel routing features, use uncompressed PCM or losslessly compressed FLAC audio.

### Loudness Standards Compliance

This suite implements industry-standard loudness normalisation:

| Standard | Target | True Peak | Region | Application |
|----------|--------|-----------|--------|-------------|
| EBU R128 | -23 LUFS | -1 dBTP | Europe, International | Broadcast television, cinema |
| ATSC A/85 | -24 LKFS | -2 dBTP | North America | Broadcast television (CALM Act) |
| AES Streaming | -16 LUFS | -1 dBTP | Global | Podcast, streaming platforms |

**Implementation:** Uses FFmpeg's `loudnorm` filter with linear mode for transparent, broadcast-compliant normalisation. Processing adds minimal latency suitable for real-time monitoring.
