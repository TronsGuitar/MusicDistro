# Adding Lyrics to Music Metadata

Complete guide for embedding lyrics in your audio files for streaming platforms.

---

## Overview

Lyrics metadata enhances your music on streaming platforms:
- ✅ **Spotify** - Scrolling lyrics display
- ✅ **Apple Music** - Time-synced lyrics
- ✅ **YouTube Music** - Lyrics panel
- ✅ **Amazon Music** - Lyrics display
- ✅ **Tidal** - Lyrics integration

---

## Lyrics Formats

### 1. **Plain Text Lyrics** (Universal)
Simple, unsynced lyrics that work everywhere.

```
Verse 1:
Walking down the street at midnight
City lights are shining bright
Looking for a sign tonight
Everything will be alright

Chorus:
We're dancing in the moonlight
Nothing's gonna stop us now
We're dancing in the moonlight
We'll show them all somehow
```

### 2. **LRC Format** (Time-Synced)
Synchronized lyrics with timestamps.

```
[00:12.00]Verse 1:
[00:14.50]Walking down the street at midnight
[00:18.00]City lights are shining bright
[00:21.50]Looking for a sign tonight
[00:25.00]Everything will be alright

[00:28.00]Chorus:
[00:29.50]We're dancing in the moonlight
[00:33.00]Nothing's gonna stop us now
[00:36.50]We're dancing in the moonlight
[00:40.00]We'll show them all somehow
```

**Format:** `[MM:SS.XX]Lyric line`

---

## Methods to Add Lyrics

### Method 1: Using Python (Mutagen)

#### Install
```bash
pip install mutagen
```

#### Script: `add-lyrics.py`

```python
#!/usr/bin/env python3
"""
Add lyrics to WAV/MP3 files
Usage: python add-lyrics.py audio.wav lyrics.txt
"""

import sys
from mutagen.wave import WAVE
from mutagen.mp3 import MP3
from mutagen.id3 import ID3, USLT

def add_lyrics_to_wav(audio_file, lyrics_file):
    """Add lyrics to WAV file"""
    try:
        audio = WAVE(audio_file)
        
        # Read lyrics
        with open(lyrics_file, 'r', encoding='utf-8') as f:
            lyrics = f.read()
        
        # Add lyrics to INFO tag
        if 'ILYRIC' not in audio:
            audio['ILYRIC'] = []
        
        audio['ILYRIC'] = [lyrics]
        audio.save()
        
        print(f"✅ Lyrics added to {audio_file}")
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def add_lyrics_to_mp3(audio_file, lyrics_file):
    """Add lyrics to MP3 file with ID3 tags"""
    try:
        # Load or create ID3 tag
        try:
            audio = ID3(audio_file)
        except:
            audio = ID3()
        
        # Read lyrics
        with open(lyrics_file, 'r', encoding='utf-8') as f:
            lyrics = f.read()
        
        # Add unsynchronized lyrics (USLT frame)
        audio.add(USLT(
            encoding=3,  # UTF-8
            lang='eng',  # Language code
            desc='',     # Description
            text=lyrics
        ))
        
        audio.save(audio_file)
        
        print(f"✅ Lyrics added to {audio_file}")
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python add-lyrics.py <audio_file> <lyrics_file>")
        print("\nExamples:")
        print("  python add-lyrics.py song.wav lyrics.txt")
        print("  python add-lyrics.py song.mp3 lyrics.lrc")
        sys.exit(1)
    
    audio_file = sys.argv[1]
    lyrics_file = sys.argv[2]
    
    if audio_file.lower().endswith('.wav'):
        add_lyrics_to_wav(audio_file, lyrics_file)
    elif audio_file.lower().endswith('.mp3'):
        add_lyrics_to_mp3(audio_file, lyrics_file)
    else:
        print("❌ Unsupported format. Use WAV or MP3.")
        sys.exit(1)
```

**Usage:**
```bash
chmod +x add-lyrics.py

# Add lyrics to WAV
python add-lyrics.py mastered.wav lyrics.txt

# Add lyrics to MP3
python add-lyrics.py mastered.mp3 lyrics.lrc
```

---

### Method 2: Using FFmpeg

#### For MP3 Files
```bash
# Embed plain text lyrics
ffmpeg -i input.mp3 -i lyrics.txt \
  -map 0 -map 1 \
  -c copy \
  -metadata:s:v:0 comment="Lyrics" \
  output.mp3

# Or use ID3v2 tags
ffmpeg -i input.mp3 \
  -metadata lyrics="$(cat lyrics.txt)" \
  -codec copy \
  output.mp3
```

#### For WAV Files
WAV files use RIFF INFO tags:
```bash
# This requires manual tag editing tools
# Use Python/Mutagen method instead (recommended)
```

