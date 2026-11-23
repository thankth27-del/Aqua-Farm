// ทดสอบเซฟเกม (shared_preferences → localStorage) บน WebKit (เอนจินเดียวกับ Safari) จำลอง iPhone
import { webkit, devices } from 'playwright';
import { createServer } from 'node:http';
import { readFileSync, existsSync, statSync, mkdtempSync } from 'node:fs';
import { join, extname, resolve } from 'node:path';
import { tmpdir } from 'node:os';

const SITE = resolve(process.argv[2]); // โฟลเดอร์ที่มี aqua_farm/ อยู่ข้างใน (จำลอง GitHub Pages)
const OUT = resolve(process.argv[3]);
const types = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm',
  '.png': 'image/png', '.otf': 'font/otf', '.ttf': 'font/ttf' };
const server = createServer((req, res) => {
  const p = join(SITE, decodeURIComponent(req.url.split('?')[0]));
  if (!existsSync(p) || statSync(p).isDirectory()) {
    const idx = join(p, 'index.html');
    if (existsSync(idx)) { res.writeHead(200, { 'Content-Type': 'text/html' }); return res.end(readFileSync(idx)); }
    res.writeHead(404); return res.end('not found');
  }
  res.writeHead(200, { 'Content-Type': types[extname(p)] || 'application/octet-stream' });
  res.end(readFileSync(p));
}).listen(8766);

const URL = 'http://localhost:8766/aqua_farm/';
const iphone = { ...devices['iPhone 13'], viewport: { width: 390, height: 844 } };
const profile = mkdtempSync(join(tmpdir(), 'aqua-webkit-'));
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const errors = [];

async function open() {
  const ctx = await webkit.launchPersistentContext(profile, { ...iphone, headless: true });
  const page = ctx.pages()[0] || (await ctx.newPage());
  page.on('pageerror', (e) => errors.push(String(e)));
  await page.goto(URL);
  await page.waitForSelector('flutter-view', { timeout: 60000 });
  await sleep(4000);
  return { ctx, page };
}
const tap = async (page, x, y, wait = 900) => { await page.mouse.click(x, y); await sleep(wait); };

try {
  // ตรวจไฟล์ PWA ใต้ base path
  for (const f of ['manifest.json', 'icons/apple-touch-icon.png', 'icons/Icon-512.png', 'favicon.png']) {
    const r = await fetch(URL + f);
    console.log(`GET ${f} → ${r.status}`);
  }

  // รอบ 1: เกมใหม่ → จบวัน 1 ครั้ง
  let { ctx, page } = await open();
  console.log('UA:', await page.evaluate(() => navigator.userAgent));
  await page.screenshot({ path: join(OUT, 'safari_1_menu.png') });
  await tap(page, 195, 365);           // เกมใหม่
  await tap(page, 195, 165);           // ช่อง 1 เกมใหม่
  await tap(page, 159, 482, 2500);     // ตกลง (ชื่อ ฟาร์มของฉัน)
  await tap(page, 340, 72, 1500);      // จบวัน
  await tap(page, 195, 371, 1500);     // เริ่มวันใหม่
  await page.screenshot({ path: join(OUT, 'safari_2_day2.png') });
  const raw = await page.evaluate(() => localStorage.getItem('flutter.aquafarm_slots_v3'));
  const saved = JSON.parse(JSON.parse(raw));
  console.log('localStorage หลังจบวัน: ช่อง', Object.keys(saved).join(','), '· วันที่', saved['1'].S.day, '· ชื่อ', saved['1'].name);
  await ctx.close();

  // รอบ 2: ปิดเบราว์เซอร์แล้วเปิดใหม่ (profile เดิม) → เล่นต่อ
  ({ ctx, page } = await open());
  await tap(page, 195, 415, 2500);     // เล่นต่อ
  await page.screenshot({ path: join(OUT, 'safari_3_continue.png') });
  const raw2 = await page.evaluate(() => localStorage.getItem('flutter.aquafarm_slots_v3'));
  console.log('หลังเปิดใหม่ วันที่ในเซฟ =', JSON.parse(JSON.parse(raw2))['1'].S.day);
  await ctx.close();
  console.log('page errors:', errors.length ? errors : 'ไม่มี');
} finally {
  server.close();
}
