#!/bin/bash
# Complete Suno → Distribution Workflow
# Downloads audio, extracts lyrics, masters, and distributes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Input
SUNO_URL="$1"
ARTIST_NAME="$2"
SONG_TITLE="$3"
RELEASE_DATE="${4:-$(date +%Y-%m-%d)}"

usage() {
    echo "Complete Suno → Distribution Workflow"
    echo "========================================"
    echo ""
    echo "Usage: $0 <suno_url> <artist_name> <song_title> [release_date]"
    echo ""
    echo "Example:"
    echo "  $0 'https://suno.com/song/abc123' 'Artist Name' 'Song Title' '2025-01-15'"
    echo ""
    echo "This script will:"
    echo "  1. Extract lyrics from Suno page"
    echo "  2. Download audio from Suno (manual step)"
    echo "  3. Convert to WAV if needed"
    echo "  4. Master with eMastered (if configured)"
    echo "  5. Embed lyrics in audio file"
    echo "  6. Prepare for distribution"
    echo ""
    echo "Environment variables:"
    echo "  EMASTERED_EMAIL      - For automated mastering"
    echo "  EMASTERED_PASSWORD   - For automated mastering"
    echo "  N8N_WEBHOOK_URL      - For social distribution"
    exit 1
}

if [ -z "$SUNO_URL" ] || [ -z "$ARTIST_NAME" ] || [ -z "$SONG_TITLE" ]; then
    usage
fi

echo ""
echo "========================================="
echo -e "${BLUE}Suno → Distribution Workflow${NC}"
echo "========================================="
echo -e "${GREEN}Suno URL:${NC} $SUNO_URL"
echo -e "${GREEN}Artist:${NC} $ARTIST_NAME"
echo -e "${GREEN}Song:${NC} $SONG_TITLE"
echo -e "${GREEN}Release Date:${NC} $RELEASE_DATE"
echo ""

# Create working directory
WORK_DIR="suno_${SONG_TITLE// /_}_$(date +%s)"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo -e "${BLUE}Working directory:${NC} $WORK_DIR"
echo ""

# Step 1: Extract Lyrics
echo "========================================="
echo -e "${BLUE}Step 1/6: Extracting Lyrics from Suno${NC}"
echo "========================================="
echo ""

if command -v node &> /dev/null; then
    if node -e "require('playwright')" 2>/dev/null; then
        LYRICS_FILE="${ARTIST_NAME// /_}_-_${SONG_TITLE// /_}_lyrics.txt"

        echo "Extracting lyrics..."
        if node ../extract-suno-lyrics.js "$SUNO_URL" "$LYRICS_FILE"; then
            echo -e "${GREEN}✅ Lyrics extracted successfully${NC}"
            EXTRACTED_LYRICS=true
        else
            echo -e "${YELLOW}⚠️  Automatic extraction failed${NC}"
            echo "You can add lyrics manually later"
            EXTRACTED_LYRICS=false
        fi
    else
        echo -e "${YELLOW}⚠️  Playwright not installed${NC}"
        echo "Install with: npm install playwright"
        echo "Skipping automatic lyrics extraction"
        EXTRACTED_LYRICS=false
    fi
else
    echo -e "${YELLOW}⚠️  Node.js not installed${NC}"
    echo "Install from: https://nodejs.org"
    echo "Skipping automatic lyrics extraction"
    EXTRACTED_LYRICS=false
fi

echo ""

# Step 2: Download Audio
echo "========================================="
echo -e "${BLUE}Step 2/6: Download Audio from Suno${NC}"
echo "========================================="
echo ""
echo -e "${YELLOW}📥 MANUAL STEP REQUIRED${NC}"
echo ""
echo "Please download your song from Suno:"
echo "  1. Go to: $SUNO_URL"
echo "  2. Click the download button"
echo "  3. Save the file to this directory:"
echo "     $(pwd)"
echo "  4. Name it: suno_audio.mp3"
echo ""
read -p "Press Enter when you've downloaded the file..."

# Verify file exists
AUDIO_FILE="suno_audio.mp3"
if [ ! -f "$AUDIO_FILE" ]; then
    echo ""
    echo -e "${YELLOW}File not found. Looking for any audio files...${NC}"

    # Find any audio file
    FOUND_AUDIO=$(find . -maxdepth 1 -type f \( -name "*.mp3" -o -name "*.wav" \) | head -1)

    if [ -n "$FOUND_AUDIO" ]; then
        AUDIO_FILE="$FOUND_AUDIO"
        echo -e "${GREEN}Found: $AUDIO_FILE${NC}"
    else
        echo -e "${RED}No audio file found in current directory${NC}"
        echo "Please download the audio file and run this script again"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Audio file located: $AUDIO_FILE${NC}"
echo ""

# Step 3: Convert to WAV
echo "========================================="
echo -e "${BLUE}Step 3/6: Convert to WAV${NC}"
echo "========================================="
echo ""

if [[ "$AUDIO_FILE" =~ \.mp3$ ]]; then
    if command -v ffmpeg &> /dev/null; then
        WAV_FILE="${ARTIST_NAME// /_}_-_${SONG_TITLE// /_}.wav"
        echo "Converting MP3 to WAV..."
        ffmpeg -i "$AUDIO_FILE" -ar 44100 -sample_fmt s16 "$WAV_FILE" -y 2>&1 | grep -v "^frame="
        echo -e "${GREEN}✅ Converted to WAV: $WAV_FILE${NC}"
    else
        echo -e "${YELLOW}⚠️  ffmpeg not installed${NC}"
        echo "Install with: sudo apt-get install ffmpeg"
        WAV_FILE="$AUDIO_FILE"
    fi
