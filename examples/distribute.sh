#!/bin/bash
# Example script to distribute HyperFollow link to social media via n8n

# Configuration - set these as environment variables or edit here
N8N_WEBHOOK_URL="${N8N_WEBHOOK_URL:-https://your-n8n-instance.com/webhook/hyperfollow-distribute}"
HYPERFOLLOW_LINK="${1:-https://hyperfollow.com/artist/song}"
ARTIST_NAME="${2:-Artist Name}"
SONG_TITLE="${3:-Song Title}"
RELEASE_DATE="${4:-$(date +%Y-%m-%d)}"
CUSTOM_MESSAGE="${5:-New music out now! 🎵}"

# Validate required parameters
if [ "$HYPERFOLLOW_LINK" = "https://hyperfollow.com/artist/song" ]; then
    echo "Usage: $0 <hyperfollow_link> <artist_name> <song_title> [release_date] [custom_message]"
    echo ""
    echo "Example:"
    echo "  $0 'https://hyperfollow.com/artist/song' 'The Artist' 'Song Name' '2025-01-15' 'Check out my new track!'"
    echo ""
    echo "Environment variables:"
    echo "  N8N_WEBHOOK_URL - Your n8n webhook endpoint"
    exit 1
fi

# Create JSON payload
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

echo "Distributing to social media..."
echo "Artist: $ARTIST_NAME"
echo "Song: $SONG_TITLE"
echo "Link: $HYPERFOLLOW_LINK"
echo ""

# Send to n8n webhook
RESPONSE=$(curl -s -X POST "$N8N_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if [ $? -eq 0 ]; then
    echo "✅ Successfully sent to n8n workflow!"
    echo "Response: $RESPONSE"
else
    echo "❌ Failed to send to n8n workflow"
    echo "Response: $RESPONSE"
    exit 1
fi
