#!/bin/bash
# distribute-premastered.sh - For WAV files that are already mastered
# Bypasses GitHub Actions pre-mastering and goes straight to distribution

MASTERED_FILE="$1"
ARTIST_NAME="$2"
SONG_TITLE="$3"
HYPERFOLLOW_LINK="$4"
RELEASE_DATE="${5:-$(date +%Y-%m-%d)}"
CUSTOM_MESSAGE="${6:-New music out now! Check it out on all streaming platforms 🎵}"
LYRICS_FILE="$7"
N8N_WEBHOOK="${N8N_WEBHOOK_URL}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validate input
if [ -z "$MASTERED_FILE" ] || [ -z "$ARTIST_NAME" ] || [ -z "$SONG_TITLE" ]; then
    echo -e "${RED}Usage: $0 <mastered_file.wav> <artist_name> <song_title> [hyperfollow_link] [release_date] [custom_message] [lyrics_file]${NC}"
    echo ""
    echo "Examples:"
    echo "  $0 my_song.wav 'Artist Name' 'Song Title'"
    echo "  $0 my_song.wav 'Artist Name' 'Song Title' 'https://distrokid.com/hyperfollow/artist/song'"
    echo "  $0 my_song.wav 'Artist Name' 'Song Title' '' '2025-01-15' 'Custom message' 'lyrics.txt'"
    echo ""
    echo "Environment variables:"
    echo "  N8N_WEBHOOK_URL - Your n8n webhook endpoint (required for social distribution)"
    echo ""
    echo "Optional lyrics file:"
    echo "  Pass path to .txt or .lrc file as 7th parameter to embed lyrics in metadata"
    exit 1
fi

# Check file exists and is WAV
if [ ! -f "$MASTERED_FILE" ]; then
    echo -e "${RED}Error: File not found: $MASTERED_FILE${NC}"
    exit 1
fi

if ! file "$MASTERED_FILE" 2>/dev/null | grep -q "WAVE\|WAV"; then
    echo -e "${YELLOW}Warning: File may not be a WAV file. Continuing anyway...${NC}"
fi

echo ""
echo "========================================="
echo -e "${BLUE}Pre-Mastered File Distribution${NC}"
echo "========================================="
echo -e "${GREEN}File:${NC} $MASTERED_FILE"
echo -e "${GREEN}Artist:${NC} $ARTIST_NAME"
echo -e "${GREEN}Song:${NC} $SONG_TITLE"
echo -e "${GREEN}Release Date:${NC} $RELEASE_DATE"
echo ""

# Optional: Quick quality check
if command -v ffmpeg &> /dev/null; then
    echo -e "${BLUE}Running quality check...${NC}"
    echo ""

    QC_OUTPUT=$(ffmpeg -i "$MASTERED_FILE" -filter:a loudnorm=print_format=summary -f null - 2>&1)

    INTEGRATED=$(echo "$QC_OUTPUT" | grep "Input Integrated:" | awk '{print $3}')
    TRUE_PEAK=$(echo "$QC_OUTPUT" | grep "Input True Peak:" | awk '{print $4}')
    LRA=$(echo "$QC_OUTPUT" | grep "Input LRA:" | awk '{print $3}')

    echo "  Integrated Loudness: $INTEGRATED LUFS"
    echo "  True Peak: $TRUE_PEAK dBFS"
    echo "  Loudness Range: $LRA LU"
    echo ""

    # Check if values are within recommended ranges
    if command -v bc &> /dev/null; then
        LUFS_CHECK=$(echo "$INTEGRATED > -16 && $INTEGRATED < -8" | bc -l 2>/dev/null)
        PEAK_CHECK=$(echo "$TRUE_PEAK < -1.0" | bc -l 2>/dev/null)

        if [ "$LUFS_CHECK" = "1" ] && [ "$PEAK_CHECK" = "1" ]; then
            echo -e "${GREEN}✅ Audio meets streaming platform standards${NC}"
        else
            if [ "$LUFS_CHECK" != "1" ]; then
                echo -e "${YELLOW}⚠️  Warning: LUFS outside recommended range (-16 to -8)${NC}"
            fi
            if [ "$PEAK_CHECK" != "1" ]; then
                echo -e "${YELLOW}⚠️  Warning: True peak above -1.0 dBFS (may cause clipping)${NC}"
            fi
        fi
    fi
    echo ""
else
    echo -e "${YELLOW}ℹ️  Install ffmpeg for quality checking: sudo apt-get install ffmpeg${NC}"
    echo ""
fi

