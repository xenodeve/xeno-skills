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
  // overflow-y must be freed too: per spec overflow-x:visible computes to auto when the other
  // axis is not visible, so the rule alone left the scroll container in place (#359).
  await pg.addStyleTag({ content: 'html,body{overflow-x:visible!important;overflow-y:visible!important}' });
  await pg.waitForTimeout(1500);
  const r = await pg.evaluate(() => {
    const over = Math.max(0, document.documentElement.scrollWidth - 390);
    // An INNER wrapper with overflow-x hidden does not scroll the page -- it throws the
    // content away, which is the same defect wearing a different rule and read as 0 before.
    let clipped = 0;
    for (const e of document.querySelectorAll('*')) {
      const ox = getComputedStyle(e).overflowX;
      if (ox !== 'hidden' && ox !== 'clip') continue;
      if (e.scrollWidth - e.clientWidth > 1) clipped++;
    }
    return { over, clipped };
  });
  console.log('overflow:', r.over, 'clipped:', r.clipped);
  await b.close();
})();
