# Complete Music Distribution Workflow
## From Suno to Streaming to Social Media

This guide walks you through the entire process of taking a song from Suno AI to all streaming platforms and social media.

---

## Table of Contents
1. [Download from Suno](#step-1-download-from-suno)
2. [Setup GitHub Repository](#step-2-setup-github-repository)
3. [Upload for Pre-Mastering](#step-3-upload-for-pre-mastering)
4. [Download Mastered Track](#step-4-download-mastered-track)
5. [Upload to Distribution](#step-5-upload-to-distribution)
6. [Setup n8n Workflow](#step-6-setup-n8n-workflow)
7. [Distribute to Social Media](#step-7-distribute-to-social-media)

---

## Step 1: Download from Suno

### 1.1 Generate Your Song
1. Go to [Suno.ai](https://suno.ai)
2. Create your song using prompts or custom mode
3. Wait for generation to complete

### 1.2 Download the Audio File
1. Click on your generated song
2. Click the **"..."** menu (three dots)
3. Select **"Download"** 
4. Choose **"Download Audio"** (this gives you the highest quality available)
5. The file downloads as an MP3 (typically 320kbps)

### 1.3 Convert to WAV (if needed)

**Option A: Using Online Converter**
1. Go to [CloudConvert](https://cloudconvert.com/mp3-to-wav) or similar
2. Upload your MP3
3. Select output format: **WAV**
4. Advanced settings (optional):
   - Audio Codec: PCM
   - Frequency: 48000 Hz
   - Channels: Stereo
5. Click **"Convert"**
6. Download the WAV file

**Option B: Using FFmpeg (Command Line)**
```bash
ffmpeg -i suno_song.mp3 -ar 48000 -sample_fmt s16 suno_song.wav
```

**Option C: Using Audacity**
1. Open Audacity
2. File → Open → Select your MP3
3. File → Export → Export as WAV
4. Choose settings:
   - Format: WAV (Microsoft)
   - Encoding: Signed 16-bit PCM
   - Sample Rate: 48000 Hz
5. Click **"Export"**

### 1.4 Name Your File
Rename with a clear format:
```
ArtistName_-_SongTitle.wav
```
Example: `John_Smith_-_Digital_Dreams.wav`

**Important**: Use underscores, no spaces or special characters

---

## Step 2: Setup GitHub Repository

### 2.1 Fork or Clone MusicDistro
1. Go to the [MusicDistro repository](https://github.com/TronsGuitar/MusicDistro)
2. Click **"Fork"** to create your own copy
3. Or clone it locally:
   ```bash
   git clone https://github.com/TronsGuitar/MusicDistro.git
   cd MusicDistro
   ```

### 2.2 Create the Inbox Folder (if it doesn't exist)
```bash
mkdir -p inbox
```

### 2.3 Setup GitHub Secrets (Optional)
If you want to embed metadata like ISRC codes:

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Add these secrets:
   - `ISRC_CODE`: Your ISRC code (optional)
   - `ARTIST_NAME`: Your artist name
   - `N8N_WEBHOOK_URL`: Your n8n webhook URL (for later)

---

## Step 3: Upload for Pre-Mastering

### 3.1 Add Your WAV File

**Option A: Via Git (Command Line)**
```bash
# Navigate to your repo
cd MusicDistro

# Copy your WAV to inbox
cp ~/Downloads/ArtistName_-_SongTitle.wav inbox/

# Add and commit
git add inbox/ArtistName_-_SongTitle.wav
git commit -m "Add new song: SongTitle for pre-mastering"

# Push to GitHub
git push origin main
```

**Option B: Via GitHub Web Interface**
1. Go to your repository on GitHub.com
2. Navigate to the `inbox/` folder (create it if needed)
3. Click **"Add file"** → **"Upload files"**
4. Drag and drop your WAV file
5. Add commit message: "Add new song for pre-mastering"
6. Click **"Commit changes"**

**Option C: Via GitHub Desktop**
1. Open GitHub Desktop
2. Select your MusicDistro repository
3. Copy WAV file to `inbox/` folder
4. GitHub Desktop will detect the change
5. Add commit message
6. Click **"Commit to main"**
7. Click **"Push origin"**

### 3.2 Verify GitHub Actions Started
1. Go to your repository on GitHub
2. Click the **"Actions"** tab
3. You should see a workflow running: "Pre-master WAV files"
4. Click on it to watch progress
5. Wait for completion (usually 1-3 minutes)

---

## Step 4: Download Mastered Track

### 4.1 Access Workflow Artifacts
1. Once the workflow completes (green checkmark ✅)
2. Click on the completed workflow run
3. Scroll down to **"Artifacts"** section
4. You'll see downloadable files:
   - `premaster-wavs` - Your processed audio file
   - `qc-reports` - Quality control analysis

### 4.2 Download the Files
1. Click **"premaster-wavs"** to download
2. Click **"qc-reports"** to download
3. Extract the ZIP files
4. Your mastered track will be named similarly to your original

### 4.3 Review QC Report
Open the `.txt` QC report to see:
- LUFS (loudness) measurements
- True peak levels
- Dynamic range
- Sample rate confirmation

**What to look for:**
- LUFS should be around -14 to -10 (streaming standard)
- True peak should be below -1.0 dBFS
- No clipping warnings

---

## Step 5: Upload to Distribution

### 5.1 Choose Your Distributor

**Popular Options:**
- **DistroKid** - $20/year unlimited uploads
- **TuneCore** - Pay per release
- **CD Baby** - One-time fee per release
- **Amuse** - Free tier available

### 5.2 Upload to DistroKid (Example)

1. **Log in to DistroKid**
   - Go to [distrokid.com](https://distrokid.com)
   - Click **"Upload"**

2. **Choose Distribution Type**
   - Select **"Single"** or **"Album"**
   - Click **"Next"**

3. **Upload Audio File**
   - Click **"Choose Audio File"**
   - Select your mastered WAV from Step 4
   - Wait for upload to complete

4. **Enter Metadata**
   - **Artist Name**: Your artist name
   - **Song Title**: Your song title
   - **Genre**: Select appropriate genre
   - **Release Date**: Choose your date
   - **Language**: Primary language
   - **Explicit**: Yes/No
   - **ISRC**: Auto-generate or paste your own

5. **Upload Cover Art**
   - Requirements:
     - Minimum 3000x3000 pixels
     - Square (1:1 ratio)
     - JPG or PNG
     - No borders, text overlays, or contact info
   - Click **"Choose Artwork"**
   - Upload your cover image

6. **Select Streaming Platforms**
   - ✅ Spotify
   - ✅ Apple Music
   - ✅ Amazon Music
   - ✅ YouTube Music
   - ✅ TikTok
   - ✅ Instagram/Facebook
   - ✅ Tidal
   - ✅ Deezer
   - Enable **YouTube Content ID** (recommended)
   - Enable **Facebook/Instagram monetization** (recommended)

7. **Enter Credits & Splits**
   - Add songwriter names
   - Set publishing splits if applicable
   - Add producer credits
   - Add any featured artists

8. **Review & Submit**
   - Review all information carefully
   - Click **"Submit"**
   - Pay if required
   - Confirm submission

### 5.3 Create HyperFollow Link (DistroKid)

1. After submission, go to **"Music"** in DistroKid
2. Find your song (it might say "Processing" or "Pending")
3. Click **"HyperFollow"**
4. Click **"Create HyperFollow Page"**
5. Customize your landing page:
   - Add description
   - Choose theme/colors
   - Add social links
6. Click **"Save"**
7. **Copy the HyperFollow URL** - Example: `https://distrokid.com/hyperfollow/yourartist/yoursong`

**Important**: Save this URL! You'll need it for Step 7.

### 5.4 Alternative: Create Link Manually

If not using DistroKid's HyperFollow, use these alternatives:

**Linkfire**
1. Go to [linkfire.com](https://linkfire.com)
2. Create a free account
3. Add your streaming links manually
4. Generate smart link

**ToneDen (Spotify Smart Links)**
1. Go to [toneden.io](https://www.toneden.io/smartlinks)
2. Paste your Spotify link
3. It auto-finds other platforms
4. Customize and save

**Feature.fm**
1. Go to [feature.fm](https://feature.fm)
2. Create landing page
3. Add all streaming links
4. Get shareable URL

---

## Step 6: Setup n8n Workflow

### 6.1 Install n8n

**Option A: n8n Cloud (Easiest)**
1. Go to [n8n.cloud](https://n8n.cloud)
2. Sign up for free trial
3. Skip to Step 6.2

**Option B: Self-Hosted (Docker)**
```bash
docker volume create n8n_data
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  docker.n8n.io/n8nio/n8n
```
Access at: `http://localhost:5678`

**Option C: npm**
```bash
npm install n8n -g
n8n start
```

### 6.2 Import the Workflow

1. **Download the template** from your MusicDistro repo:
   - File: `n8n-hyperfollow-distribution.json`

2. **Import to n8n**:
   - Open n8n web interface
   - Click **"Workflows"** → **"Import from File"**
   - Select `n8n-hyperfollow-distribution.json`
   - Click **"Import"**

### 6.3 Configure Social Media Credentials

You need to set up OAuth/API access for each platform you want to use.

#### Twitter/X Setup

1. **Create Twitter App**:
   - Go to [developer.twitter.com](https://developer.twitter.com/en/portal/dashboard)
   - Sign in with your Twitter account
   - Click **"Create Project"** → **"Create App"**
   - App name: "Music Distribution Bot"
   - Get your API keys

2. **Add to n8n**:
   - In n8n, click **"Credentials"** → **"New"**
   - Search for **"Twitter OAuth2 API"**
   - Enter your Client ID and Client Secret
   - Click **"Connect"** and authorize
   - Save

3. **Update the workflow node**:
   - Open the "Post to Twitter/X" node
   - Select your Twitter credentials
   - Save

#### Facebook Setup

1. **Create Facebook App**:
   - Go to [developers.facebook.com](https://developers.facebook.com)
   - Click **"Create App"**
   - Choose **"Business"** type
   - Add **"Facebook Login"** product
   - Get permissions: `pages_manage_posts`, `pages_read_engagement`

2. **Get your Page ID**:
   - Go to your Facebook Page
   - Click **"About"**
   - Scroll to bottom - copy Page ID
   - Or use: `https://facebook.com/YOUR_PAGE_NAME` and inspect

3. **Add to n8n**:
   - Click **"Credentials"** → **"New"**
   - Search for **"Facebook Graph API"**
   - Enter your credentials
   - Authorize
   - Save

4. **Update workflow**:
   - Open "Post to Facebook" node
   - Select credentials
   - Enter your Page ID in the `pageId` field
   - Save

#### LinkedIn Setup

1. **Create LinkedIn App**:
   - Go to [linkedin.com/developers](https://www.linkedin.com/developers/)
   - Click **"Create app"**
   - Fill in details
   - Request **"Share on LinkedIn"** product
   - Get `r_liteprofile` and `w_member_social` permissions

2. **Add to n8n**:
   - Click **"Credentials"** → **"New"**
   - Search for **"LinkedIn OAuth2 API"**
   - Enter Client ID and Secret
   - Authorize
   - Save

#### Telegram Setup

1. **Create Telegram Bot**:
   - Open Telegram app
   - Search for `@BotFather`
   - Send: `/newbot`
   - Follow prompts to name your bot
   - Copy the **API Token**

2. **Get Chat ID**:
   - Add your bot to your channel/group
   - Make it an admin
   - To get Chat ID:
     - Search for `@userinfobot`
     - Send any message
     - It will reply with your Chat ID
   - OR for channels: `-100` + channel ID

3. **Add to n8n**:
   - Click **"Credentials"** → **"New"**
   - Search for **"Telegram API"**
   - Paste your API Token
   - Save

4. **Update workflow**:
   - Open "Post to Telegram" node
   - Select credentials
   - Enter your Chat ID
   - Save

#### Discord Setup

1. **Create Webhook**:
   - Open Discord
   - Go to your server
   - Right-click the channel → **"Edit Channel"**
   - Click **"Integrations"** → **"Webhooks"**
   - Click **"New Webhook"**
   - Name it "Music Releases"
   - Copy the **Webhook URL**

2. **Update workflow**:
   - Open "Post to Discord" node
   - Paste webhook URL into `webhookUri` field
   - Save

### 6.4 Activate the Workflow

1. Click the **"Inactive"** toggle at top
2. It should turn green: **"Active"**
3. Click on the **"Webhook"** node
4. Copy the **"Production URL"**
   - Example: `https://your-n8n.cloud/webhook/hyperfollow-distribute`
5. **Save this URL** - you'll need it for Step 7!

---

## Step 7: Distribute to Social Media

### 7.1 Wait for Release to Go Live

1. Check your distributor dashboard
2. Wait for your song to be **"Live"** on streaming platforms
3. Verify it appears on:
   - Spotify
   - Apple Music
   - YouTube Music
   - etc.

**Typical timeline:**
- DistroKid: 1-7 days
- TuneCore: 3-14 days
- CD Baby: 2-4 weeks

### 7.2 Prepare Your Information

Gather the following:
- ✅ Your HyperFollow/Smart Link URL
- ✅ Artist name
- ✅ Song title
- ✅ Release date
- ✅ Custom message (optional)

### 7.3 Trigger the n8n Workflow

**Option A: Using cURL (Command Line)**

```bash
curl -X POST https://your-n8n.cloud/webhook/hyperfollow-distribute \
  -H "Content-Type: application/json" \
  -d '{
    "hyperfollow_link": "https://distrokid.com/hyperfollow/yourartist/yoursong",
    "artist_name": "Your Artist Name",
    "song_title": "Your Song Title",
    "release_date": "2025-01-15",
    "custom_message": "So excited to finally share this with you all! 🎵 Been working on this for months!"
  }'
```

**Option B: Using the Helper Script**

```bash
cd MusicDistro/examples
chmod +x distribute.sh

export N8N_WEBHOOK_URL="https://your-n8n.cloud/webhook/hyperfollow-distribute"

./distribute.sh \
  "https://distrokid.com/hyperfollow/yourartist/yoursong" \
  "Your Artist Name" \
  "Your Song Title" \
  "2025-01-15" \
  "So excited to share this! 🎵"
```

**Option C: Using Postman/Insomnia**

1. Open Postman or Insomnia
2. Create a new **POST** request
3. URL: Your n8n webhook URL
4. Headers:
   - `Content-Type`: `application/json`
5. Body (raw JSON):
```json
{
  "hyperfollow_link": "https://distrokid.com/hyperfollow/yourartist/yoursong",
  "artist_name": "Your Artist Name",
  "song_title": "Your Song Title",
  "release_date": "2025-01-15",
  "custom_message": "So excited to finally share this with you all! 🎵"
}
```
6. Click **Send**

**Option D: Using Python**

```python
import requests

payload = {
    "hyperfollow_link": "https://distrokid.com/hyperfollow/yourartist/yoursong",
    "artist_name": "Your Artist Name",
    "song_title": "Your Song Title",
    "release_date": "2025-01-15",
    "custom_message": "So excited to finally share this! 🎵"
}

response = requests.post(
    "https://your-n8n.cloud/webhook/hyperfollow-distribute",
    json=payload
)

print("Status:", response.status_code)
print("Response:", response.json())
```

**Option E: Using a Web Form**

Create a simple HTML form:

```html
<!DOCTYPE html>
<html>
<body>
  <h2>Music Release Distributor</h2>
  <form id="releaseForm">
    <input type="url" id="link" placeholder="HyperFollow Link" required><br>
    <input type="text" id="artist" placeholder="Artist Name" required><br>
    <input type="text" id="song" placeholder="Song Title" required><br>
    <input type="date" id="date" required><br>
    <textarea id="message" placeholder="Custom message (optional)"></textarea><br>
    <button type="submit">Distribute to Social Media</button>
  </form>

  <script>
    document.getElementById('releaseForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const payload = {
        hyperfollow_link: document.getElementById('link').value,
        artist_name: document.getElementById('artist').value,
        song_title: document.getElementById('song').value,
        release_date: document.getElementById('date').value,
        custom_message: document.getElementById('message').value
      };

      const response = await fetch('https://your-n8n.cloud/webhook/hyperfollow-distribute', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      if (response.ok) {
        alert('Successfully distributed to social media! ✅');
      } else {
        alert('Error: ' + response.statusText);
      }
    });
  </script>
</body>
</html>
```

### 7.4 Verify Posts Went Live

1. **Check n8n execution**:
   - Open n8n
   - Click **"Executions"**
   - Check latest execution
   - Verify all nodes completed successfully (green checkmarks)

2. **Check each platform**:
   - ✅ Twitter/X - Check your profile
   - ✅ Facebook - Check your Page
   - ✅ LinkedIn - Check your feed
   - ✅ Telegram - Check your channel
   - ✅ Discord - Check your server

3. **If a platform failed**:
   - Check n8n error logs
   - Verify credentials are still valid
   - Re-authorize if needed
   - Try posting manually to that platform

---

## Troubleshooting

### GitHub Actions Not Running
- **Check**: Workflow file exists at `.github/workflows/premaster.yml`
- **Check**: You pushed to the correct branch (usually `main`)
- **Check**: Workflow is enabled in Settings → Actions
- **Fix**: Re-push or manually trigger from Actions tab

### n8n Webhook Returns Error
- **401 Unauthorized**: Check credentials for each platform
- **403 Forbidden**: Check API permissions
- **500 Server Error**: Check n8n logs for details
- **Timeout**: Check internet connection and n8n instance status

### DistroKid Upload Failed
- **Audio format**: Must be WAV or FLAC
- **Cover art**: Must be exactly square, minimum 3000x3000px
- **ISRC**: Can leave blank to auto-generate
- **Metadata**: All required fields must be filled

### Social Media Post Didn't Appear
- **Twitter**: Check character limit (280)
- **Facebook**: Check if page has posting permissions
- **LinkedIn**: Verify account has sharing permissions
- **Telegram**: Verify bot is admin in channel
- **Discord**: Verify webhook URL is correct and active

---

## Tips for Success

### Audio Quality
- ✅ Use the mastered WAV from GitHub Actions, not the original
- ✅ Review the QC report before uploading
- ✅ Test the audio file plays correctly
- ✅ Check for clipping or distortion

### Metadata
- ✅ Use consistent artist name across all platforms
- ✅ Include songwriter and producer credits
- ✅ Add ISRC if you have one (increases royalty tracking)
- ✅ Choose the most accurate genre

### Cover Art
- ✅ Use 3000x3000px or higher
- ✅ No phone numbers, websites, or social handles
- ✅ High quality, professional design
- ✅ Export as JPG (smaller file size) or PNG (best quality)

### Social Media
- ✅ Post during peak hours (7-9 PM in your audience's timezone)
- ✅ Customize the message for your style
- ✅ Engage with comments quickly
- ✅ Pin the post on your profiles
- ✅ Add the link to your bio/about section

### Timing
- ✅ Schedule your release 2-4 weeks in advance
- ✅ Build anticipation with pre-release content
- ✅ Post teasers 1 week before
- ✅ Go live with social posts on release day
- ✅ Follow up 1 week later with "in case you missed it"

---

## Complete Checklist

Use this checklist for each release:

### Pre-Release (2-4 weeks before)
- [ ] Generate song on Suno
- [ ] Download as MP3
- [ ] Convert to WAV
- [ ] Upload to MusicDistro/inbox
- [ ] Wait for GitHub Actions to complete
- [ ] Download mastered track
- [ ] Review QC report
- [ ] Create cover art (3000x3000px)
- [ ] Upload to distributor
- [ ] Create HyperFollow/smart link
- [ ] Schedule release date

### Release Day
- [ ] Verify song is live on all platforms
- [ ] Test HyperFollow link
- [ ] Prepare custom social message
- [ ] Trigger n8n workflow
- [ ] Verify posts on all platforms
- [ ] Pin posts to profiles
- [ ] Update bio links
- [ ] Engage with comments

### Post-Release (1 week after)
- [ ] Check streaming stats
- [ ] Post "thank you" message
- [ ] Share user-generated content
- [ ] Plan next release

---

## Next Steps

### Automation Ideas
1. **GitHub Actions → n8n integration**: Auto-trigger social posts when mastering completes
2. **Scheduled posts**: Use n8n schedule trigger for optimal timing
3. **Analytics tracking**: Add UTM parameters to links
4. **A/B testing**: Try different messages and track performance

### Advanced Features
1. **Add Mastodon support**: Use HTTP Request node with Mastodon API
2. **Add Reddit posting**: Create app and use Reddit API
3. **Email newsletter**: Integrate with Mailchimp/SendGrid
4. **SMS notifications**: Use Twilio for text message announcements

### Resources
- [DistroKid Help Center](https://support.distrokid.com)
- [n8n Documentation](https://docs.n8n.io)
- [Suno AI Community](https://suno.ai/community)
- [Music Marketing Guide](https://www.hypebot.com)

---

## Support

If you run into issues:
1. Check the troubleshooting section above
2. Review n8n execution logs
3. Check GitHub Actions logs
4. Open an issue on [MusicDistro GitHub](https://github.com/TronsGuitar/MusicDistro/issues)

---

**Congratulations!** You now have a complete automated music distribution pipeline! 🎵🚀

From Suno to streaming to social media - all automated and repeatable for every release.