else
    WAV_FILE="$AUDIO_FILE"
    echo "File is already WAV format"
fi

echo ""

# Step 4: Master with eMastered (optional)
echo "========================================="
echo -e "${BLUE}Step 4/6: Mastering${NC}"
echo "========================================="
echo ""

MASTERED_FILE="$WAV_FILE"

if [ -n "$EMASTERED_EMAIL" ] && [ -n "$EMASTERED_PASSWORD" ]; then
    echo "eMastered credentials found. Attempting automated mastering..."

    if [ -f "../emastered-auto.js" ]; then
        MASTERED_FILE="${ARTIST_NAME// /_}_-_${SONG_TITLE// /_}_mastered.wav"

        if node ../emastered-auto.js "$WAV_FILE" "$MASTERED_FILE"; then
            echo -e "${GREEN}✅ Mastered with eMastered${NC}"
        else
            echo -e "${YELLOW}⚠️  Automated mastering failed${NC}"
            echo "Using original file"
            MASTERED_FILE="$WAV_FILE"
        fi
    else
        echo -e "${YELLOW}⚠️  eMastered automation script not found${NC}"
        MASTERED_FILE="$WAV_FILE"
    fi
else
    echo -e "${YELLOW}ℹ️  eMastered credentials not set${NC}"
    echo "Set EMASTERED_EMAIL and EMASTERED_PASSWORD for automated mastering"
    echo ""
    echo "Using file as-is (Suno audio is usually well-mastered)"
fi

echo ""

# Step 5: Embed Lyrics
if [ "$EXTRACTED_LYRICS" = true ] && [ -f "$LYRICS_FILE" ]; then
    echo "========================================="
    echo -e "${BLUE}Step 5/6: Embedding Lyrics${NC}"
    echo "========================================="
    echo ""

    if command -v python3 &> /dev/null; then
        if python3 ../add-lyrics.py "$MASTERED_FILE" "$LYRICS_FILE"; then
            echo -e "${GREEN}✅ Lyrics embedded in audio file${NC}"
        else
            echo -e "${YELLOW}⚠️  Failed to embed lyrics${NC}"
            echo "You can still upload the lyrics file separately"
        fi
    else
        echo -e "${YELLOW}⚠️  Python not found${NC}"
        echo "Install Python to embed lyrics: sudo apt install python3"
    fi
else
    echo "========================================="
    echo -e "${BLUE}Step 5/6: Lyrics${NC}"
    echo "========================================="
    echo -e "${YELLOW}ℹ️  No lyrics extracted. Skipping embedding.${NC}"
fi

echo ""

# Step 6: Prepare for Distribution
echo "========================================="
echo -e "${BLUE}Step 6/6: Prepare for Distribution${NC}"
echo "========================================="
echo ""

# Copy to main mastered folder
FINAL_DIR="../mastered"
mkdir -p "$FINAL_DIR"

FINAL_AUDIO="$FINAL_DIR/${ARTIST_NAME// /_}_-_${SONG_TITLE// /_}_${RELEASE_DATE}.wav"
cp "$MASTERED_FILE" "$FINAL_AUDIO"
echo -e "${GREEN}✅ Audio file ready: $FINAL_AUDIO${NC}"

if [ -f "$LYRICS_FILE" ]; then
    FINAL_LYRICS="$FINAL_DIR/${ARTIST_NAME// /_}_-_${SONG_TITLE// /_}_lyrics.txt"
    cp "$LYRICS_FILE" "$FINAL_LYRICS"
    echo -e "${GREEN}✅ Lyrics file ready: $FINAL_LYRICS${NC}"
fi

echo ""

# Quality check
if command -v ffmpeg &> /dev/null; then
    echo "Quality Check:"
    QC_OUTPUT=$(ffmpeg -i "$FINAL_AUDIO" -filter:a loudnorm=print_format=summary -f null - 2>&1)

    INTEGRATED=$(echo "$QC_OUTPUT" | grep "Input Integrated:" | awk '{print $3}')
    TRUE_PEAK=$(echo "$QC_OUTPUT" | grep "Input True Peak:" | awk '{print $4}')

    echo "  LUFS: $INTEGRATED"
    echo "  Peak: $TRUE_PEAK dBFS"
fi

echo ""
echo "========================================="
echo -e "${GREEN}🎉 Workflow Complete!${NC}"
echo "========================================="
echo ""
echo "📁 Files ready for distribution:"
echo "   Audio: $FINAL_AUDIO"
[ -f "$FINAL_LYRICS" ] && echo "   Lyrics: $FINAL_LYRICS"
echo ""
echo "📋 Next steps:"
echo "   1. Upload to DistroKid:"
echo "      • Audio file: $FINAL_AUDIO"
[ -f "$FINAL_LYRICS" ] && echo "      • Lyrics file: $FINAL_LYRICS"
echo ""
echo "   2. Get your HyperFollow link"
echo ""
echo "   3. Distribute to social media:"
echo "      ./distribute-premastered.sh \\"
echo "        \"$FINAL_AUDIO\" \\"
echo "        \"$ARTIST_NAME\" \\"
echo "        \"$SONG_TITLE\" \\"
echo "        \"YOUR_HYPERFOLLOW_LINK\" \\"
echo "        \"$RELEASE_DATE\""
echo ""
echo "🗂️  Working files saved in: $WORK_DIR"
echo ""
