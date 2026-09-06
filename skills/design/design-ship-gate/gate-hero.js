// design-ship-gate check 6: no text collides with the headline.
// usage: node gate-hero.js [page.html]   (run from the page's directory; needs playwright)
// A column ruler "01-12" sat across the h1; a glass lens sat over "EST. 1998". Both were
// text over text, and the ruler was even BELOW the headline in z-order, so z-index is not
// consulted: any positioned element carrying its own visible text whose box overlaps the
// h1 box is a collision. Blobs and glows carry no text and pass.
const { chromium } = require('playwright');
const path = require('path');
const { pathToFileURL } = require('url');
(async () => {
  const file = path.resolve(process.cwd(), process.argv[2] || 'index.html');
  const b = await chromium.launch();
  const pg = await b.newPage({ viewport: { width: 1440, height: 900 } });
  await pg.goto(pathToFileURL(file).href);
  await pg.waitForTimeout(1500);
  const r = await pg.evaluate(() => {
    const h = document.querySelector('h1');
    if (!h) return null;   // a missing h1 is not a collision (#359)
    const hb = h.getBoundingClientRect();
    const positioned = e => { for (let x = e; x && x !== document.body; x = x.parentElement) { const p = getComputedStyle(x).position; if (p === 'absolute' || p === 'fixed') return true; } return false; };
    const out = new Set();
    for (const e of document.body.querySelectorAll('*')) {
      if (h.contains(e) || e.contains(h) || !positioned(e)) continue;
      const own = [...e.childNodes].some(n => n.nodeType === 3 && n.textContent.trim());
      if (!own) continue;
      const s = getComputedStyle(e);
      if (s.visibility === 'hidden' || s.display === 'none' || parseFloat(s.opacity) === 0) continue;
      const r = e.getBoundingClientRect();
      if (r.width === 0 || r.height === 0) continue;
      if (r.left < hb.right && r.right > hb.left && r.top < hb.bottom && r.bottom > hb.top)
        out.add(e.tagName + '.' + e.className + ' "' + e.textContent.trim().slice(0, 20) + '"');
    }
    return [...out];
  });
  if (r === null) {
    // Reporting this as `colliding: 1 ["no h1"]` turned a missing element into a collision the
    // model then tried to fix. The page still fails brief coverage; this check simply cannot run.
    console.log('colliding:', 0, '[]');
    console.log('note: no h1 found - the collision check did not run');
  } else {
    console.log('colliding:', r.length, JSON.stringify(r));
  }
  await b.close();
})();
