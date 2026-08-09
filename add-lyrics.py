#!/usr/bin/env python3
"""
Add Lyrics to Audio Metadata
Supports WAV and MP3 files with plain text or LRC format lyrics

Usage:
    python add-lyrics.py <audio_file> <lyrics_file>
    python add-lyrics.py song.wav lyrics.txt
    python add-lyrics.py song.mp3 lyrics.lrc

Requirements:
    pip install mutagen
"""

import sys
import os

try:
    from mutagen.wave import WAVE
    from mutagen.mp3 import MP3
    from mutagen.id3 import ID3, USLT, ID3NoHeaderError
except ImportError:
    print("❌ Error: mutagen library not installed")
    print("Install with: pip install mutagen")
    sys.exit(1)


def add_lyrics_to_wav(audio_file, lyrics_text):
    """
    Add lyrics to WAV file using RIFF INFO tags

    Args:
        audio_file: Path to WAV file
        lyrics_text: Lyrics as string

    Returns:
        bool: Success status
    """
    try:
        audio = WAVE(audio_file)

        # WAV files use INFO tags
        # ILYRIC is the standard tag for lyrics
        audio['ILYRIC'] = [lyrics_text]

        # Save changes
        audio.save()

        return True

    except Exception as e:
        print(f"❌ Error adding lyrics to WAV: {e}")
        return False


def add_lyrics_to_mp3(audio_file, lyrics_text):
    """
    Add lyrics to MP3 file using ID3v2 tags

    Args:
        audio_file: Path to MP3 file
        lyrics_text: Lyrics as string

    Returns:
        bool: Success status
    """
    try:
        # Try to load existing ID3 tags, create if not present
        try:
            audio = ID3(audio_file)
        except ID3NoHeaderError:
            audio = ID3()
            audio.save(audio_file)
            audio = ID3(audio_file)

        # Remove existing lyrics if any
        audio.delall('USLT')

        # Add unsynchronized lyrics (USLT frame)
        # This is the standard ID3v2 frame for lyrics
        audio.add(USLT(
            encoding=3,      # UTF-8 encoding
            lang='eng',      # Language code (ISO 639-2)
            desc='',         # Description (empty for main lyrics)
            text=lyrics_text # The actual lyrics
        ))

        # Save changes
        audio.save(audio_file, v2_version=4)

        return True

    except Exception as e:
        print(f"❌ Error adding lyrics to MP3: {e}")
        return False


def verify_lyrics(audio_file):
    """
    Verify that lyrics were successfully added

    Args:
        audio_file: Path to audio file
    """
    try:
        if audio_file.lower().endswith('.wav'):
            audio = WAVE(audio_file)
            if 'ILYRIC' in audio:
                lyrics = audio['ILYRIC'][0]
                lines = lyrics.split('\n')
                print(f"\n📝 Lyrics verified ({len(lines)} lines)")
                print(f"   First line: {lines[0][:50]}...")
                return True
            else:
                print("⚠️  Warning: No lyrics found in file")
                return False

        elif audio_file.lower().endswith('.mp3'):
            audio = ID3(audio_file)
            if 'USLT::eng' in audio or 'USLT' in audio:
                # Get the USLT frame
                for frame in audio.values():
                    if frame.FrameID == 'USLT':
                        lyrics = frame.text
                        lines = lyrics.split('\n')
                        print(f"\n📝 Lyrics verified ({len(lines)} lines)")
                        print(f"   First line: {lines[0][:50]}...")
                        return True
                return False
            else:
                print("⚠️  Warning: No lyrics found in file")
                return False

    except Exception as e:
        print(f"⚠️  Could not verify lyrics: {e}")
        return False


def detect_lyrics_format(lyrics_text):
    """
    Detect if lyrics are in LRC format (time-synced)

    Args:
        lyrics_text: Lyrics string

    Returns:
        str: 'lrc' or 'plain'
    """
    # Check for LRC timestamp pattern [MM:SS.XX]
    import re
    lrc_pattern = r'^\[\d{2}:\d{2}\.\d{2}\]'

    for line in lyrics_text.split('\n')[:5]:  # Check first 5 lines
        if re.match(lrc_pattern, line.strip()):
            return 'lrc'

    return 'plain'


def main():
    """Main entry point"""

    # Check arguments
    if len(sys.argv) < 3:
        print("Add Lyrics to Audio Metadata")
        print("=" * 50)
        print("\nUsage:")
        print(f"  {sys.argv[0]} <audio_file> <lyrics_file>")
        print("\nExamples:")
        print(f"  {sys.argv[0]} song.wav lyrics.txt")
        print(f"  {sys.argv[0]} song.mp3 lyrics.lrc")
        print("\nSupported formats:")
        print("  Audio: WAV, MP3")
        print("  Lyrics: Plain text (.txt) or LRC (.lrc)")
        print("\nNote: Install mutagen first: pip install mutagen")
        sys.exit(1)

    audio_file = sys.argv[1]
    lyrics_file = sys.argv[2]

    # Validate files exist
    if not os.path.exists(audio_file):
        print(f"❌ Error: Audio file not found: {audio_file}")
        sys.exit(1)

    if not os.path.exists(lyrics_file):
        print(f"❌ Error: Lyrics file not found: {lyrics_file}")
        sys.exit(1)

    # Read lyrics
    try:
        with open(lyrics_file, 'r', encoding='utf-8') as f:
            lyrics_text = f.read().strip()
    except UnicodeDecodeError:
        # Try with different encoding
        try:
            with open(lyrics_file, 'r', encoding='latin-1') as f:
                lyrics_text = f.read().strip()
            print("⚠️  Warning: Used latin-1 encoding (not UTF-8)")
        except Exception as e:
            print(f"❌ Error reading lyrics file: {e}")
            sys.exit(1)

    if not lyrics_text:
        print("❌ Error: Lyrics file is empty")
        sys.exit(1)

    # Detect lyrics format
    lyrics_format = detect_lyrics_format(lyrics_text)

    # Display info
    print(f"\n🎵 Adding lyrics to audio file")
    print(f"   Audio: {audio_file}")
    print(f"   Lyrics: {lyrics_file}")
    print(f"   Format: {lyrics_format.upper()}")
    print(f"   Lines: {len(lyrics_text.split(chr(10)))}")

    # Add lyrics based on file type
    success = False

    if audio_file.lower().endswith('.wav'):
        print("\n⏳ Processing WAV file...")
        success = add_lyrics_to_wav(audio_file, lyrics_text)

    elif audio_file.lower().endswith('.mp3'):
        print("\n⏳ Processing MP3 file...")
        success = add_lyrics_to_mp3(audio_file, lyrics_text)

    else:
        print(f"❌ Unsupported file format: {audio_file}")
        print("   Supported formats: WAV, MP3")
        sys.exit(1)

    # Verify and report
    if success:
        print(f"✅ Lyrics successfully added to {audio_file}")
        verify_lyrics(audio_file)

        # Additional tips
        print("\n💡 Next steps:")
        if audio_file.lower().endswith('.mp3'):
            print("   • Lyrics are embedded in ID3v2 USLT tag")
        else:
            print("   • Lyrics are embedded in RIFF INFO ILYRIC tag")

        print("   • Upload to DistroKid with lyrics file for full support")
        print("   • Submit to Spotify for Artists for lyrics display")

        if lyrics_format == 'lrc':
            print("   • Time-synced lyrics detected (LRC format)")
            print("   • Best for Apple Music and YouTube Music")

        sys.exit(0)
    else:
        print(f"\n❌ Failed to add lyrics")
        sys.exit(1)


if __name__ == '__main__':
    main()
