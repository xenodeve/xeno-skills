// Screenshot a page so you can LOOK at it: `Read` the PNG afterwards (#380).
// usage: NODE_PATH=C:/Users/xenod/.claude/tools/node_modules \
//        node <this dir>/shot.js <url-or-html-path> <out.png> [width] [height] [dark]
// Prints the saved path and every page error / console error, so a page whose
// script does not load says so even when the picture looks fine.
const path = require('path');
const { pathToFileURL } = require('url');
const { chromium } = require('playwright');

(async () => {
  const [src, out, w = '1280', h = '800', scheme] = process.argv.slice(2);
  if (!src || !out) {
    console.error('usage: node shot.js <url-or-html-path> <out.png> [width] [height] [dark]');
    process.exit(2);
  }
  const url = /^[a-z]+:\/\//i.test(src) ? src : pathToFileURL(path.resolve(src)).href;
  const browser = await chromium.launch();
  const page = await browser.newPage({
    viewport: { width: +w, height: +h },
    colorScheme: scheme === 'dark' ? 'dark' : 'light',
  });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  await page.goto(url, { waitUntil: 'networkidle' });
  await page.screenshot({ path: out });
  await browser.close();
  console.log(`saved ${path.resolve(out)} (${w}x${h}${scheme === 'dark' ? ', dark' : ''})`);
  console.log(`page errors: ${errors.length}`);
  for (const e of errors) console.log('  ' + e);
})().catch(e => { console.error(e.message); process.exit(1); });
