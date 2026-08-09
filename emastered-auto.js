/**
 * eMastered Automation Script
 * Automates browser interaction with eMastered.com for AI mastering
 *
 * Requirements: npm install playwright
 * Usage: node emastered-auto.js <input.wav> [output.wav]
 */

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

async function masterTrack(audioFile, outputFile, credentials, options = {}) {
  // Validate input file exists
  if (!fs.existsSync(audioFile)) {
    throw new Error(`Input file not found: ${audioFile}`);
  }

  const browser = await chromium.launch({
    headless: options.headless !== false,
    slowMo: options.slowMo || 0
  });

  const context = await browser.newContext({
    acceptDownloads: true,
    viewport: { width: 1920, height: 1080 }
  });

  const page = await context.newPage();

  try {
    console.log('🔐 Logging in to eMastered...');

    // Navigate to login
    await page.goto('https://www.emastered.com/login', {
      waitUntil: 'networkidle'
    });

    // Fill login form
    await page.fill('input[type="email"], input[name="email"]', credentials.email);
    await page.fill('input[type="password"], input[name="password"]', credentials.password);
    await page.click('button[type="submit"], button:has-text("Log in")');

    // Wait for login to complete
    await page.waitForURL('**/dashboard', { timeout: 15000 });
    console.log('✅ Logged in successfully');

    // Navigate to mastering page
    console.log('📤 Uploading audio file...');
    await page.goto('https://www.emastered.com/master', {
      waitUntil: 'networkidle'
    });

    // Upload file
    const fileInput = await page.locator('input[type="file"]').first();
    await fileInput.setInputFiles(path.resolve(audioFile));

    // Wait for upload to complete
    await page.waitForSelector(
      'text=/Upload complete|Ready to master|Processing complete/i',
      { timeout: 180000 }
    );
    console.log('✅ Upload complete');

    // Configure mastering options if provided
    if (options.intensity) {
      console.log(`⚙️  Setting intensity: ${options.intensity}`);
      await page.selectOption('select[name="intensity"]', options.intensity);
    }

    // Upload reference track if provided
    if (options.referenceTrack && fs.existsSync(options.referenceTrack)) {
      console.log('📎 Uploading reference track...');
      const refInput = await page.locator('input[type="file"]').nth(1);
      await refInput.setInputFiles(path.resolve(options.referenceTrack));
      await page.waitForTimeout(2000);
    }

    // Start mastering
    console.log('🎛️  Starting mastering process...');
    await page.click('button:has-text("Master"), button:has-text("Start Mastering")');

    // Wait for mastering to complete (can take 30-180 seconds)
    console.log('⏳ Mastering in progress (this may take 1-3 minutes)...');
    await page.waitForSelector(
      'text=/Mastering complete|Master complete|Download/i',
      { timeout: 300000 } // 5 minutes max
    );
    console.log('✅ Mastering complete!');

    // Preview before download (optional)
    if (options.preview) {
      console.log('🎧 Preview available - waiting 10 seconds...');
      await page.waitForTimeout(10000);
    }

    // Download the mastered file
    console.log('📥 Downloading mastered file...');

    // Click download button
    const downloadPromise = page.waitForEvent('download', { timeout: 30000 });
    await page.click('button:has-text("Download"), a:has-text("Download WAV")');

    const download = await downloadPromise;

    // Save to specified location
    const outputPath = path.resolve(outputFile);
    await download.saveAs(outputPath);

    // Verify file was downloaded
    if (!fs.existsSync(outputPath)) {
      throw new Error('Download failed - file not found');
    }

    const stats = fs.statSync(outputPath);
    console.log(`✅ Successfully mastered: ${audioFile}`);
    console.log(`📥 Saved to: ${outputPath}`);
    console.log(`📊 File size: ${(stats.size / 1024 / 1024).toFixed(2)} MB`);

    return {
      success: true,
      inputFile: audioFile,
      outputFile: outputPath,
      fileSize: stats.size
    };

  } catch (error) {
    console.error('❌ Error during mastering process:');
    console.error(`   ${error.message}`);

    // Take screenshot for debugging
    if (options.debug) {
      const screenshotPath = 'emastered-error.png';
      await page.screenshot({ path: screenshotPath });
      console.error(`   Screenshot saved to: ${screenshotPath}`);
    }

    throw error;

  } finally {
    await browser.close();
  }
}

// CLI usage
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.length < 1) {
    console.error('Usage: node emastered-auto.js <input.wav> [output.wav] [options]');
    console.error('');
    console.error('Options:');
    console.error('  --intensity=<low|medium|high>  Mastering intensity (default: medium)');
    console.error('  --reference=<file.wav>         Reference track for mastering');
    console.error('  --preview                      Wait 10s after mastering for preview');
    console.error('  --debug                        Save screenshot on error');
    console.error('  --headful                      Show browser window');
    console.error('');
    console.error('Environment variables:');
    console.error('  EMASTERED_EMAIL     Your eMastered email');
    console.error('  EMASTERED_PASSWORD  Your eMastered password');
    console.error('');
    console.error('Example:');
    console.error('  node emastered-auto.js input.wav output.wav --intensity=high');
    process.exit(1);
  }

  const inputFile = args[0];
  const outputFile = args[1] || `mastered_${path.basename(inputFile)}`;

  // Parse options
  const options = {
    intensity: 'medium',
    headless: true,
    preview: false,
    debug: false
  };

  args.slice(2).forEach(arg => {
    if (arg.startsWith('--intensity=')) {
      options.intensity = arg.split('=')[1];
    } else if (arg.startsWith('--reference=')) {
      options.referenceTrack = arg.split('=')[1];
    } else if (arg === '--preview') {
      options.preview = true;
    } else if (arg === '--debug') {
      options.debug = true;
    } else if (arg === '--headful') {
      options.headless = false;
    }
  });

  // Get credentials from environment
  const credentials = {
    email: process.env.EMASTERED_EMAIL,
    password: process.env.EMASTERED_PASSWORD
  };

  if (!credentials.email || !credentials.password) {
    console.error('❌ Error: EMASTERED_EMAIL and EMASTERED_PASSWORD must be set');
    console.error('');
    console.error('Set them with:');
    console.error('  export EMASTERED_EMAIL="your-email@example.com"');
    console.error('  export EMASTERED_PASSWORD="your-password"');
    process.exit(1);
  }

  // Run the mastering process
  masterTrack(inputFile, outputFile, credentials, options)
    .then(result => {
      console.log('');
      console.log('🎉 Mastering complete!');
      process.exit(0);
    })
    .catch(error => {
      console.error('');
      console.error('💥 Mastering failed');
      process.exit(1);
    });
}

module.exports = { masterTrack };
