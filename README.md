# MusicDistro
A complete automation toolkit for independent music distribution - from pre-mastering to social media distribution.

## Features

🎵 **GitHub Actions Pre-Mastering** - Automated WAV file preparation for distribution networks
🚀 **n8n Social Media Distribution** - One-click distribution of HyperFollow links to all major social platforms
📊 **Quality Control** - Automated LUFS and true-peak analysis
🔗 **End-to-End Pipeline** - From raw mix to streaming platforms and social media


Below is a practical end-to-end checklist you can fold into an automated “pre-master → Mixea → release” pipeline. Everything marked 🛠 Scriptable can be done from the command line (ffmpeg/sox/bwfmetaedit) or in Python (mutagen/pydub + ffmpeg).

1 Render a clean pre-master
Target	Why
24-bit or 16-bit PCM WAV, 44.1 kHz or 48 kHz stereo	These are the only formats Mixea/DistroKid accept; higher rates will simply be down-sampled in the browser 
support.distrokid.com
Peak headroom ≈ -3 dBFS, no brick-wall limiting	Gives Mixea room to apply its own loudness curve, avoiding inter-sample clipping
No dither until your final bit-depth change	Keeps noise-shaping predictable
Clean tails, no DC-offset, start/stop on zero-crossings	Prevents clicks in the mastered file

🛠 Scriptable:

bash
Copy
Edit
sox raw_mix.wav -b24 -r48k premaster.wav \
    gain -n -3 rate -v 48000 dither
2 Metadata—keep it minimal
You don’t need any embedded tags for DistroKid. The upload form you fill out overrides (and streaming services ignore) whatever is inside the file 
support.distrokid.com
.

Embedding ISRC (the “monetary ID”) is optional; DistroKid will generate one automatically or lets you paste your own in the form. Embedding it in a BWF “ISRC” chunk won’t hurt, but it also won’t raise your royalty rate. 
support.distrokid.com

If you still want tags for local archiving:

🛠 Scriptable (Python—mutagen for RIFF/INFO, eyed3 for MP3 once mastered):

python
Copy
Edit
from mutagen.wave import WAVE
tags = WAVE("premaster.wav")
tags["IART"] = "Your Artist"
tags["INAM"] = "Song Title"
tags["ISRC"] = "QM24S2500010"
tags.save()
3 Automate quality gates before upload
Check	CLI / Python example
True-peak & LUFS	ffmpeg -i premaster.wav -filter:a loudnorm=print_format=summary -f null -
Spectral cleanup / resampler sanity	sox --i -r premaster.wav to confirm 44.1 k/48 k
File-naming guard	Regex-rename: Artist_-_Title_v01.wav (ASCII + underscores only)

Put those steps in a Makefile, GitHub Action, or a local pre-commit hook so bad files never reach Mixea.

4 Use Mixea (DistroKid Mastering)
Drag-and-drop the premaster.wav into Mixea.

Choose the flavor that matches your genre; preview the loudness difference.

Download the mastered WAV (again 16- or 24-bit).

Upload that master to DistroKid’s “Upload” page and enter your metadata manually.

Mixea itself does not look at embedded metadata; it only needs audio 
support.distrokid.com
.

5 Maximize royalties
Tick YouTube Content ID, Facebook/Instagram monetization, etc., on the DistroKid upload page.

Make sure the correct songwriters and publisher shares are filled out (DistroKid passes these to PROs & MLC).

Deliver the final WAV at full resolution—DistroKid transcodes, but payouts are stream-based, not file-size-based, so there’s no penalty for higher fidelity.

6 Putting it all together
A minimal bash pipeline:

bash
Copy
Edit
#!/usr/bin/env bash
set -e

INPUT=$1                # raw_mix.wav
OUT=premaster.wav
ISRC=QM24S2500010       # or leave blank

# 1. Render & clean
sox "$INPUT" -b24 -r48k "$OUT" gain -n -3 rate -v 48000 dither

# 2. Optional tags
bwfmetaedit --ISRC="$ISRC" "$OUT"

# 3. QC report
ffmpeg -i "$OUT" -filter:a loudnorm=print_format=summary -f null - | tee qc.txt
Trigger that script from your DAW’s export macro or a GitHub Action. The only manual steps left are Mixea’s artistic choices and the brief DistroKid upload form.

TL;DR
Focus on audio quality; Mixea & DSPs don’t care about embedded metadata.
Generate a clean 24-bit or 16-bit WAV with -3 dBFS headroom, run your QC script, then let DistroKid assign the ISRC and metadata in their web form. Automating the bounce, tag stub, and QC checks gets you 90 % of the way to hands-free releases—without leaving money on the table.

I wonder if I could create an action that runs when I upload the wav file song into a github folder that does all of the tasks.


.github/workflows/premaster