# Add lyrics if provided
if [ -n "$LYRICS_FILE" ] && [ -f "$LYRICS_FILE" ]; then
    echo -e "${BLUE}Adding lyrics metadata...${NC}"
    echo ""

    if command -v python3 &> /dev/null; then
        python3 add-lyrics.py "$MASTERED_FILE" "$LYRICS_FILE"

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Lyrics embedded in audio file${NC}"
            echo ""
            echo "💡 Tips:"
            echo "   • Also upload lyrics file separately to DistroKid"
            echo "   • Submit to Spotify for Artists for lyrics display"
            echo ""
        else
            echo -e "${YELLOW}⚠️  Warning: Failed to add lyrics${NC}"
            echo "   You can still upload the lyrics file separately to your distributor"
            echo ""
        fi
    else
        echo -e "${YELLOW}⚠️  Python not found - skipping lyrics embedding${NC}"
        echo "   Install Python 3 and mutagen to add lyrics automatically:"
        echo "   sudo apt install python3"
        echo "   pip3 install mutagen"
        echo ""
        echo "   You can still upload: $LYRICS_FILE separately to your distributor"
        echo ""
    fi
elif [ -n "$LYRICS_FILE" ]; then
    echo -e "${YELLOW}⚠️  Lyrics file specified but not found: $LYRICS_FILE${NC}"
    echo ""
fi

# Copy to mastered folder (optional)
if [ -t 0 ]; then  # Only ask if running interactively
    read -p "Copy to mastered/ folder for archival? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p mastered
        SAFE_FILENAME="${ARTIST_NAME// /_}_-_${SONG_TITLE// /_}.wav"
        cp "$MASTERED_FILE" "mastered/$SAFE_FILENAME"
        echo -e "${GREEN}✅ Copied to mastered/$SAFE_FILENAME${NC}"
    fi
fi

# If HyperFollow link provided, distribute to social media
if [ -n "$HYPERFOLLOW_LINK" ]; then
    echo ""
    echo -e "${BLUE}Distributing to social media...${NC}"

    if [ -z "$N8N_WEBHOOK" ]; then
        echo -e "${RED}❌ Error: N8N_WEBHOOK_URL environment variable not set${NC}"
        echo ""
        echo "Set it with:"
        echo "  export N8N_WEBHOOK_URL='https://your-n8n.com/webhook/hyperfollow-distribute'"
        echo ""
        echo "Or run the curl command manually:"
        echo ""
        echo "curl -X POST 'https://your-n8n.com/webhook/hyperfollow-distribute' \\"
        echo "  -H 'Content-Type: application/json' \\"
        echo "  -d '{"
        echo "    \"hyperfollow_link\": \"$HYPERFOLLOW_LINK\","
        echo "    \"artist_name\": \"$ARTIST_NAME\","
        echo "    \"song_title\": \"$SONG_TITLE\","
        echo "    \"release_date\": \"$RELEASE_DATE\","
        echo "    \"custom_message\": \"$CUSTOM_MESSAGE\""
        echo "  }'"
        exit 1
    fi

    PAYLOAD=$(cat <<EOF
{
  "hyperfollow_link": "$HYPERFOLLOW_LINK",
  "artist_name": "$ARTIST_NAME",
  "song_title": "$SONG_TITLE",
  "release_date": "$RELEASE_DATE",
  "custom_message": "$CUSTOM_MESSAGE"
}
EOF
)

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$N8N_WEBHOOK" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
        echo -e "${GREEN}✅ Successfully distributed to social media!${NC}"
        echo ""
        echo -e "${GREEN}Posted to:${NC}"
        echo "  • Twitter/X"
        echo "  • Facebook"
        echo "  • LinkedIn"
        echo "  • Telegram"
        echo "  • Discord"
        [ -n "$BODY" ] && echo "$BODY"
    else
        echo -e "${RED}❌ Failed to distribute to social media (HTTP $HTTP_CODE)${NC}"
        [ -n "$BODY" ] && echo "$BODY"
        exit 1
    fi
else
    echo ""
    echo -e "${YELLOW}ℹ️  No HyperFollow link provided.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Upload $MASTERED_FILE to DistroKid"
    echo "  2. Create HyperFollow page"
    echo "  3. Run this script again with the HyperFollow link:"
    echo ""
    echo -e "${BLUE}$0 '$MASTERED_FILE' '$ARTIST_NAME' '$SONG_TITLE' 'YOUR_HYPERFOLLOW_LINK'${NC}"
    echo ""
    echo "Or trigger n8n directly:"
    echo ""
    if [ -n "$N8N_WEBHOOK" ]; then
        echo "curl -X POST '$N8N_WEBHOOK' \\"
    else
        echo "curl -X POST 'https://your-n8n.com/webhook/hyperfollow-distribute' \\"
    fi
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
echo -e "${GREEN}Complete!${NC}"
echo "========================================="
