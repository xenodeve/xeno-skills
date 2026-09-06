// design-ship-gate check 5: no horizontal overflow at 390 px.
// usage: node gate-390.js [page.html]   (run from the page's directory; needs playwright)
// overflow-x:hidden is removed first: that rule is how the one measured overflow was hidden.
const { chromium } = require('playwright');
const path = require('path');
const { pathToFileURL } = require('url');
(async () => {
  const file = path.resolve(process.cwd(), process.argv[2] || 'index.html');
  const b = await chromium.launch();
  const pg = await b.newPage({ viewport: { width: 390, height: 844 } });
  await pg.goto(pathToFileURL(file).href);
  await pg.addStyleTag({ content: 'html,body{overflow-x:visible!important}' });
  await pg.waitForTimeout(500);
  const over = await pg.evaluate(() => Math.max(0, document.documentElement.scrollWidth - 390));
  console.log('overflow:', over);
  await b.close();
})();
