# Suno AI Integration Guide

Complete guide for extracting lyrics and automating music distribution from Suno AI.

---

## Overview

Suno AI is an AI music generation platform that creates complete songs with lyrics. This integration automatically extracts lyrics from Suno pages and streamlines the distribution process.

**What You Can Automate:**
- ✅ Lyrics extraction from Suno.com pages
- ✅ Audio download (manual step)
- ✅ Format conversion (MP3 → WAV)
- ✅ Lyrics embedding in audio files
- ✅ Mastering with eMastered
- ✅ Distribution to streaming platforms
- ✅ Social media posting

---

## Quick Start

### **Complete Workflow (One Command)**

```bash
chmod +x suno-complete-workflow.sh

./suno-complete-workflow.sh \
  "https://suno.com/song/c0117fdc-ff4c-41e5-b623-9e6be9e3ceae" \
  "Artist Name" \
  "Song Title" \
  "2025-01-15"
```

This will:
1. Extract lyrics automatically
2. Prompt you to download audio
3. Convert to WAV
4. Master with eMastered (if configured)
5. Embed lyrics
6. Prepare for distribution

---

## Lyrics Extraction

### **Method 1: Automatic Extraction (Recommended)**

**Requirements:**
```bash
npm install playwright
npx playwright install chromium
```

**Extract Lyrics:**
```bash
node extract-suno-lyrics.js \
  "https://suno.com/song/c0117fdc-ff4c-41e5-b623-9e6be9e3ceae"
```

**Output:**
- `Song_Title_lyrics.txt` - Lyrics file
- `Song_Title_metadata.json` - Song metadata

**With Custom Filename:**
```bash
node extract-suno-lyrics.js \
  "https://suno.com/song/abc123" \
  "my_song_lyrics.txt"
```

---

### **Method 2: Manual Copy-Paste**

1. Open Suno song page
2. Scroll to lyrics section
3. Copy lyrics
4. Save to `lyrics.txt`

**Format:**
```
Verse 1:
Walking down the street at midnight
City lights are shining bright

Chorus:
We're dancing in the moonlight
Nothing's gonna stop us now
```

---

## Complete Workflows

### **Workflow 1: Suno → DistroKid (Full Automation)**

```bash
#!/bin/bash

# 1. Extract lyrics
node extract-suno-lyrics.js \
  "https://suno.com/song/abc123" \
  "lyrics.txt"

# 2. Download audio from Suno (manual)
# Save as: suno_audio.mp3

# 3. Complete workflow
./suno-complete-workflow.sh \
  "https://suno.com/song/abc123" \
  "My Artist" \
  "My Song" \
  "2025-01-15"
```

---

### **Workflow 2: Suno → eMastered → Distribution**

```bash
# Environment setup
export EMASTERED_EMAIL="your@email.com"
export EMASTERED_PASSWORD="password"
export N8N_WEBHOOK_URL="https://your-n8n.com/webhook"

# Extract lyrics
SUNO_URL="https://suno.com/song/abc123"
node extract-suno-lyrics.js "$SUNO_URL" "lyrics.txt"

# Download audio manually from Suno
# Save as: suno_audio.mp3

# Convert to WAV
ffmpeg -i suno_audio.mp3 -ar 44100 suno_audio.wav

# Master with eMastered + embed lyrics
./emastered-workflow.sh \
  "suno_audio.wav" \
  "Artist Name" \
  "Song Title" \
  "2025-01-15" \
  "" \
  "lyrics.txt"

# Result: Mastered file with embedded lyrics ready for distribution
```

---

### **Workflow 3: Quick Distribution (Pre-Mastered)**

If Suno audio quality is good enough (it usually is):

```bash
# Extract lyrics
node extract-suno-lyrics.js \
  "https://suno.com/song/abc123" \
  "lyrics.txt"

# Download from Suno → suno_audio.mp3

# Convert to WAV
ffmpeg -i suno_audio.mp3 -ar 44100 suno_audio.wav

# Embed lyrics
python3 add-lyrics.py suno_audio.wav lyrics.txt

# Distribute
./distribute-premastered.sh \
  "suno_audio.wav" \
  "Artist" \
  "Song" \
  "https://hyperfollow.com/link" \
  "2025-01-15" \
  "New AI-generated track!" \
  "lyrics.txt"
```

---

## Lyrics Extraction Details

### **What Gets Extracted**

