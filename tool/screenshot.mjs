// แคปหน้าจอเกมเวอร์ชันเว็บที่ขนาด iPhone (390x844)
// รัน: node tool/screenshot.mjs <โฟลเดอร์ build web> <โฟลเดอร์ผลลัพธ์> <ไฟล์ขั้นตอน .json>
// ขั้นตอน:
//   ["wait", ms]                 รอ
//   ["click", x, y]              แตะที่พิกัด
//   ["tap", "ข้อความ", n?]        แตะปุ่ม/ข้อความที่ตรงกัน (ตัวที่ n นับจาก 0, ค่าลบนับจากท้าย)
//   ["scroll", x, y, dy]         เลื่อนจอ
//   ["scrollTo", "ข้อความ"]       เลื่อนจนเห็นข้อความ
//   ["shot", "ชื่อไฟล์"]           บันทึกภาพ
// "tap" ใช้ semantics ของ Flutter web (เปิดให้อัตโนมัติ) จึงไม่ผูกกับตำแหน่งปุ่ม
import { createServer } from 'node:http';
import { mkdirSync, readFileSync, writeFileSync, existsSync, statSync } from 'node:fs';
import { extname, join, resolve } from 'node:path';
import { launch } from './cdp.mjs';

const [webDir, outDir, stepsFile] = process.argv.slice(2).map((p) => resolve(p));
mkdirSync(outDir, { recursive: true });
const steps = JSON.parse(readFileSync(stepsFile, 'utf8').replace(/^﻿/, ''));

const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.png': 'image/png', '.otf': 'font/otf', '.ttf': 'font/ttf', '.css': 'text/css' };
const server = createServer((req, res) => {
  let p = join(webDir, decodeURIComponent(req.url.split('?')[0]));
  if (!existsSync(p) || statSync(p).isDirectory()) p = join(webDir, 'index.html');
  res.writeHead(200, { 'Content-Type': types[extname(p)] || 'application/octet-stream' });
  res.end(readFileSync(p));
}).listen(8765);

// หาตำแหน่งกลางของโหนด semantics ที่ข้อความตรงกัน (ตรงทั้งหมดก่อน แล้วค่อยแบบมีคำนั้นอยู่)
const findJs = (text, n, op = 'tap') => `(() => {
  const ph = document.querySelector('flt-semantics-placeholder');
  if (ph) ph.click();
  const t = ${JSON.stringify(text)};
  // ไม่นับส่วนที่อยู่ใต้เมนูล่าง (สูงราว 90px) เพื่อไม่ให้แตะโดนเมนูแทน
  const limit = ${op === 'tap' ? 'innerHeight' : 'innerHeight - 100'};
  const all = [...document.querySelectorAll('flt-semantics')].filter((e) => {
    const r = e.getBoundingClientRect();
    return r.width > 0 && r.height > 0 && r.bottom > 0 && r.top < limit;
  });
  const label = (e) => ((e.getAttribute('aria-label') || '') + ' ' + [...e.childNodes]
    .filter((c) => c.nodeType === 3).map((c) => c.textContent).join(' ')).trim();
  let m = all.filter((e) => label(e) === t);
  if (!m.length) m = all.filter((e) => label(e).split(/\\s+/).includes(t) || label(e).includes(t));
  if (!m.length) return null;
  // เลือกโหนดในสุด (เล็กสุด) ที่ตรง เพื่อไม่แตะกรอบใหญ่
  m.sort((a, b) => a.getBoundingClientRect().width * a.getBoundingClientRect().height
    - b.getBoundingClientRect().width * b.getBoundingClientRect().height);
  const i = ${n};
  m.sort((a, b) => a.getBoundingClientRect().top - b.getBoundingClientRect().top);
  const e = m[i < 0 ? m.length + i : i];
  if (!e) return null;
  const r = e.getBoundingClientRect();
  return [r.left + r.width / 2, r.top + r.height / 2];
})()`;

