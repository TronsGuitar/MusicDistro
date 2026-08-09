#!/bin/bash
# Complete eMastered + MusicDistro Workflow
# Automates: eMastered mastering → Quality check → Social distribution

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration from environment
EMASTERED_EMAIL="${EMASTERED_EMAIL}"
EMASTERED_PASSWORD="${EMASTERED_PASSWORD}"
N8N_WEBHOOK="${N8N_WEBHOOK_URL}"

# Input parameters
INPUT_FILE="$1"
ARTIST_NAME="$2"
SONG_TITLE="$3"
RELEASE_DATE="${4:-$(date +%Y-%m-%d)}"
HYPERFOLLOW_LINK="${5}"
LYRICS_FILE="${6}"

# Usage
usage() {
    echo "Usage: $0 <input.wav> <artist> <song_title> [release_date] [hyperfollow_link] [lyrics_file]"
    echo ""
    echo "Environment variables:"
    echo "  EMASTERED_EMAIL      Your eMastered email (required)"
    echo "  EMASTERED_PASSWORD   Your eMastered password (required)"
    echo "  N8N_WEBHOOK_URL      Your n8n webhook for social distribution (optional)"
    echo ""
    echo "Example:"
    echo "  $0 'track.wav' 'Artist Name' 'Song Title' '2025-01-15' 'https://hyperfollow.com/link'"
    exit 1
}

# Validate inputs
if [ -z "$INPUT_FILE" ] || [ -z "$ARTIST_NAME" ] || [ -z "$SONG_TITLE" ]; then
    usage
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}Error: Input file not found: $INPUT_FILE${NC}"
    exit 1
fi

if [ -z "$EMASTERED_EMAIL" ] || [ -z "$EMASTERED_PASSWORD" ]; then
    echo -e "${RED}Error: EMASTERED_EMAIL and EMASTERED_PASSWORD must be set${NC}"
    echo ""
    echo "Set them with:"
    echo "  export EMASTERED_EMAIL='your-email@example.com'"
    echo "  export EMASTERED_PASSWORD='your-password'"
    exit 1
fi

echo ""
echo "========================================="
echo -e "${BLUE}eMastered + MusicDistro Workflow${NC}"
echo "========================================="
echo -e "${GREEN}Artist:${NC} $ARTIST_NAME"
echo -e "${GREEN}Song:${NC} $SONG_TITLE"
echo -e "${GREEN}Input:${NC} $INPUT_FILE"
echo -e "${GREEN}Release Date:${NC} $RELEASE_DATE"
echo ""

# Step 1: Check if Node.js and Playwright are installed
echo -e "${BLUE}Step 1/5: Checking dependencies...${NC}"

if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js not installed${NC}"
    echo "Install from: https://nodejs.org"
    exit 1
fi

if ! node -e "require('playwright')" 2>/dev/null; then
    echo -e "${YELLOW}Playwright not found. Installing...${NC}"
    npm install playwright
    npx playwright install chromium
fi

echo -e "${GREEN}✅ Dependencies OK${NC}"

# Step 2: Master with eMastered
echo ""
echo -e "${BLUE}Step 2/5: Mastering with eMastered AI...${NC}"

MASTERED_FILE="mastered/${ARTIST_NAME// /_}_-_${SONG_TITLE// /_}_mastered.wav"
mkdir -p mastered

# Run eMastered automation
if node emastered-auto.js "$INPUT_FILE" "$MASTERED_FILE"; then
    echo -e "${GREEN}✅ Mastering complete: $MASTERED_FILE${NC}"
else
    echo -e "${RED}❌ Mastering failed${NC}"
    echo ""
    echo "Try manually:"
    echo "  1. Go to https://www.emastered.com"
    echo "  2. Upload: $INPUT_FILE"
    echo "  3. Download mastered file as: $MASTERED_FILE"
    echo "  4. Run: ./distribute-premastered.sh \"$MASTERED_FILE\" \"$ARTIST_NAME\" \"$SONG_TITLE\" \"$HYPERFOLLOW_LINK\""
    exit 1
fi

# Step 3: Quality Check
echo ""
echo -e "${BLUE}Step 3/5: Quality Check...${NC}"

if command -v ffmpeg &> /dev/null; then
    echo ""
    QC_OUTPUT=$(ffmpeg -i "$MASTERED_FILE" -filter:a loudnorm=print_format=summary -f null - 2>&1)

    INTEGRATED=$(echo "$QC_OUTPUT" | grep "Input Integrated:" | awk '{print $3}')
    TRUE_PEAK=$(echo "$QC_OUTPUT" | grep "Input True Peak:" | awk '{print $4}')
    LRA=$(echo "$QC_OUTPUT" | grep "Input LRA:" | awk '{print $3}')

    echo "  Integrated Loudness: $INTEGRATED LUFS"
    echo "  True Peak: $TRUE_PEAK dBFS"
    echo "  Loudness Range: $LRA LU"
    echo ""

    # Check if values are good
    if command -v bc &> /dev/null; then
        LUFS_OK=$(echo "$INTEGRATED > -16 && $INTEGRATED < -8" | bc -l 2>/dev/null || echo "0")
        PEAK_OK=$(echo "$TRUE_PEAK < -1.0" | bc -l 2>/dev/null || echo "0")

        if [ "$LUFS_OK" = "1" ] && [ "$PEAK_OK" = "1" ]; then
            echo -e "${GREEN}✅ Audio quality meets streaming standards${NC}"
        else
            [ "$LUFS_OK" != "1" ] && echo -e "${YELLOW}⚠️  LUFS outside recommended range (-16 to -8)${NC}"
            [ "$PEAK_OK" != "1" ] && echo -e "${YELLOW}⚠️  True peak above -1.0 dBFS${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  ffmpeg not installed - skipping quality check${NC}"
    echo "Install with: sudo apt-get install ffmpeg"
