// design-ship-gate check 4: in dark mode every stat is visible.
// usage: node gate-dark.js [page.html]   (run from the page's directory; needs playwright)
// Reads TEXT NODES, because a stat is written `9.4<span>B</span>` and an element-level
// test skips it. "invisible" = luminance distance to the effective background < 60.
const { chromium } = require('playwright');
const path = require('path');
const { pathToFileURL } = require('url');
(async () => {
  const file = path.resolve(process.cwd(), process.argv[2] || 'index.html');
  const b = await chromium.launch();
  const pg = await b.newPage({ colorScheme: 'dark', viewport: { width: 1440, height: 900 } });
  await pg.goto(pathToFileURL(file).href);
  await pg.waitForTimeout(1500);
  const r = await pg.evaluate(() => {
    const lum = c => { const [r, g, b, a] = c.match(/[\d.]+/g).map(Number); return a === 0 ? null : 0.2126 * r + 0.7152 * g + 0.0722 * b; };
    const bg = el => { for (let e = el; e; e = e.parentElement) { const l = lum(getComputedStyle(e).backgroundColor); if (l !== null) return l; } return 255; };
    const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT), out = [];
    let n;
    while ((n = w.nextNode())) {
      const t = n.textContent.trim();
      if (!/^[\d≈~+.,]+[A-Za-z%+]*$/.test(t) || !/\d/.test(t)) continue;
      const e = n.parentElement, s = getComputedStyle(e);
      if (s.display === 'none' || s.visibility === 'hidden' || !e.getClientRects().length) continue;
      const d = Math.abs(lum(s.color) - bg(e));
      if (d < 60) out.push({ t, d: Math.round(d), sel: e.tagName + '.' + e.className });
    }
    return out;
  });
  console.log('invisible:', r.length, JSON.stringify(r));
  await b.close();
})();
