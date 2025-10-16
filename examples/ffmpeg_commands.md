# FFmpeg Commands — Broadcast Cheatsheet

> Curated, field-tested invocations for QC, mezzanine exports, loudness, and routing. Assumes 48 kHz PCM unless noted.

---

## 1) Mezzanine masters (editing-friendly)

### ProRes 422 HQ (Rec.709, timecode tag)
ffmpeg -i input.mov \
  -c:v prores_ks -profile:v 3 -pix_fmt yuv422p10le \
  -color_primaries bt709 -color_trc bt709 -colorspace bt709 \
  -movflags +write_colr \
  -timecode 01:00:00:00 \
  -c:a pcm_s24le -ar 48000 \
  output_prores422hq_rec709_tc.mov

### DNxHD 185 (1080i50, MXF OP1a, PCM 24-bit)
ffmpeg -i input.mov \
  -c:v dnxhd -profile:v dnxhd -b:v 185M -pix_fmt yuv422p \
  -flags +ildct+ilme -r 25 -s 1920x1080 -aspect 16:9 \
  -c:a pcm_s24le -ar 48000 \
  -f mxf_op1a output_dnxhd185_1080i50.mxf

### DNxHR HQX (UHD progressive mezzanine)
ffmpeg -i input.mov \
  -c:v dnxhr -profile:v dnxhr_hqx -pix_fmt yuv422p10le \
  -c:a pcm_s24le -ar 48000 \
  -f mxf_op1a output_dnxhr_hqx_2160p25.mxf

---

## 2) Timecode (DF/NDF) tagging

### MOV timecode (NDF example)
ffmpeg -i input.mov -c copy -timecode 10:00:00:00 output_tc.mov

### NTSC Drop-Frame (29.97) in MOV
# DF uses semicolons in display; ffmpeg takes SMPTE string:
ffmpeg -i input.mov -c copy -timecode 01:00:00;00 output_tc_df.mov

### MXF start timecode (OP1a, PAL example)
ffmpeg -i input.mov -c:v dnxhd -b:v 120M -r 25 \
  -c:a pcm_s24le -ar 48000 \
  -timecode 10:00:00:00 \
  -f mxf_op1a output_tc_1080i50.mxf

---

## 3) Loudness (R128 / A/85) — measure & normalise

### Measure only (EBU R128; print integrated, LRA, TP)
ffmpeg -nostats -i input.wav -filter:a ebur128 -f null - 2> loudness_report.txt

### Two-pass loudnorm (transparent) to −23 LUFS / −1 dBTP
# Pass 1 (measure):
ffmpeg -i input.wav -filter:a loudnorm=I=-23:TP=-1:LRA=7:print_format=json -f null - 2> loud.json
# Extract measured values (I, LRA, TP, thresh) and feed into pass 2:
ffmpeg -i input.wav -filter:a loudnorm=I=-23:TP=-1:LRA=7:measured_I=MEAS_I:measured_LRA=MEAS_LRA:measured_TP=MEAS_TP:measured_thresh=MEAS_TH:offset=MEAS_OFF:linear=true:print_format=summary -c:a pcm_s24le output_r128.wav

### Single-pass “monitoring normalise” (low-latency)
ffmpeg -i input.wav -filter:a loudnorm=I=-23:TP=-1:LRA=7:linear=true -f wav - | play -

---

## 4) Channel routing / solo / pair monitoring

### Route CH1+CH2 (stereo pair) from a 16-ch input
ffmpeg -i input_16ch.wav -filter_complex "[0:a]pan=stereo|c0=c0|c1=c1[aout]" -map "[aout]" out_1-2.wav

### Solo CH5 to dual-mono (L/R both = CH5)
ffmpeg -i input_16ch.wav -filter_complex "[0:a]pan=stereo|c0=c4|c1=c4[a]" -map "[a]" out_ch5_mono2st.wav

### Fold all 16 to stereo with RMS-oriented weights (clipping-safe headroom)
ffmpeg -i input_16ch.wav -filter_complex "[0:a]pan=stereo|c0=(c0+c2+c4+c6+c8+c10+c12+c14)/4|c1=(c1+c3+c5+c7+c9+c11+c13+c15)/4[a]" -map "[a]" out_sum.wav -af dynaudnorm

---

## 5) Network ingest/monitor (UDP multicast, low latency)

### Sender (H.264 in MPEG-TS, ultrafast, zerolatency)
ffmpeg -re -i input.mp4 -c:v libx264 -preset ultrafast -tune zerolatency -x264-params "keyint=60:min-keyint=60:scenecut=0" \
  -c:a aac -ar 48000 -b:a 192k \
  -f mpegts "udp://239.1.1.1:5000?pkt_size=1316&ttl=16&overrun_nonfatal=1"

### mpv receive (example)
mpv "udp://239.1.1.1:5000?timeout=1000000&fifo_size=1048576" --profile=qc-realtime

---

## 6) Still frames / QC grabs

### Exact frame PNG (no OSD)
ffmpeg -ss 00:01:23.456 -i input.mov -frames:v 1 -map 0:v:0 -an -sn -c:v png qc_0123456.png

### Every X frames (e.g., every 50th) as PNG sequence
ffmpeg -i input.mov -vf "select=not(mod(n\,50)),setpts=N/FRAME_RATE/TB" -vsync vfr frame_%06d.png

---

## 7) Colour signalling (Rec.709 tagging & convert)

### Tag as Rec.709 (no matrix change; set flags)
ffmpeg -i input.mov -c:v copy \
  -color_primaries bt709 -color_trc bt709 -colorspace bt709 \
  -movflags +write_colr \
  -c:a copy output_tagged_rec709.mov

### Convert full-range 709 → legal range 709 (studio levels)
ffmpeg -i input.mov -vf "scale=in_range=full:out_range=tv,format=yuv420p" -c:v prores_ks -profile:v 3 -c:a copy output_legal.mov

---

## 8) Interlace tools (inspection & deinterlace)

### Detect field order / interlace cadence (idet)
ffmpeg -i input.mxf -filter:v idet -frames:v 500 -an -f rawvideo -y /dev/null 2> idet_report.txt

### YADIF (double-rate deinterlace 50i→50p)
ffmpeg -i input_1080i50.mxf -vf "yadif=1:1:0" -r 50 -c:v prores_ks -profile:v 3 -c:a copy output_1080p50.mov