The script extracts:
- ✅ **Lyrics** (complete song text)
- ✅ **Song title**
- ✅ **Artist/creator** (if available)
- ✅ **Tags/genre** (if available)
- ✅ **Creation date** (if available)

### **How It Works**

1. Opens Suno page with Playwright
2. Waits for page to load
3. Searches for lyrics using multiple selectors:
   - `[class*="lyrics"]`
   - `pre` tags
   - `.song-lyrics`
   - JSON embedded data
4. Extracts and cleans lyrics
5. Saves as `.txt` and `.json`

### **Supported Suno URLs**

```
✅ https://suno.com/song/c0117fdc-ff4c-41e5-b623-9e6be9e3ceae
✅ https://www.suno.com/song/abc123
✅ https://suno.ai/song/xyz789
```

---

## Audio Download

### **Manual Download (Current Method)**

1. Go to Suno song page
2. Click download button (⬇️)
3. Save MP3 file

**Note:** Suno doesn't currently provide an API for automated downloads.

### **Bulk Download**

For multiple songs:

```bash
#!/bin/bash
# bulk-suno-download.sh

SUNO_URLS=(
  "https://suno.com/song/abc123"
  "https://suno.com/song/def456"
  "https://suno.com/song/ghi789"
)

for URL in "${SUNO_URLS[@]}"; do
  echo "Processing: $URL"

  # Extract lyrics
  node extract-suno-lyrics.js "$URL"

  echo "Please download audio from: $URL"
  read -p "Press Enter when done..."

  echo "---"
done
```

---

## Format Conversion

### **MP3 to WAV**

```bash
# Standard conversion
ffmpeg -i suno_audio.mp3 -ar 44100 -sample_fmt s16 output.wav

# High quality (24-bit)
ffmpeg -i suno_audio.mp3 -ar 48000 -sample_fmt s24 output.wav

# Batch conversion
for file in *.mp3; do
  ffmpeg -i "$file" -ar 44100 "${file%.mp3}.wav"
done
```

---

## Metadata Extraction

### **JSON Metadata File**

The extraction script creates a JSON file with all metadata:

```json
{
  "url": "https://suno.com/song/abc123",
  "title": "Dancing in the Moonlight",
  "lyrics": "Verse 1:\nWalking down...",
  "artist": "AI Artist",
  "tags": ["electronic", "upbeat", "dance"],
  "created": "2025-01-15",
  "extractedAt": "2025-01-15T10:30:00.000Z"
}
```

**Use Metadata:**

```bash
# Extract title from JSON
TITLE=$(jq -r '.title' metadata.json)

# Extract artist
ARTIST=$(jq -r '.artist' metadata.json)

# Use in workflow
./distribute-premastered.sh \
  "audio.wav" \
  "$ARTIST" \
  "$TITLE" \
  ...
```

---

## Integration with Album Wizard

Update the wizard to support Suno URLs:

**New Field in Step 1:**
```html
<div class="form-group">
  <label for="sunoUrl">Suno Song URL <span class="label-optional">(Optional)</span></label>
  <input type="url" id="sunoUrl" placeholder="https://suno.com/song/...">
  <button onclick="extractSunoData()">Extract Lyrics & Metadata</button>
</div>
```

**JavaScript:**
```javascript
async function extractSunoData() {
  const sunoUrl = document.getElementById('sunoUrl').value;

  if (!sunoUrl) return;

  // Call extraction endpoint
  const response = await fetch('/extract-suno', {
    method: 'POST',
    body: JSON.stringify({ url: sunoUrl })
  });

  const data = await response.json();

  // Auto-fill form
  document.getElementById('lyrics').value = data.lyrics;
  document.getElementById('songTitle').value = data.title;
  // ... etc
}
```

---

## Troubleshooting

### **Lyrics Extraction Fails**

**Problem:** Script can't find lyrics

**Solutions:**
1. Check if song page loads in browser
2. Verify song is publicly accessible
3. Suno may have changed page structure
4. Try manual copy-paste method

**Debug Mode:**
```bash
node extract-suno-lyrics.js "$URL" --debug
# Creates screenshot: suno-page-debug.png
```

---

### **Audio Quality Issues**

**Suno Audio Specs:**
- Format: MP3 (320kbps typically)
- Sample Rate: 44.1 kHz
- Channels: Stereo
- Duration: Usually 2-4 minutes

**Quality is usually good enough** for streaming platforms without additional mastering.