fi

# Step 3.5: Add Lyrics (if provided)
if [ -n "$LYRICS_FILE" ] && [ -f "$LYRICS_FILE" ]; then
    echo ""
    echo -e "${BLUE}Step 3.5/5: Adding Lyrics Metadata...${NC}"

    if command -v python3 &> /dev/null; then
        python3 add-lyrics.py "$MASTERED_FILE" "$LYRICS_FILE"

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Lyrics embedded in audio file${NC}"

            # Also save lyrics as separate file for DistroKid upload
            LYRICS_COPY="mastered/${ARTIST_NAME// /_}_-_${SONG_TITLE// /_}_lyrics.txt"
            cp "$LYRICS_FILE" "$LYRICS_COPY"
            echo -e "${GREEN}✅ Lyrics file saved: $LYRICS_COPY${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Python not found - skipping lyrics${NC}"
        echo "Install: sudo apt install python3 && pip3 install mutagen"
    fi
elif [ -n "$LYRICS_FILE" ]; then
    echo -e "${YELLOW}⚠️  Lyrics file not found: $LYRICS_FILE${NC}"
fi

# Step 4: Archive
echo ""
echo -e "${BLUE}Step 4/5: Archiving...${NC}"

# Save a copy with metadata
cp "$MASTERED_FILE" "mastered/${ARTIST_NAME// /_}_-_${SONG_TITLE// /_}_${RELEASE_DATE}.wav"
echo -e "${GREEN}✅ Archived with date: ${RELEASE_DATE}${NC}"

# Step 5: Social Distribution
echo ""
echo -e "${BLUE}Step 5/5: Social Media Distribution...${NC}"

if [ -z "$HYPERFOLLOW_LINK" ]; then
    echo -e "${YELLOW}ℹ️  No HyperFollow link provided${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Upload to DistroKid: $MASTERED_FILE"
    echo "  2. Create HyperFollow page"
    echo "  3. Run distribution:"
    echo ""
    echo "     ./distribute-premastered.sh \\"
    echo "       \"$MASTERED_FILE\" \\"
    echo "       \"$ARTIST_NAME\" \\"
    echo "       \"$SONG_TITLE\" \\"
    echo "       \"YOUR_HYPERFOLLOW_LINK\""
elif [ -z "$N8N_WEBHOOK" ]; then
    echo -e "${YELLOW}ℹ️  N8N_WEBHOOK_URL not set${NC}"
    echo ""
    echo "Set it with:"
    echo "  export N8N_WEBHOOK_URL='https://your-n8n.com/webhook/hyperfollow-distribute'"
    echo ""
    echo "Then run:"
    echo "  ./distribute-premastered.sh \\"
    echo "    \"$MASTERED_FILE\" \\"
    echo "    \"$ARTIST_NAME\" \\"
    echo "    \"$SONG_TITLE\" \\"
    echo "    \"$HYPERFOLLOW_LINK\""
else
    echo "Distributing to social media..."

    PAYLOAD=$(cat <<EOF
{
  "hyperfollow_link": "$HYPERFOLLOW_LINK",
  "artist_name": "$ARTIST_NAME",
  "song_title": "$SONG_TITLE",
  "release_date": "$RELEASE_DATE",
  "custom_message": "Just released my new track, professionally mastered with eMastered AI! 🎵✨"
}
EOF
)

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$N8N_WEBHOOK" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
        echo -e "${GREEN}✅ Successfully distributed to social media!${NC}"
        echo ""
        echo "Posted to:"
        echo "  • Twitter/X"
        echo "  • Facebook"
        echo "  • LinkedIn"
        echo "  • Telegram"
        echo "  • Discord"
    else
        echo -e "${RED}❌ Social distribution failed (HTTP $HTTP_CODE)${NC}"
        echo "Run manually:"
        echo "  ./distribute-premastered.sh \\"
        echo "    \"$MASTERED_FILE\" \\"
        echo "    \"$ARTIST_NAME\" \\"
        echo "    \"$SONG_TITLE\" \\"
        echo "    \"$HYPERFOLLOW_LINK\""
    fi
fi

echo ""
echo "========================================="
echo -e "${GREEN}🎉 Workflow Complete!${NC}"
echo "========================================="
echo -e "${GREEN}Mastered file:${NC} $MASTERED_FILE"
echo ""
echo "Next steps:"
echo "  1. Upload mastered WAV to DistroKid"
echo "  2. Get HyperFollow link"
echo "  3. Distribute to social (if not done above)"
echo ""
