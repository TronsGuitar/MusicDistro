# eMastered Integration Guide

Complete guide for integrating eMastered.com with your MusicDistro workflow for automated AI mastering.

---

## Overview

eMastered provides AI-powered mastering with an Ultimate subscription that includes:
- Unlimited mastering
- Advanced mastering engine
- Reference mastering
- Multiple file formats
- Stem mastering (individual tracks)
- API access (depending on plan)

This integration replaces or complements the GitHub Actions pre-mastering workflow.

---

## Integration Options

### Option 1: Manual eMastered + Automated Distribution
**Best for:** Users who want manual control over mastering settings
**Time:** 5-10 minutes per track

### Option 2: CLI Automation via Browser Automation
**Best for:** Batch processing multiple tracks
**Time:** Automated, ~2 minutes per track

### Option 3: API Integration (if available)
**Best for:** Complete automation
**Time:** Fully automated, ~1 minute per track

---

## Option 1: Manual eMastered + Automated Distribution

### Workflow

```
Suno/Source → Upload to eMastered → Download Mastered → 
distribute-premastered.sh → DistroKid → n8n → Social Media
```

### Step-by-Step

#### 1. Export from Suno
```bash
# Download your track from Suno
# If MP3, convert to WAV first
ffmpeg -i suno_track.mp3 -ar 44100 -sample_fmt s16 suno_track.wav
```

#### 2. Upload to eMastered
1. Go to https://www.emastered.com
2. Click **"Master a Track"**
3. Upload your WAV file
4. Choose mastering options:
   - **Mastering Intensity:** Medium (recommended for streaming)
   - **Reference Track:** Optional, upload a similar commercial track
   - **Format:** WAV (highest quality)
5. Click **"Master Now"**
6. Preview and adjust if needed
7. Download the mastered track

#### 3. Distribute Automatically
```bash
cd MusicDistro

# Set your n8n webhook (one time)
export N8N_WEBHOOK_URL="https://your-n8n.com/webhook/hyperfollow-distribute"

# Run distribution script
./distribute-premastered.sh \
  "path/to/emastered_track.wav" \
  "Your Artist Name" \
  "Song Title" \
  "https://distrokid.com/hyperfollow/artist/song"
```

**Done!** The script handles quality checks and social distribution.

---

## Option 2: CLI Automation with Playwright

Automate browser interaction with eMastered for batch processing.

### Setup

#### Install Dependencies
```bash
# Install Node.js and Playwright
npm install -g playwright
playwright install chromium

# Or use Python
pip install playwright
playwright install chromium
```

### Automation Script

Create `emastered-auto.js`:

```javascript
const { chromium } = require('playwright');
const path = require('path');

async function masterTrack(audioFile, outputFile, credentials) {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // Login
    await page.goto('https://www.emastered.com/login');
    await page.fill('input[type="email"]', credentials.email);
    await page.fill('input[type="password"]', credentials.password);
    await page.click('button[type="submit"]');
    await page.waitForURL('**/dashboard', { timeout: 10000 });

    // Upload track
    await page.goto('https://www.emastered.com/master');
    
    const fileInput = await page.locator('input[type="file"]');
    await fileInput.setInputFiles(path.resolve(audioFile));

    // Wait for upload
    await page.waitForSelector('text=Upload complete', { timeout: 120000 });

    // Start mastering
    await page.click('button:has-text("Master Now")');
    
    // Wait for mastering to complete
    await page.waitForSelector('text=Mastering complete', { timeout: 180000 });

    // Download
    await page.click('button:has-text("Download")');
    
    // Select WAV format
    await page.click('text=WAV');
    
    // Wait for download
    const download = await page.waitForEvent('download');
    await download.saveAs(outputFile);

    console.log(`✅ Successfully mastered: ${audioFile}`);
    console.log(`📥 Saved to: ${outputFile}`);

  } catch (error) {
    console.error('❌ Error:', error.message);
    throw error;
  } finally {
    await browser.close();
  }
}

// Usage
const credentials = {
  email: process.env.EMASTERED_EMAIL,
  password: process.env.EMASTERED_PASSWORD
};

const audioFile = process.argv[2];
const outputFile = process.argv[3] || 'mastered_output.wav';

if (!audioFile) {
  console.error('Usage: node emastered-auto.js <input.wav> [output.wav]');
  process.exit(1);
}

masterTrack(audioFile, outputFile, credentials)
  .then(() => process.exit(0))
  .catch(() => process.exit(1));
```

### Environment Variables

```bash
# Add to ~/.bashrc or ~/.zshrc
export EMASTERED_EMAIL="your-email@example.com"
export EMASTERED_PASSWORD="your-password"
```

### Usage

```bash
# Master a single track
node emastered-auto.js input.wav output_mastered.wav

# Batch process multiple tracks
for file in inbox/*.wav; do
  output="mastered/$(basename "$file")"
  node emastered-auto.js "$file" "$output"
done
```

---

## Option 3: API Integration

eMastered may provide API access with Ultimate subscriptions. Contact their support to request API credentials.

### If API is Available

Create `emastered-api.sh`:

