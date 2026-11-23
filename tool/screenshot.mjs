// แคปหน้าจอเกมเวอร์ชันเว็บที่ขนาด iPhone (390x844)
// รัน: node tool/screenshot.mjs <โฟลเดอร์ build web> <โฟลเดอร์ผลลัพธ์> <ไฟล์ขั้นตอน .json>
// ขั้นตอน: ["wait", ms] | ["click", x, y] | ["scroll", x, y, dy] | ["shot", "ชื่อไฟล์"]
import { createServer } from 'node:http';
import { mkdirSync, readFileSync, writeFileSync, existsSync, statSync } from 'node:fs';
import { extname, join, resolve } from 'node:path';
import { launch } from './cdp.mjs';

const [webDir, outDir, stepsFile] = process.argv.slice(2).map((p) => resolve(p));
mkdirSync(outDir, { recursive: true });
const steps = JSON.parse(readFileSync(stepsFile, 'utf8'));

const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.png': 'image/png', '.otf': 'font/otf', '.ttf': 'font/ttf', '.css': 'text/css' };
const server = createServer((req, res) => {
  let p = join(webDir, decodeURIComponent(req.url.split('?')[0]));
  if (!existsSync(p) || statSync(p).isDirectory()) p = join(webDir, 'index.html');
  res.writeHead(200, { 'Content-Type': types[extname(p)] || 'application/octet-stream' });
  res.end(readFileSync(p));
}).listen(8765);

const b = await launch({ width: 390, height: 844, scale: 2 });
try {
  await b.send('Page.enable');
  await b.send('Page.navigate', { url: 'http://127.0.0.1:8765/' });
  await b.sleep(6000);
  for (const [op, ...a] of steps) {
    if (op === 'wait') await b.sleep(a[0]);
    if (op === 'click') {
      for (const type of ['mousePressed', 'mouseReleased']) {
        await b.send('Input.dispatchMouseEvent', { type, x: a[0], y: a[1], button: 'left', clickCount: 1 });
      }
      await b.sleep(900);
    }
    if (op === 'scroll') {
      await b.send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: a[0], y: a[1], deltaX: 0, deltaY: a[2] });
      await b.sleep(900);
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