Answer in chat instead
I’ve dropped a ready-to-paste GitHub Actions workflow into the canvas. Here’s what it does and how to tailor it:

How the workflow works
Trigger – Fires on every push that adds a .wav under inbox/.

Environment setup – Installs SoX, FFmpeg, BWF MetaEdit, Git LFS, and the Mutagen Python lib on an Ubuntu runner.

Processing loop – For each new WAV it:

creates a 24-bit 48 kHz premaster with -3 dBFS headroom

optionally embeds the ISRC you store as a repo secret (ISRC_CODE)

prints LUFS + true-peak stats to a per-file QC text report

Artifacts – Uploads the cleaned WAVs and QC logs so you can grab them from the Actions run page.

(Optional) auto-commits processed files back to the repo—uncomment the last step and add a PAT if you’d like that.

Things you still need to decide
Decision	Why it matters	Quick answer
Git LFS vs. normal Git	WAVs over 100 MB can’t be pushed via plain Git ➜ use LFS or keep them < 100 MB. 
docs.github.com
For typical 3–4 min 24-bit WAVs you’ll be under ~70 MB, so plain Git is fine.
Where to store secrets	ISRC, any PAT for commits, and maybe Mixea flavor choices.	Settings → Secrets & variables → Actions → New secret.
Output destination	Downloading artifacts is simplest; auto-committing needs a PAT with repo scope.	Start with artifacts—flip the switch later if you want in-repo files.
Mastering step	Mixea/DistroKid still needs manual ears for the “sound” choice.	Keep that human; the action just guarantees a clean premaster.

Extending or chaining
Format checks – Add SoX’s --i or soxi calls if you want hard-fail validation.

Continuous delivery – You could add a second job that, on workflow_run success, posts the artifacts to a private S3 bucket or Notion link for collaborators.

Notifications – Use actions/upload-artifact + slackapi/slack-github-action to DM yourself the LUFS report.

Gotchas
GitHub’s free tier gives 2 GB of Actions artifact storage per repo; clean old runs if you accumulate many WAVs.

Each Actions run tops out at 6 hours and 14 GB of RAM—plenty for audio but worth knowing.

If you ever process >2 GB in one push, GitHub’s push hard-limit kicks in. 
docs.github.com

Feel free to tweak the YAML right in the canvas—let me know what else you'd like automated!

## Social Media Distribution with n8n

After your music is live on streaming platforms, automate sharing your HyperFollow links across all social networks with our n8n workflow template.

### Quick Start

1. **Import the template**: `n8n-hyperfollow-distribution.json`
2. **Configure credentials** for your social platforms (Twitter, Facebook, LinkedIn, Telegram, Discord)
3. **Activate the workflow** and copy the webhook URL
4. **Send a POST request** with your release details:

```bash
curl -X POST https://your-n8n.com/webhook/hyperfollow-distribute \
  -H "Content-Type: application/json" \
  -d '{
    "hyperfollow_link": "https://hyperfollow.com/artist/song",
    "artist_name": "Your Name",
    "song_title": "Song Title",
    "release_date": "2025-01-15",
    "custom_message": "New music out now! 🎵"
  }'
```

### Supported Platforms

✅ Twitter/X | ✅ Facebook | ✅ LinkedIn | ✅ Telegram | ✅ Discord | ⚠️ Instagram*

*Instagram requires a Business Account and image URL

### Features

- **Platform-optimized messages** - Tailored content for each social network
- **Parallel posting** - Distribute to all platforms simultaneously
- **Smart hashtag generation** - Automatic hashtags based on artist/song
- **Error resilience** - Continues posting even if one platform fails
- **Customizable templates** - Edit messages to match your brand voice

📖 **Full documentation**: See `n8n-setup-guide.md` for complete setup instructions

### Integration with GitHub Actions

Combine pre-mastering and social distribution:

```yaml
- name: Distribute to Social Media
  if: success()
  run: |
    curl -X POST ${{ secrets.N8N_WEBHOOK_URL }} \
      -H "Content-Type: application/json" \
      -d '{
        "hyperfollow_link": "${{ secrets.HYPERFOLLOW_LINK }}",
        "artist_name": "${{ secrets.ARTIST_NAME }}",
        "song_title": "${{ github.event.head_commit.message }}",
        "release_date": "$(date +%Y-%m-%d)"
      }'
```

### Example Scripts

- `examples/distribute.sh` - Bash script for command-line distribution
- `examples/hyperfollow-webhook-payload.json` - Example payload template

## Complete Workflow

1. **Export** your mix as WAV from your DAW
2. **Push** to GitHub → triggers pre-mastering action
3. **Download** mastered WAV from GitHub artifacts
4. **Upload** to DistroKid/Mixea
5. **Get** your HyperFollow link when release goes live
6. **Trigger** n8n workflow → instant social media distribution
7. **Done!** All platforms updated simultaneously