---

### Method 3: Using ID3 Tag Editors

#### Kid3 (GUI - Linux/Mac/Windows)
```bash
# Install
sudo apt install kid3  # Linux
brew install kid3      # Mac

# Usage
kid3
# 1. Open your MP3 file
# 2. Go to "Lyrics" field
# 3. Paste your lyrics
# 4. Save
```

#### Mp3tag (Windows)
1. Download from https://www.mp3tag.de
2. Open your file
3. Add lyrics in "Unsynchronized lyrics" field
4. Save

#### Tag Editor (macOS)
1. Download from App Store
2. Open your file
3. Add to "Lyrics" field
4. Save

---

## Integration with MusicDistro Workflows

### Update: `distribute-premastered.sh`

Add lyrics handling:

```bash
#!/bin/bash
# Updated distribute-premastered.sh with lyrics support

# ... existing code ...

LYRICS_FILE="${6}"  # Add as optional 6th parameter

# After quality check, add lyrics if provided
if [ -n "$LYRICS_FILE" ] && [ -f "$LYRICS_FILE" ]; then
    echo ""
    echo -e "${BLUE}Adding lyrics metadata...${NC}"
    
    if command -v python3 &> /dev/null; then
        python3 add-lyrics.py "$MASTERED_FILE" "$LYRICS_FILE"
        echo -e "${GREEN}✅ Lyrics added${NC}"
    else
        echo -e "${YELLOW}⚠️  Python not found - skipping lyrics${NC}"
        echo "Install Python to add lyrics automatically"
    fi
fi
```

**Usage with lyrics:**
```bash
./distribute-premastered.sh \
  "mastered.wav" \
  "Artist Name" \
  "Song Title" \
  "https://hyperfollow.com/link" \
  "2025-01-15" \
  "lyrics.txt"
```

---

### Update: `emastered-workflow.sh`

Add lyrics parameter:

```bash
#!/bin/bash
# Updated emastered-workflow.sh with lyrics support

# Input parameters
INPUT_FILE="$1"
ARTIST_NAME="$2"
SONG_TITLE="$3"
RELEASE_DATE="${4:-$(date +%Y-%m-%d)}"
HYPERFOLLOW_LINK="${5}"
LYRICS_FILE="${6}"  # NEW

# ... after mastering step ...

# Add lyrics if provided
if [ -n "$LYRICS_FILE" ] && [ -f "$LYRICS_FILE" ]; then
    echo ""
    echo -e "${BLUE}Adding lyrics metadata...${NC}"
    python3 add-lyrics.py "$MASTERED_FILE" "$LYRICS_FILE"
    echo -e "${GREEN}✅ Lyrics embedded${NC}"
fi
```

---

### Update: Album Setup Wizard

Add lyrics field to the wizard in Step 1 (Track Details):

```html
<div class="form-group">
  <label for="lyrics">Lyrics <span class="label-optional">(Optional)</span></label>
  <textarea id="lyrics" rows="8" placeholder="Paste your lyrics here...

Verse 1:
Walking down the street...

Chorus:
We're dancing in the moonlight..."></textarea>
  <p class="help-text">
    Plain text or LRC format. Will be embedded in metadata for streaming platforms.
  </p>
</div>
```

Export lyrics as a separate file:

```javascript
function exportLyrics() {
  if (!formData.lyrics) {
    alert('No lyrics to export');
    return;
  }
  
  const blob = new Blob([formData.lyrics], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `${formData.artistName}_${formData.songTitle}_lyrics.txt`.replace(/\s+/g, '_');
  a.click();
}
```

---

## Platform-Specific Requirements

### Spotify
- **Format:** Plain text or LRC
- **Method:** Upload via Spotify for Artists dashboard
- **Note:** Cannot embed directly in audio; upload separately

### Apple Music
- **Format:** Time-synced LRC preferred
- **Method:** Upload via Apple Music for Artists
- **Note:** Supports syllable-level timing

### DistroKid
- **Upload:** Separate lyrics file during upload
- **Format:** Plain text (.txt) or LRC (.lrc)
- **Sync:** Automatically sends to platforms

### YouTube Music
- **Format:** Plain text
- **Method:** Auto-detected from metadata or manual upload
- **Display:** Lyrics panel

---

## Best Practices

### 1. **Format Lyrics Properly**
```
✅ Good:
Verse 1:
Line one
Line two

Chorus:
Line three
Line four

✗ Bad:
verse 1 line one line two chorus line three line four
```

### 2. **Include Song Structure**
- Label sections: Verse 1, Chorus, Bridge, Outro
- Add empty lines between sections
- Be consistent with formatting

