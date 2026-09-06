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
    // The canvas, when nothing paints one. Falling back to white here called light text on a
    // color-scheme:dark page invisible and dark text on it fine -- wrong in both directions
    // (tests/skills/fixtures/design-ship-gate/dark-colorscheme.html, #359).
    const canvas = () => {
      const cs = getComputedStyle(document.documentElement);
      const l = lum(cs.backgroundColor);
      if (l !== null) return l;
      const scheme = (cs.colorScheme || '').toLowerCase();
      const dark = scheme.includes('dark') && !scheme.includes('light')
        ? true
        : window.matchMedia('(prefers-color-scheme: dark)').matches;
      return dark ? 18 : 255;
    };
    const bg = el => { for (let e = el; e; e = e.parentElement) { const l = lum(getComputedStyle(e).backgroundColor); if (l !== null) return l; } return canvas(); };
    const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT), out = [];
    let n;
    let checked = 0;
    while ((n = w.nextNode())) {
      const t = n.textContent.trim();
      // A stat is a SHORT run of text carrying a number. Requiring the whole node to be
      // numeric skipped `9.4B users` and `$1.2M` -- the ones a reader actually reads (#359).
      if (!/\d/.test(t) || t.length > 40) continue;
      const e = n.parentElement, s = getComputedStyle(e);
      if (s.display === 'none' || s.visibility === 'hidden' || !e.getClientRects().length) continue;
      checked++;
      const d = Math.abs(lum(s.color) - bg(e));
      if (d < 60) out.push({ t, d: Math.round(d), sel: e.tagName + '.' + e.className });
    }
    return { out, checked };
  });
  // the candidate count makes a dead detector visible: `invisible: 0 candidates: 0` is not a pass
  console.log('invisible:', r.out.length, 'candidates:', r.checked, JSON.stringify(r.out));
  await b.close();
})();
