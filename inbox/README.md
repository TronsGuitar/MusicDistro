# Inbox

Drop your raw WAV mix files here. Pushing a `.wav` file to this folder will automatically trigger the **Premaster-QC** GitHub Action, which will:

1. **Render a clean pre-master** – converts to 24-bit, 48 kHz with -3 dBFS headroom using SoX
2. **Embed metadata** – writes Artist, Title, and ISRC tags into the WAV using Python/mutagen (requires `ARTIST_NAME`, `SONG_TITLE`, and `ISRC_CODE` repo secrets)
3. **Generate a QC report** – measures integrated LUFS and true-peak levels using FFmpeg
4. **Upload artifacts** – the processed WAV and QC report are available on the Actions run page

## How to Use

1. Export your mix as a WAV file from your DAW
2. Copy it into this `inbox/` folder
3. Push to GitHub
4. Wait for the Action to complete (~1-2 minutes)
5. Download `premaster_outputs` from the workflow run artifacts

## Requirements

Set the following **Repository Secrets** (Settings → Secrets and variables → Actions):

| Secret | Required | Description |
|--------|----------|-------------|
| `ISRC_CODE` | Optional | Your track's ISRC code (e.g. `QM24S2500010`) |
| `ARTIST_NAME` | Optional | Artist name to embed in WAV tags |
| `SONG_TITLE` | Optional | Song title to embed in WAV tags |

If secrets are not set the action will still run and skip the optional tagging steps.

## File Naming

Use ASCII characters and underscores only to avoid path issues:

```
Artist_-_Song_Title_v01.wav   ✅ (recommended)
My Artist - My Song (mix 1).wav   ⚠️  (works, but spaces and parentheses in the filename will be preserved in artifact zip entries, which can cause extraction issues on Windows and some Linux tools)
```
