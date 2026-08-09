#!/usr/bin/env node
/**
 * Extract Lyrics from Suno.com
 * Automatically scrapes lyrics from Suno song pages
 *
 * Usage:
 *   node extract-suno-lyrics.js <suno_url> [output_file]
 *   node extract-suno-lyrics.js https://suno.com/song/c0117fdc-ff4c-41e5-b623-9e6be9e3ceae
 *   node extract-suno-lyrics.js https://suno.com/song/abc123 lyrics.txt
 *
 * Requirements:
 *   npm install playwright
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function extractSunoLyrics(sunoUrl, outputFile = null) {
  // Validate URL
  if (!sunoUrl.includes('suno.com')) {
    throw new Error('Invalid Suno URL. Must be from suno.com');
  }

  console.log('🎵 Extracting lyrics from Suno...');
  console.log(`   URL: ${sunoUrl}`);

  const browser = await chromium.launch({
    headless: true
  });

  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 }
  });

  const page = await context.newPage();

  try {
    // Navigate to Suno song page
    console.log('\n⏳ Loading Suno page...');
    await page.goto(sunoUrl, {
      waitUntil: 'networkidle',
      timeout: 30000
    });

    // Wait for page to load
    await page.waitForTimeout(2000);

    // Try multiple selectors to find lyrics
    // Suno's UI may change, so we try various common patterns
    const lyricsSelectors = [
      '[class*="lyrics"]',
      '[class*="Lyrics"]',
      '[data-testid="lyrics"]',
      'pre',
      '.song-lyrics',
      '#lyrics',
      '[aria-label*="lyrics" i]',
      'div[class*="song"] pre',
      'div[class*="content"] pre'
    ];

    let lyrics = null;
    let songTitle = null;
    let metadata = {};

    // Try to extract song title
    try {
      const titleSelectors = [
        'h1',
        '[class*="title"]',
        '[data-testid="title"]',
        'meta[property="og:title"]'
      ];

      for (const selector of titleSelectors) {
        const element = await page.$(selector);
        if (element) {
          if (selector.includes('meta')) {
            songTitle = await element.getAttribute('content');
          } else {
            songTitle = await element.textContent();
          }
          if (songTitle) {
            songTitle = songTitle.trim();
            break;
          }
        }
      }
    } catch (e) {
      console.log('⚠️  Could not extract title');
    }

    // Try to extract lyrics with each selector
    console.log('🔍 Searching for lyrics...');
    for (const selector of lyricsSelectors) {
      try {
        const elements = await page.$$(selector);

        for (const element of elements) {
          const text = await element.textContent();

          // Check if this looks like lyrics
          if (text && text.length > 50 && text.includes('\n')) {
            // Verify it's not just code or JSON
            if (!text.includes('{') && !text.includes('function') && !text.includes('const')) {
              lyrics = text.trim();
              console.log(`✓ Found lyrics using selector: ${selector}`);
              break;
            }
          }
        }

        if (lyrics) break;
      } catch (e) {
        // Continue to next selector
      }
    }

    // Alternative: Try to find lyrics in page content
    if (!lyrics) {
      console.log('🔍 Trying alternative extraction method...');

      const pageContent = await page.content();

      // Look for lyrics in JSON data
      const jsonMatches = pageContent.match(/"lyrics":\s*"([^"]+)"/);
      if (jsonMatches) {
        lyrics = jsonMatches[1]
          .replace(/\\n/g, '\n')
          .replace(/\\"/g, '"')
          .replace(/\\'/g, "'");
        console.log('✓ Found lyrics in JSON data');
      }
    }

    // Try to extract additional metadata
    try {
      // Look for artist/creator
      const artistElement = await page.$('[class*="artist"], [class*="creator"]');
      if (artistElement) {
        metadata.artist = await artistElement.textContent();
      }

      // Look for tags/genre
      const tagElements = await page.$$('[class*="tag"], [class*="genre"]');
      if (tagElements.length > 0) {
        metadata.tags = [];
        for (const tag of tagElements) {
          const tagText = await tag.textContent();
          if (tagText) metadata.tags.push(tagText.trim());
        }
      }

      // Look for creation date
      const dateElement = await page.$('time, [class*="date"]');
      if (dateElement) {
        metadata.created = await dateElement.textContent();
      }
    } catch (e) {
      // Metadata extraction is optional
    }

    if (!lyrics) {
      // Last resort: take a screenshot for debugging
      const screenshotPath = 'suno-page-debug.png';
      await page.screenshot({ path: screenshotPath, fullPage: true });
      console.log(`📸 Screenshot saved to ${screenshotPath} for debugging`);

      throw new Error('Could not find lyrics on the page. The page structure may have changed.');
    }

    // Clean up lyrics
    lyrics = cleanLyrics(lyrics);

    // Display results
    console.log('\n✅ Successfully extracted lyrics!');
    console.log(`   Title: ${songTitle || 'Unknown'}`);
    console.log(`   Length: ${lyrics.split('\n').length} lines`);
    console.log(`   Characters: ${lyrics.length}`);

    if (metadata.artist) {
      console.log(`   Artist: ${metadata.artist}`);
    }

    // Save to file if output specified
    if (outputFile) {
      fs.writeFileSync(outputFile, lyrics, 'utf-8');
      console.log(`\n💾 Lyrics saved to: ${outputFile}`);
    } else {
      // Generate filename from title or URL
      const songId = sunoUrl.split('/').pop();
      const filename = songTitle
        ? `${songTitle.replace(/[^a-z0-9]/gi, '_')}_lyrics.txt`
        : `suno_${songId}_lyrics.txt`;

      fs.writeFileSync(filename, lyrics, 'utf-8');
      console.log(`\n💾 Lyrics saved to: ${filename}`);
      outputFile = filename;
    }

    // Also save metadata as JSON
    const metadataFile = outputFile.replace('.txt', '_metadata.json');
    const fullMetadata = {
      url: sunoUrl,
      title: songTitle,
      lyrics: lyrics,
      ...metadata,
      extractedAt: new Date().toISOString()
    };
    fs.writeFileSync(metadataFile, JSON.stringify(fullMetadata, null, 2), 'utf-8');
    console.log(`📊 Metadata saved to: ${metadataFile}`);

    // Preview
    console.log('\n📝 Lyrics preview:');
    console.log('─'.repeat(50));
    const lines = lyrics.split('\n');
    console.log(lines.slice(0, 10).join('\n'));
    if (lines.length > 10) {
      console.log('...');
      console.log(`(${lines.length - 10} more lines)`);
    }
    console.log('─'.repeat(50));

    return {
      lyrics,
      title: songTitle,
      metadata,
      outputFile
    };

  } catch (error) {
    console.error('\n❌ Error extracting lyrics:');
    console.error(`   ${error.message}`);
    throw error;
  } finally {
    await browser.close();
  }
}

function cleanLyrics(lyrics) {
  // Clean up extracted lyrics
  return lyrics
    // Remove excessive blank lines
    .replace(/\n{3,}/g, '\n\n')
    // Remove leading/trailing whitespace
    .trim()
    // Normalize line endings
    .replace(/\r\n/g, '\n')
    // Remove any HTML entities
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'");
}

// CLI usage
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.length < 1) {
    console.log('Extract Lyrics from Suno.com');
    console.log('='.repeat(50));
    console.log('\nUsage:');
    console.log('  node extract-suno-lyrics.js <suno_url> [output_file]');
    console.log('\nExamples:');
    console.log('  node extract-suno-lyrics.js https://suno.com/song/abc123');
    console.log('  node extract-suno-lyrics.js https://suno.com/song/abc123 my_lyrics.txt');
    console.log('\nThe script will:');
    console.log('  • Extract lyrics from the Suno page');
    console.log('  • Extract song title and metadata');
    console.log('  • Save lyrics to a text file');
    console.log('  • Save metadata as JSON');
    console.log('\nNote: Requires Playwright');
    console.log('  Install with: npm install playwright');
    console.log('  Then run: npx playwright install chromium');
    process.exit(1);
  }

  const sunoUrl = args[0];
  const outputFile = args[1];

  extractSunoLyrics(sunoUrl, outputFile)
    .then(result => {
      console.log('\n🎉 Extraction complete!');
      console.log(`\n💡 Next steps:`);
      console.log(`   • Use lyrics file: ${result.outputFile}`);
      console.log(`   • Add to your track with: python3 add-lyrics.py audio.wav ${result.outputFile}`);
      console.log(`   • Include in workflow: ./emastered-workflow.sh ... ${result.outputFile}`);
      process.exit(0);
    })
    .catch(error => {
      console.error('\n💥 Extraction failed');
      console.error('\nTroubleshooting:');
      console.error('  • Check if the URL is correct');
      console.error('  • Make sure the song is publicly accessible');
      console.error('  • Suno may have changed their page structure');
      console.error('  • Try opening the URL in a browser to verify');
      process.exit(1);
    });
}

module.exports = { extractSunoLyrics, cleanLyrics };