const b = await launch({ width: 390, height: 844, scale: 2 });
const click = async (x, y) => {
  for (const type of ['mousePressed', 'mouseReleased']) {
    await b.send('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 });
    await b.sleep(60);
  }
  await b.sleep(900);
};
try {
  await b.send('Page.enable');
  await b.send('Page.navigate', { url: 'http://127.0.0.1:8765/' });
  await b.sleep(7000);
  await b.evaluate(findJs('', 0));
  await b.sleep(800);
  for (const [op, ...a] of steps) {
    if (op === 'wait') await b.sleep(a[0]);
    // ["save", {patch}] — แก้เซฟช่อง 1 ใน localStorage (เช่น ตั้งตลาดปิด) ใช้คู่กับ reload
    if (op === 'save') {
      console.log('save', await b.evaluate(`(() => {
        const k = 'flutter.aquafarm_slots_v3';
        let raw = JSON.parse(localStorage.getItem(k));
        const wrapped = typeof raw === 'string';
        const all = wrapped ? JSON.parse(raw) : raw;
        Object.assign(all['1'].S, ${JSON.stringify(a[0])});
        const out = JSON.stringify(all);
        localStorage.setItem(k, JSON.stringify(wrapped ? out : all));
        return Object.keys(${JSON.stringify(a[0])}).join(',');
      })()`));
    }
    if (op === 'reload') {
      await b.send('Page.reload', {});
      await b.sleep(7000);
      await b.evaluate(findJs('', 0));
      await b.sleep(800);
    }
    if (op === 'click') await click(a[0], a[1]);
    if (op === 'tap' || op === 'scrollTo') {
      let p = null;
      for (let k = 0; k < 12 && !p; k++) {
        p = await b.evaluate(findJs(a[0], a[1] ?? 0, op));
        if (!p && op === 'scrollTo') {
          await b.send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 195, y: 500, deltaX: 0, deltaY: 250 });
          await b.sleep(500);
        } else if (!p) await b.sleep(400);
      }
      if (!p) throw new Error(`ไม่พบ "${a[0]}"`);
      if (op === 'tap') await click(p[0], p[1]);
      console.log(op, a[0], p.map(Math.round).join(','));
    }
    if (op === 'scroll') {
      await b.send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: a[0], y: a[1], deltaX: 0, deltaY: a[2] });
      await b.sleep(900);
    }
    // ["frames", "ชื่อ", จำนวน, ห่างกันms, [x,y,w,h] (ถ้ามี: ทำภาพรวมเฟรมเฉพาะส่วนนี้)]
    // แคปต่อเนื่องเพื่อดูการเคลื่อนไหว แล้วรวมเป็นภาพเดียว (ชื่อ_sheet.png)
    if (op === 'frames') {
      const [name, count, every, clip] = a;
      const shots = [];
      const t0 = Date.now();
      for (let i = 0; i < count; i++) {
        const due = t0 + i * every;
        const lag = due - Date.now();
        if (lag > 0) await b.sleep(lag);
        const at = Date.now() - t0;
        const { data } = await b.send('Page.captureScreenshot', { format: 'png' });
        writeFileSync(join(outDir, `${name}_${String(i).padStart(2, '0')}.png`), Buffer.from(data, 'base64'));
        shots.push([data, at]);
      }
      console.log('frames', name, shots.map((s) => s[1]).join(','));
      if (clip) {
        const sheet = await b.evaluate(`(async () => {
          const shots = ${JSON.stringify(shots)};
          const [x, y, w, h] = ${JSON.stringify(clip)};
          const s = 2, cols = 2, pad = 6;
          const c = document.createElement('canvas');
          const rows = Math.ceil(shots.length / cols);
          c.width = cols * (w * s + pad) + pad; c.height = rows * (h * s + pad + 28) + pad;
          const g = c.getContext('2d');
          g.imageSmoothingEnabled = false;
          g.fillStyle = '#2a1c12'; g.fillRect(0, 0, c.width, c.height);
          for (let i = 0; i < shots.length; i++) {
            const img = new Image();
            img.src = 'data:image/png;base64,' + shots[i][0];
            await img.decode();
            const cx = pad + (i % cols) * (w * s + pad), cy = pad + Math.floor(i / cols) * (h * s + pad + 28);
            g.drawImage(img, x * s, y * s, w * s, h * s, cx, cy + 28, w * s, h * s);
            g.fillStyle = '#fff3c4'; g.font = 'bold 22px sans-serif';
            g.fillText('t = ' + (shots[i][1] / 1000).toFixed(1) + ' s', cx + 4, cy + 22);
          }
          return c.toDataURL('image/png').split(',')[1];
        })()`);
        writeFileSync(join(outDir, `${name}_sheet.png`), Buffer.from(sheet, 'base64'));
        console.log('saved', name + '_sheet');
      }
    }
    if (op === 'shot') {
      const { data } = await b.send('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(outDir, a[0] + '.png'), Buffer.from(data, 'base64'));
      console.log('saved', a[0]);
    }
  }
} finally {
  b.close();
  server.close();
}