```bash
#!/bin/bash
# eMastered API Integration

EMASTERED_API_KEY="${EMASTERED_API_KEY}"
EMASTERED_API_URL="https://api.emastered.com/v1"

INPUT_FILE="$1"
OUTPUT_FILE="${2:-mastered_output.wav}"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <input.wav> [output.wav]"
    exit 1
fi

if [ -z "$EMASTERED_API_KEY" ]; then
    echo "Error: EMASTERED_API_KEY not set"
    exit 1
fi

echo "Uploading to eMastered..."

# Upload file
UPLOAD_RESPONSE=$(curl -s -X POST "$EMASTERED_API_URL/upload" \
  -H "Authorization: Bearer $EMASTERED_API_KEY" \
  -F "file=@$INPUT_FILE")

FILE_ID=$(echo "$UPLOAD_RESPONSE" | jq -r '.file_id')

if [ -z "$FILE_ID" ] || [ "$FILE_ID" = "null" ]; then
    echo "Error uploading file"
    echo "$UPLOAD_RESPONSE"
    exit 1
fi

echo "File uploaded. ID: $FILE_ID"

# Start mastering
echo "Starting mastering process..."

MASTER_RESPONSE=$(curl -s -X POST "$EMASTERED_API_URL/master" \
  -H "Authorization: Bearer $EMASTERED_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"file_id\": \"$FILE_ID\",
    \"intensity\": \"medium\",
    \"format\": \"wav\"
  }")

JOB_ID=$(echo "$MASTER_RESPONSE" | jq -r '.job_id')

echo "Mastering job started. ID: $JOB_ID"

# Poll for completion
while true; do
    STATUS_RESPONSE=$(curl -s -X GET "$EMASTERED_API_URL/status/$JOB_ID" \
      -H "Authorization: Bearer $EMASTERED_API_KEY")
    
    STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.status')
    
    echo "Status: $STATUS"
    
    if [ "$STATUS" = "completed" ]; then
        break
    elif [ "$STATUS" = "failed" ]; then
        echo "Mastering failed"
        exit 1
    fi
    
    sleep 5
done

# Download mastered file
echo "Downloading mastered file..."

DOWNLOAD_URL=$(echo "$STATUS_RESPONSE" | jq -r '.download_url')

curl -s -L "$DOWNLOAD_URL" \
  -H "Authorization: Bearer $EMASTERED_API_KEY" \
  -o "$OUTPUT_FILE"

echo "✅ Mastered file saved to: $OUTPUT_FILE"

# Optional: Get mastering stats
STATS=$(echo "$STATUS_RESPONSE" | jq -r '.stats')
echo ""
echo "Mastering Stats:"
echo "$STATS" | jq '.'
```

**Note:** API endpoints are hypothetical. Check eMastered documentation for actual endpoints.

---

## Complete Automated Workflow

### Combined Script: `emastered-workflow.sh`

```bash
#!/bin/bash
# Complete eMastered + Distribution Workflow

set -e

# Configuration
EMASTERED_EMAIL="${EMASTERED_EMAIL}"
EMASTERED_PASSWORD="${EMASTERED_PASSWORD}"
N8N_WEBHOOK="${N8N_WEBHOOK_URL}"

# Input
INPUT_FILE="$1"
ARTIST_NAME="$2"
SONG_TITLE="$3"
RELEASE_DATE="${4:-$(date +%Y-%m-%d)}"
HYPERFOLLOW_LINK="${5}"

# Validate
if [ -z "$INPUT_FILE" ] || [ -z "$ARTIST_NAME" ] || [ -z "$SONG_TITLE" ]; then
    echo "Usage: $0 <input.wav> <artist> <song_title> [release_date] [hyperfollow_link]"
    exit 1
fi

echo "========================================="
echo "eMastered + MusicDistro Workflow"
echo "========================================="
echo "Artist: $ARTIST_NAME"
echo "Song: $SONG_TITLE"
echo "Input: $INPUT_FILE"
echo ""

# Step 1: Master with eMastered
echo "Step 1/4: Mastering with eMastered..."
MASTERED_FILE="mastered/${ARTIST_NAME// /_}_-_${SONG_TITLE// /_}_mastered.wav"
mkdir -p mastered

# Choose your method:
# Method A: Playwright automation
# node emastered-auto.js "$INPUT_FILE" "$MASTERED_FILE"

# Method B: API (if available)
# ./emastered-api.sh "$INPUT_FILE" "$MASTERED_FILE"

# Method C: Manual (exit here and upload manually)
if [ "$EMASTERED_METHOD" = "manual" ]; then
    echo "Please:"
    echo "  1. Upload $INPUT_FILE to eMastered"
    echo "  2. Download mastered file as: $MASTERED_FILE"
    echo "  3. Run: ./distribute-premastered.sh \"$MASTERED_FILE\" \"$ARTIST_NAME\" \"$SONG_TITLE\" \"$HYPERFOLLOW_LINK\""
    exit 0
fi

echo "✅ Mastering complete: $MASTERED_FILE"

# Step 2: Quality Check
echo ""
echo "Step 2/4: Quality Check..."
if command -v ffmpeg &> /dev/null; then
    ffmpeg -i "$MASTERED_FILE" -filter:a loudnorm=print_format=summary -f null - 2>&1 | \
        grep -E "Input Integrated|Input True Peak"
fi

# Step 3: Upload to DistroKid
echo ""
echo "Step 3/4: Manual Upload Required"
echo "Upload $MASTERED_FILE to DistroKid"
echo "Then get your HyperFollow link"
echo ""

if [ -z "$HYPERFOLLOW_LINK" ]; then
    read -p "Enter HyperFollow link (or press Enter to skip): " HYPERFOLLOW_LINK
fi

# Step 4: Distribute to Social Media
if [ -n "$HYPERFOLLOW_LINK" ] && [ -n "$N8N_WEBHOOK" ]; then
    echo ""
    echo "Step 4/4: Distributing to Social Media..."
    
    PAYLOAD=$(cat <<EOF
{
  "hyperfollow_link": "$HYPERFOLLOW_LINK",
  "artist_name": "$ARTIST_NAME",
  "song_title": "$SONG_TITLE",
  "release_date": "$RELEASE_DATE",
  "custom_message": "Just released my new track, mastered with eMastered! 🎵"
}
EOF
)
    
    RESPONSE=$(curl -s -X POST "$N8N_WEBHOOK" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD")
    
    echo "✅ Distributed to social media!"
else
    echo ""
    echo "Step 4/4: Skipped (no HyperFollow link or webhook)"
fi

echo ""
echo "========================================="
echo "Workflow Complete!"
echo "========================================="
echo "Mastered file: $MASTERED_FILE"
```