**If you want to master anyway:**
- Use eMastered for AI mastering
- Use GitHub Actions for basic normalization
- Professional mastering for important releases

---

### **Character Encoding**

If lyrics have special characters:

```bash
# Check encoding
file -i lyrics.txt

# Convert to UTF-8
iconv -f ISO-8859-1 -t UTF-8 lyrics.txt > lyrics_utf8.txt
```

---

## Best Practices

### **1. Verify Lyrics**

Always review extracted lyrics:
- Check for formatting
- Fix any extraction errors
- Add section labels if missing

### **2. Audio Quality**

Suno audio is usually well-mastered, but:
- Check LUFS levels
- Verify no clipping
- Listen for artifacts

### **3. Metadata**

Use consistent naming:
```
Artist_Name_-_Song_Title_lyrics.txt
Artist_Name_-_Song_Title.wav
```

### **4. Backup Originals**

Keep original Suno files:
```bash
mkdir -p originals
cp suno_audio.mp3 originals/
cp lyrics.txt originals/
```

---

## Advanced Usage

### **Batch Processing**

Process multiple Suno songs:

```bash
#!/bin/bash
# batch-suno-process.sh

# List of Suno URLs
URLS=(
  "https://suno.com/song/abc123"
  "https://suno.com/song/def456"
)

for URL in "${URLS[@]}"; do
  # Extract metadata
  METADATA=$(node extract-suno-lyrics.js "$URL")

  # Get title from filename
  LYRICS_FILE=$(ls -t *_lyrics.txt | head -1)

  echo "Processed: $LYRICS_FILE"
  echo "---"
done
```

---

### **Custom Lyrics Format**

Transform extracted lyrics:

```python
#!/usr/bin/env python3
# format-lyrics.py

import sys

with open(sys.argv[1], 'r') as f:
    lyrics = f.read()

# Add timestamps (example)
lines = lyrics.split('\n')
formatted = []

time = 0
for line in lines:
    if line.strip():
        formatted.append(f"[{time//60:02d}:{time%60:02d}.00]{line}")
        time += 4  # Assume 4 seconds per line

output = '\n'.join(formatted)

with open(sys.argv[1].replace('.txt', '.lrc'), 'w') as f:
    f.write(output)
```

---

## Example: Complete Release

```bash
#!/bin/bash
# complete-suno-release.sh

# Configuration
SUNO_URL="https://suno.com/song/abc123"
ARTIST="AI Music Artist"
SONG="Moonlight Dance"
RELEASE_DATE="2025-01-15"

echo "🎵 Complete Suno Release Workflow"
echo "================================="

# 1. Extract lyrics
echo "Step 1: Extracting lyrics..."
node extract-suno-lyrics.js "$SUNO_URL" "lyrics.txt"

# 2. Download audio (manual)
echo ""
echo "Step 2: Please download audio from:"
echo "  $SUNO_URL"
echo ""
read -p "Save as 'suno_audio.mp3' and press Enter..."

# 3. Convert to WAV
echo ""
echo "Step 3: Converting to WAV..."
ffmpeg -i suno_audio.mp3 -ar 44100 audio.wav

# 4. Embed lyrics
echo ""
echo "Step 4: Embedding lyrics..."
python3 add-lyrics.py audio.wav lyrics.txt

# 5. Quality check
echo ""
echo "Step 5: Quality check..."
ffmpeg -i audio.wav -filter:a loudnorm=print_format=summary -f null - 2>&1 | \
  grep -E "Integrated|Peak"

# 6. Ready for distribution
echo ""
echo "Step 6: Files ready!"
echo "  Audio: audio.wav"
echo "  Lyrics: lyrics.txt"
echo ""
echo "Next: Upload to DistroKid and distribute"
```

---

## Resources

- [Suno AI](https://suno.com) - AI music generation
- [Suno Community](https://www.reddit.com/r/SunoAI/) - Tips and tricks
- [Playwright Docs](https://playwright.dev) - For automation

---

## Summary

**Suno Integration Benefits:**
- ✅ Automatic lyrics extraction
- ✅ Streamlined workflow
- ✅ Professional metadata
- ✅ Complete automation possible

**Recommended Workflow:**
```
Suno URL → Extract Lyrics → Download Audio → 
Convert to WAV → Embed Lyrics → DistroKid → 
HyperFollow → n8n → Social Media ✨
```

**Time Saved:** ~5-10 minutes per release with automation!
