const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const esbuild = require('esbuild');
const { prodOptions } = require('./esbuild-config.js');

async function build() {
  console.log('Starting Docker build process...');

  // Ensure directories exist
  console.log('Creating directories...');
  execSync('node scripts/ensure-dirs.js', { stdio: 'inherit' });

  // Copy assets
  console.log('Copying assets...');
  execSync('node scripts/copy-assets.js', { stdio: 'inherit' });

  // Build CSS
  console.log('Building CSS...');
  execSync('pnpm exec postcss ./src/client/styles.css -o ./public/bundle/styles.css', { stdio: 'inherit' });

  // Bundle client JavaScript
  console.log('Bundling client JavaScript...');
  try {
    // Build main app bundle
    await esbuild.build({
      ...prodOptions,
      entryPoints: ['src/client/app-entry.ts'],
      outfile: 'public/bundle/client-bundle.js',
    });

    // Build test bundle
    await esbuild.build({
      ...prodOptions,
      entryPoints: ['src/client/test-entry.ts'],
      outfile: 'public/bundle/test.js',
    });

    // Build service worker
    await esbuild.build({
      ...prodOptions,
      entryPoints: ['src/client/sw.ts'],
      outfile: 'public/sw.js',
      format: 'iife', // Service workers need IIFE format
    });

    console.log('Client bundles built successfully');
  } catch (error) {
    console.error('Build failed:', error);
    process.exit(1);
  }

  // Build server TypeScript
  console.log('Building server...');
  execSync('npx tsc --build --force', { stdio: 'inherit' });

  // Verify dist directory exists
  if (fs.existsSync(path.join(__dirname, '../dist'))) {
    const files = fs.readdirSync(path.join(__dirname, '../dist'));
    console.log(`Server build created ${files.length} files in dist/`);

    // Check for the essential server.js file
    if (!fs.existsSync(path.join(__dirname, '../dist/server/server.js'))) {
      console.error('ERROR: dist/server/server.js not found after tsc build!');
      process.exit(1);
    }
  } else {
    console.error('ERROR: dist directory does not exist after tsc build!');
    process.exit(1);
  }

  console.log('Docker build completed successfully!');
}

build().catch((error) => {
  console.error('Build failed:', error);
  process.exit(1);
});
