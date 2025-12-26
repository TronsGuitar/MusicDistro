# n8n HyperFollow Social Media Distribution Template

## Overview

This n8n workflow template automates the distribution of your HyperFollow music links across all major social media platforms with a single webhook call. Perfect for music releases, it generates platform-specific messages and posts them simultaneously to maximize your reach.

## Supported Platforms

✅ **Twitter/X** - Optimized for 280 characters with hashtags
✅ **Facebook** - Page posts with detailed release information
✅ **LinkedIn** - Professional-toned announcements
✅ **Telegram** - Channel/group notifications
✅ **Discord** - Server announcements via webhooks
⚠️ **Instagram** - Requires Business Account (disabled by default, see setup)

## Features

- 🚀 **One-Click Distribution** - Post to all platforms with a single API call
- 📝 **Smart Message Generation** - Platform-specific messages tailored to each network's best practices
- 🎨 **Customizable Messages** - Override default messages with your own copy
- 🔗 **HyperFollow Integration** - Designed specifically for music distribution links
- 📊 **Activity Logging** - Track successful posts and errors
- ⚡ **Parallel Execution** - Posts to all platforms simultaneously for speed

## Installation

### 1. Import the Workflow

1. Open your n8n instance
2. Click **Workflows** → **Import from File**
3. Select `n8n-hyperfollow-distribution.json`
4. Click **Import**

### 2. Configure Platform Credentials

You'll need to set up OAuth/API credentials for each platform you want to use:

