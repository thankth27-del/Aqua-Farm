// ส่งออกภาพพิกเซลจาก reference/index.html เป็น PNG ใน assets/pixel/
// ใช้ฟังก์ชัน ico() ของต้นแบบเองวาดลง canvas แล้วบันทึกตามขนาดจริง (12x12)
// ปลาไม่ส่งออกแล้ว: ใช้ปลาชุดใหม่ใน assets/fish/ (แถบ 8 เฟรม 128x128)
// รัน: node tool/export_sprites.mjs
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { launch } from './cdp.mjs';

const root = resolve(import.meta.dirname, '..');
const out = resolve(root, 'assets/pixel');
mkdirSync(out, { recursive: true });

const b = await launch({ width: 800, height: 450 });
try {
  await b.send('Page.enable');
  await b.send('Page.navigate', { url: pathToFileURL(resolve(root, 'reference/index.html')).href });
  await b.sleep(1500);
  const sprites = await b.evaluate(`(() => {
    const names = Object.keys(MAPS);
    const r = {};
    for (const n of names) { ico(n); r[n] = IC[n][0]; }
    return r;
  })()`);
  for (const [name, url] of Object.entries(sprites)) {
    writeFileSync(resolve(out, name + '.png'), Buffer.from(url.split(',')[1], 'base64'));
  }
  console.log('exported', Object.keys(sprites).length, 'sprites to', out);
} finally {
  b.close();
}
