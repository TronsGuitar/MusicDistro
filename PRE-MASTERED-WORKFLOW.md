# Using Pre-Mastered WAV Files

If your WAV files are already professionally mastered (from Suno, a mastering service, or your own mastering chain), you can skip the GitHub Actions pre-mastering step and go straight to distribution.

## Quick Path: Pre-Mastered Files → Distribution → Social Media

### Step 1: Verify Your Mastered WAV Meets Requirements

Your mastered file should meet these specs:

**Audio Format:**
- ✅ WAV format (16-bit or 24-bit PCM)
- ✅ Sample rate: 44.1 kHz or 48 kHz
- ✅ Stereo (2 channels)

**Quality Targets:**
- ✅ LUFS: -14 to -10 (streaming standard)
- ✅ True peak: Below -1.0 dBFS (preferably -1.5 dBFS)
- ✅ No clipping or distortion

**Check Your File (Optional):**
```bash
# Install ffmpeg if needed
sudo apt-get install ffmpeg

# Check loudness
ffmpeg -i your_mastered_track.wav -filter:a loudnorm=print_format=summary -f null - 2>&1 | grep -E "Input Integrated|Input True Peak"

# Check format
ffmpeg -i your_mastered_track.wav 2>&1 | grep -E "Stream|Duration"
```

### Step 2: Skip GitHub Actions (Optional Storage Only)

If you want to use GitHub just for version control/storage:

```bash
# Create a 'mastered' folder instead of 'inbox'
mkdir -p mastered

# Copy your file there
cp /path/to/your_mastered_track.wav mastered/Artist_-_Song_Title.wav

# Commit and push (optional)
git add mastered/
git commit -m "Add pre-mastered track: Song Title"
git push
```

**OR** skip GitHub entirely and keep files locally.

### Step 3: Upload Directly to DistroKid

Since your file is already mastered, go straight to upload:

1. **Log in to DistroKid**: https://distrokid.com
2. **Click "Upload"**
3. **Choose your pre-mastered WAV file**
4. **Fill out metadata**:
   - Artist name
   - Song title
   - Genre
   - Release date
   - Cover art (3000x3000px minimum)
5. **Enable monetization**:
   - ✅ YouTube Content ID
   - ✅ Facebook/Instagram
   - ✅ TikTok
6. **Submit**
7. **Create HyperFollow page**
8. **Copy the HyperFollow URL**

### Step 4: Distribute to Social Media with n8n

Once you have your HyperFollow link:

```bash
curl -X POST https://your-n8n-instance.com/webhook/hyperfollow-distribute \
  -H "Content-Type: application/json" \
  -d '{
    "hyperfollow_link": "https://distrokid.com/hyperfollow/artist/song",
    "artist_name": "Your Artist Name",
    "song_title": "Song Title",
    "release_date": "2025-01-15",
    "custom_message": "New music out now! 🎵"
  }'
```

**Done!** Your pre-mastered file is now distributed to all social platforms.

---

## Folder Structure for Pre-Mastered Files

If you want to organize both raw and mastered files:

```
MusicDistro/
├── inbox/              # For files that need pre-mastering (GitHub Actions)
├── mastered/           # For pre-mastered files (bypass GitHub Actions)
├── examples/
├── n8n-hyperfollow-distribution.json
└── COMPLETE-WORKFLOW-GUIDE.md
```

---

## Automated Distribution Script for Pre-Mastered Files

Create a helper script to streamline the process:

```bash
#!/bin/bash
# distribute-premastered.sh - For files that are already mastered

MASTERED_FILE="$1"
ARTIST_NAME="$2"
SONG_TITLE="$3"
HYPERFOLLOW_LINK="$4"
RELEASE_DATE="${5:-$(date +%Y-%m-%d)}"
N8N_WEBHOOK="${N8N_WEBHOOK_URL:-https://your-n8n.com/webhook/hyperfollow-distribute}"

# Validate input
if [ -z "$MASTERED_FILE" ] || [ -z "$ARTIST_NAME" ] || [ -z "$SONG_TITLE" ]; then
    echo "Usage: $0 <mastered_file.wav> <artist_name> <song_title> [hyperfollow_link] [release_date]"
    echo ""
    echo "Example:"
    echo "  $0 my_song.wav 'Artist Name' 'Song Title' 'https://distrokid.com/hyperfollow/...'"
    exit 1
fi

# Check file exists and is WAV
if [ ! -f "$MASTERED_FILE" ]; then
    echo "Error: File not found: $MASTERED_FILE"
    exit 1
fi

if ! file "$MASTERED_FILE" | grep -q "WAVE\|WAV"; then
    echo "Warning: File may not be a WAV file"
fi

echo "========================================="
echo "Pre-Mastered File Distribution"
echo "========================================="
echo "File: $MASTERED_FILE"
echo "Artist: $ARTIST_NAME"
echo "Song: $SONG_TITLE"
echo "Release Date: $RELEASE_DATE"
echo ""

# Optional: Quick quality check
if command -v ffmpeg &> /dev/null; then
    echo "Running quick quality check..."
    ffmpeg -i "$MASTERED_FILE" -filter:a loudnorm=print_format=summary -f null - 2>&1 | grep -E "Input Integrated|Input True Peak|Input LRA"
    echo ""
fi

# Copy to mastered folder (optional)
read -p "Copy to mastered/ folder for archival? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p mastered
    SAFE_FILENAME="${ARTIST_NAME// /_}_-_${SONG_TITLE// /_}.wav"
    cp "$MASTERED_FILE" "mastered/$SAFE_FILENAME"
    echo "✅ Copied to mastered/$SAFE_FILENAME"
fi

# If HyperFollow link provided, distribute to social media
if [ -n "$HYPERFOLLOW_LINK" ]; then
    echo ""
    echo "Distributing to social media..."
    
    PAYLOAD=$(cat <<EOF
{
  "hyperfollow_link": "$HYPERFOLLOW_LINK",
  "artist_name": "$ARTIST_NAME",
  "song_title": "$SONG_TITLE",
  "release_date": "$RELEASE_DATE",
  "custom_message": "New music out now! Check it out on all streaming platforms 🎵"
}
EOF
)
    
    RESPONSE=$(curl -s -X POST "$N8N_WEBHOOK" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD")
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully distributed to social media!"
        echo "$RESPONSE"
    else
        echo "❌ Failed to distribute to social media"
        echo "$RESPONSE"
    fi
else
    echo ""
    echo "ℹ️  No HyperFollow link provided. Upload to DistroKid, then run:"
    echo ""
    echo "curl -X POST $N8N_WEBHOOK \\"
    echo "  -H 'Content-Type: application/json' \\"
    echo "  -d '{"
    echo "    \"hyperfollow_link\": \"YOUR_LINK_HERE\","
    echo "    \"artist_name\": \"$ARTIST_NAME\","
    echo "    \"song_title\": \"$SONG_TITLE\","
    echo "    \"release_date\": \"$RELEASE_DATE\""
    echo "  }'"
fi

echo ""
echo "========================================="
echo "Distribution Complete!"
echo "========================================="
```

Save as `distribute-premastered.sh` and use:

```bash
chmod +x distribute-premastered.sh

# Without social distribution (just quality check + archive)
./distribute-premastered.sh my_mastered_song.wav "Artist Name" "Song Title"

# With social distribution
./distribute-premastered.sh my_mastered_song.wav "Artist Name" "Song Title" "https://distrokid.com/hyperfollow/artist/song"
```

---

## Comparison: Pre-Mastering vs Pre-Mastered Workflow

| Step | Pre-Mastering Workflow | Pre-Mastered Workflow |
|------|----------------------|----------------------|
| 1. Get audio | Download from Suno | Already mastered |
| 2. Convert | MP3 → WAV | Already WAV |
| 3. Pre-master | GitHub Actions | **SKIP** ✅ |
| 4. Quality check | Automated QC report | Manual check (optional) |
| 5. Upload | DistroKid | DistroKid |
| 6. HyperFollow | Create link | Create link |
| 7. Social distribution | n8n workflow | n8n workflow |

**Time saved: 5-10 minutes per release** ⚡

---

## When to Use Each Workflow

### Use GitHub Actions Pre-Mastering When:
- ✅ You have raw/unmixed audio from Suno
- ✅ You want automated loudness normalization
- ✅ You need consistent LUFS targeting
- ✅ You want automated quality reports
- ✅ You're new to mastering

### Use Pre-Mastered Workflow When:
- ✅ Audio is already professionally mastered
- ✅ You're using external mastering services
- ✅ Suno output is already at commercial loudness
- ✅ You have your own mastering chain
- ✅ You want faster turnaround

---

## Integration with n8n Workflow

Both workflows use the same n8n social distribution at the end:

```
┌─────────────────────────────────────────────────┐
│  Pre-Mastering Workflow                         │
│  Suno → GitHub Actions → DistroKid → n8n       │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Pre-Mastered Workflow                          │
│  Mastered File → DistroKid → n8n               │
└─────────────────────────────────────────────────┘
```

The n8n social distribution step is **exactly the same** regardless of which path you take!

---

## Quick Reference

**I have:** Pre-mastered WAV files
**I need:** Fast path to distribution + social media

**Steps:**
1. ✅ Verify WAV meets specs (16/24-bit, 44.1/48kHz, LUFS -14 to -10)
2. ✅ Upload directly to DistroKid
3. ✅ Get HyperFollow link
4. ✅ Trigger n8n workflow
5. ✅ Done!

**No GitHub Actions needed!**