#### Twitter/X
1. Go to [Twitter Developer Portal](https://developer.twitter.com/en/portal/dashboard)
2. Create a new app with OAuth 2.0 enabled
3. Enable permissions: `tweet.read` and `tweet.write`
4. In n8n, add credentials for "Twitter OAuth2 API"
5. Complete the OAuth flow

#### Facebook (for Pages)
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create an app with the Facebook Login product
3. Request permissions: `pages_manage_posts`, `pages_read_engagement`
4. In n8n, add credentials for "Facebook Graph API"
5. Enter your Page ID in the "Post to Facebook" node

#### LinkedIn
1. Go to [LinkedIn Developers](https://www.linkedin.com/developers/)
2. Create an app and request the "Share on LinkedIn" product
3. Get `r_liteprofile` and `w_member_social` permissions
4. In n8n, add credentials for "LinkedIn OAuth2 API"

#### Telegram
1. Message [@BotFather](https://t.me/botfather) on Telegram
2. Create a new bot with `/newbot`
3. Copy the API token
4. Get your channel/group Chat ID (use [@userinfobot](https://t.me/userinfobot))
5. In n8n, add credentials for "Telegram API"
6. Update the `chatId` parameter in the "Post to Telegram" node

#### Discord
1. Create a webhook in your Discord server:
   - Server Settings → Integrations → Webhooks → New Webhook
2. Copy the webhook URL
3. Paste it into the `webhookUri` parameter in the "Post to Discord" node

#### Instagram (Optional)
1. Convert your Instagram account to a Business Account
2. Link it to a Facebook Page
3. Get your Instagram Account ID from the Facebook Graph API:
   ```bash
   curl "https://graph.facebook.com/v18.0/me/accounts?access_token=YOUR_TOKEN"
   ```
4. Enable the "Create Instagram Post" node
5. Add your Instagram Account ID
6. **Note:** Requires an image URL - you'll need to host your cover art

### 3. Activate the Workflow

1. Click the **Inactive** toggle to activate
2. Copy the webhook URL from the Webhook node
3. Save the workflow

## Usage

### Webhook Endpoint

Send a POST request to your webhook URL with the following JSON payload:

```json
{
  "hyperfollow_link": "https://hyperfollow.com/your-artist/your-song",
  "artist_name": "Your Artist Name",
  "song_title": "Your Song Title",
  "release_date": "2025-01-15",
  "custom_message": "So excited to share this new track with you all! 🎵"
}
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `hyperfollow_link` | ✅ Yes | Your HyperFollow URL |
| `artist_name` | ✅ Yes | Artist/band name |
| `song_title` | ✅ Yes | Track title |
| `release_date` | ✅ Yes | Release date (YYYY-MM-DD) |
| `custom_message` | ❌ No | Custom message (falls back to default) |

### Example with cURL

```bash
curl -X POST https://your-n8n-instance.com/webhook/hyperfollow-distribute \
  -H "Content-Type: application/json" \
  -d '{
    "hyperfollow_link": "https://hyperfollow.com/artist/new-song",
    "artist_name": "The Music Makers",
    "song_title": "Digital Dreams",
    "release_date": "2025-01-15",
    "custom_message": "After months in the studio, here it is! 🎵"
  }'
```

### Example with Python

```python
import requests

payload = {
    "hyperfollow_link": "https://hyperfollow.com/artist/new-song",
    "artist_name": "The Music Makers",
    "song_title": "Digital Dreams",
    "release_date": "2025-01-15",
    "custom_message": "After months in the studio, here it is! 🎵"
}

response = requests.post(
    "https://your-n8n-instance.com/webhook/hyperfollow-distribute",
    json=payload
)

print(response.json())
```

### Integration with GitHub Actions

Add this step to your workflow after the mastering process:

```yaml
- name: Distribute to Social Media
  if: github.ref == 'refs/heads/main'
  run: |
    curl -X POST ${{ secrets.N8N_WEBHOOK_URL }} \
      -H "Content-Type: application/json" \
      -d '{
        "hyperfollow_link": "${{ secrets.HYPERFOLLOW_LINK }}",
        "artist_name": "${{ secrets.ARTIST_NAME }}",
        "song_title": "${{ github.event.head_commit.message }}",
        "release_date": "${{ github.event.head_commit.timestamp }}",
        "custom_message": "New release is live! 🎵"
      }'
```

## Message Templates

The workflow automatically generates platform-optimized messages:

### Twitter/X (280 chars max)
```
🎵 New Release Alert! 🎵

"Digital Dreams" by The Music Makers is now available on all streaming platforms!

🎧 Listen now: https://hyperfollow.com/...

#NewMusic #TheMusicMakers #MusicRelease
```

### Facebook
```
🎵 New Release Alert! 🎵

"Digital Dreams" by The Music Makers is now available on all streaming platforms!

Release Date: 2025-01-15

🎧 Stream on your favorite platform: https://hyperfollow.com/...

Thank you for your support! 🙏
```

### LinkedIn (Professional)
```
Excited to announce the release of "Digital Dreams"!

This new track represents my latest creative work and is now available across all major streaming platforms.

Listen here: https://hyperfollow.com/...

#MusicProduction #NewRelease #IndependentArtist
```

### Telegram/Discord
```
🎉 NEW RELEASE 🎉

The Music Makers - "Digital Dreams"

After months in the studio, here it is! 🎵

🎧 https://hyperfollow.com/...

Enjoy and share with your friends!
```

## Troubleshooting

### Common Issues

**"Authentication failed"**
- Re-authenticate your credentials in n8n
- Check that your app has the required permissions
- Verify tokens haven't expired

**"Rate limit exceeded"**
- Twitter: Wait 15 minutes between posts
- Facebook: Max 50 posts per day per page
- Add delay nodes between platform posts if needed

**"Webhook not responding"**
- Ensure the workflow is activated
- Check n8n instance is running and accessible
- Verify webhook URL is correct

**Instagram posts not working**
- Instagram requires an image URL
- Business account must be linked to a Facebook Page
- Enable the Instagram node (disabled by default)

### Error Handling

The workflow will continue posting to other platforms even if one fails. Check the execution logs in n8n to see which platforms succeeded and which failed.

## Advanced Customization

### Add More Platforms

1. **Mastodon**: Add HTTP Request node to post to Mastodon API
2. **Threads**: Use unofficial API or wait for official support
3. **TikTok**: Currently requires manual posting (no official API for posts)
4. **YouTube Community**: Use YouTube Data API v3

### Schedule Posts

Replace the Webhook node with a Schedule Trigger to post at specific times:
1. Replace "Webhook" with "Schedule Trigger"
2. Set your desired posting time
3. Store release data in a database or Google Sheets
4. Pull data in the "Set Variables" node

### Add Image Support

1. Host your cover art (Imgur, Cloudinary, S3, etc.)
2. Add `cover_image_url` to the webhook payload
3. Update social media nodes to include the image

### Custom Hashtag Strategy

Edit the "Generate Messages" code node to customize hashtags:
```javascript
// Add genre-specific hashtags
const genre = $input.item.json.genre || 'music';
const genreHashtag = `#${genre.toLowerCase()}`;

const twitterMessage = `${baseMessage}\n\n🎧 Listen: ${link}\n\n#NewMusic ${genreHashtag} #IndieArtist`;
```

## Best Practices

1. **Test First**: Use n8n's "Test Workflow" before going live
2. **Backup Credentials**: Save your API keys securely
3. **Monitor Executions**: Check n8n logs after each release
4. **Customize Messages**: Tailor the default messages to your brand voice
5. **Timing**: Post during peak engagement hours (evening in your audience's timezone)
6. **Compliance**: Ensure you have rights to post on behalf of pages/accounts
7. **Link Shorteners**: Consider using bit.ly for tracking if HyperFollow links are long

## Security Notes

- **Never commit credentials** to git repositories
- Use n8n's credential encryption
- If self-hosting, use HTTPS for webhook endpoints
- Rotate API tokens regularly
- Use environment variables for sensitive data

## Support & Resources

- [n8n Documentation](https://docs.n8n.io/)
- [HyperFollow](https://hyperfollow.com/)
- [n8n Community Forum](https://community.n8n.io/)

## License

This template is provided as-is for use with your n8n instance. Modify and distribute freely.

---

**Made for independent artists by the MusicDistro project** 🎵