### 3. **Timing for LRC**
- Use a lyrics timing tool
- Test on multiple platforms
- Keep timing slightly ahead (100-200ms)

### 4. **Character Encoding**
- Use UTF-8 encoding
- Avoid special characters that may not display
- Test international characters

### 5. **File Naming**
```bash
# Good naming convention:
Artist_Name_-_Song_Title_lyrics.txt
Artist_Name_-_Song_Title_lyrics.lrc

# Keep consistent with audio file names
```

---

## Tools for Creating Time-Synced Lyrics

### Online Tools
- **LRC Maker** - https://lrcmaker.com
- **Spotify Lyrics** - Built-in tool for artists
- **Musixmatch** - Professional lyrics timing

### Desktop Applications
- **Subtitle Edit** (Windows/Mac/Linux)
- **Aegisub** (Cross-platform)
- **LRC Editor** (Windows)

### How to Create LRC:
1. Play your track in the tool
2. Type each line of lyrics
3. Press hotkey at the moment line starts
4. Export as .lrc file

---

## Automated Lyrics from Suno

If using Suno AI, lyrics are often available:

```bash
#!/bin/bash
# extract-suno-lyrics.sh
# Extract lyrics from Suno metadata if available

SUNO_OUTPUT="$1"

# Suno often includes lyrics in metadata
# Check if lyrics are available
if [ -f "${SUNO_OUTPUT}.txt" ]; then
    echo "✅ Found Suno lyrics file"
    cp "${SUNO_OUTPUT}.txt" "lyrics.txt"
elif [ -f "${SUNO_OUTPUT}.json" ]; then
    # Extract from JSON metadata
    LYRICS=$(jq -r '.lyrics' "${SUNO_OUTPUT}.json")
    if [ "$LYRICS" != "null" ]; then
        echo "$LYRICS" > "lyrics.txt"
        echo "✅ Extracted lyrics from JSON"
    fi
fi
```

---

## Complete Workflow with Lyrics

### Full Pipeline:

```bash
#!/bin/bash
# complete-workflow-with-lyrics.sh

ARTIST="Artist Name"
SONG="Song Title"
SUNO_AUDIO="suno_track.mp3"
LYRICS_FILE="lyrics.txt"

# 1. Convert Suno MP3 to WAV
echo "Converting to WAV..."
ffmpeg -i "$SUNO_AUDIO" -ar 44100 raw.wav

# 2. Master with eMastered
echo "Mastering..."
./emastered-workflow.sh \
  "raw.wav" \
  "$ARTIST" \
  "$SONG" \
  "2025-01-15"

# 3. Add lyrics to mastered file
echo "Adding lyrics..."
MASTERED="mastered/${ARTIST// /_}_-_${SONG// /_}_mastered.wav"
python3 add-lyrics.py "$MASTERED" "$LYRICS_FILE"

# 4. Verify lyrics were added
echo "Verifying..."
python3 -c "from mutagen.wave import WAVE; w=WAVE('$MASTERED'); print('Lyrics:', 'ILYRIC' in w)"

# 5. Upload to DistroKid (manual)
echo "Ready to upload: $MASTERED"
echo "Lyrics file: $LYRICS_FILE"

# 6. Distribute to social
./distribute-premastered.sh \
  "$MASTERED" \
  "$ARTIST" \
  "$SONG" \
  "https://hyperfollow.com/link"
```

---

## Troubleshooting

### Lyrics Not Showing on Spotify
- Upload separately via Spotify for Artists dashboard
- Wait 24-48 hours for processing
- Ensure lyrics are properly formatted

### Encoding Issues
```bash
# Convert to UTF-8
iconv -f ISO-8859-1 -t UTF-8 lyrics.txt > lyrics_utf8.txt
```

### Metadata Not Saving
```bash
# Check file permissions
chmod 644 audio.wav

# Verify with mutagen
python3 -c "from mutagen.wave import WAVE; print(WAVE('audio.wav').pprint())"
```

### LRC Timing Off
- Add offset in LRC file header: `[offset:+500]` (500ms later)
- Test with VLC Media Player before upload
- Use professional timing tool

---

## Summary

**Best Workflow:**
1. ✅ Create/extract lyrics from Suno
2. ✅ Format as plain text or LRC
3. ✅ Embed in mastered audio with Python script
4. ✅ Upload separate lyrics file to DistroKid
5. ✅ Submit to Spotify for Artists (if needed)

**Files to Keep:**
- `Artist_Song_lyrics.txt` - Plain text
- `Artist_Song_lyrics.lrc` - Time-synced (optional)
- Embedded in audio metadata

**Result:** Professional lyrics display across all streaming platforms! 🎵📝