Usage:
```bash
chmod +x emastered-workflow.sh

./emastered-workflow.sh \
  "suno_track.wav" \
  "Artist Name" \
  "Song Title" \
  "2025-01-15" \
  "https://hyperfollow.com/link"
```

---

## Batch Processing Multiple Tracks

### Process an entire album:

```bash
#!/bin/bash
# batch-emastered.sh - Process multiple tracks

TRACKS_DIR="$1"
OUTPUT_DIR="mastered"

mkdir -p "$OUTPUT_DIR"

for track in "$TRACKS_DIR"/*.wav; do
    basename=$(basename "$track" .wav)
    output="$OUTPUT_DIR/${basename}_mastered.wav"
    
    echo "Processing: $basename"
    
    # Master with eMastered
    node emastered-auto.js "$track" "$output"
    
    # Quality check
    echo "Quality check:"
    ffmpeg -i "$output" -filter:a loudnorm=print_format=summary -f null - 2>&1 | \
        grep -E "Integrated|Peak"
    
    echo "---"
    sleep 5  # Rate limiting
done

echo "✅ Batch processing complete!"
echo "Mastered files in: $OUTPUT_DIR"
```

Usage:
```bash
./batch-emastered.sh inbox/
```

---

## Integration with Album Setup Wizard

The wizard can be updated to include eMastered as a mastering option:

**In Step 2 (Audio File), add:**
- ☐ GitHub Actions Pre-Mastering
- ☑ eMastered AI Mastering (Recommended)
- ☐ Already Mastered (Skip)

---

## Comparison: GitHub Actions vs eMastered

| Feature | GitHub Actions | eMastered Ultimate |
|---------|----------------|-------------------|
| **Cost** | Free | $120-180/year |
| **Quality** | Good (SoX normalization) | Excellent (AI mastering) |
| **Speed** | 2-3 minutes | 1-2 minutes |
| **Automation** | Full (on git push) | Manual or scripted |
| **Features** | Basic mastering | Advanced + reference |
| **LUFS Targeting** | Fixed (-14) | Customizable |
| **Multi-format** | WAV only | WAV, MP3, FLAC |
| **Batch Processing** | Yes (git push) | Yes (with scripts) |

**Recommendation:** 
- Use **eMastered** for singles and important releases (better quality)
- Use **GitHub Actions** for demos and batch processing (free, automated)

---

## Troubleshooting

### eMastered Upload Fails
- Check file format (WAV, MP3, or FLAC)
- Ensure file size < 500MB
- Verify internet connection
- Try re-uploading

### Automation Script Errors
- Ensure Playwright is installed: `playwright install`
- Check credentials are set in environment variables
- Update selectors if eMastered UI changed
- Run in non-headless mode for debugging: `headless: false`

### Quality Issues
- Use higher mastering intensity for louder tracks
- Upload a reference track for better matching
- Ensure input file quality is good (no clipping)
- Contact eMastered support for custom mastering

---

## Next Steps

1. **Test eMastered** with a single track manually
2. **Set up automation** using Playwright script
3. **Integrate** with existing distribution workflow
4. **Batch process** your back catalog
5. **Update wizard** to include eMastered option

---

## Resources

- [eMastered Website](https://www.emastered.com)
- [eMastered Help Center](https://help.emastered.com)
- [Playwright Documentation](https://playwright.dev)
- [MusicDistro Workflows](COMPLETE-WORKFLOW-GUIDE.md)

---

**🎵 eMastered + MusicDistro = Professional Distribution Pipeline**
