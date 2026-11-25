// สร้างไอคอนแอป (PWA / iPhone) — พื้นบ่อวาดแบบพิกเซล ปลาใช้เฟรมแรกของปลาชุดใหม่ (assets/fish/)
// รัน: node tool/make_icons.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { launch } from './cdp.mjs';

const root = resolve(import.meta.dirname, '..');
const fish = 'data:image/png;base64,' + readFileSync(resolve(root, 'assets/fish/nila_strip.png')).toString('base64');

// [ไฟล์, ขนาด px, maskable?]
const targets = [
  ['web/icons/Icon-192.png', 192, false],
  ['web/icons/Icon-512.png', 512, false],
  ['web/icons/Icon-maskable-192.png', 192, true],
  ['web/icons/Icon-maskable-512.png', 512, true],
  ['web/icons/apple-touch-icon.png', 180, false],
  ['web/favicon.png', 32, false],
];

const b = await launch({ width: 600, height: 600, port: 9334 });
try {
  for (const [file, size, maskable] of targets) {
    const url = await b.evaluate(`(async () => {
      const img = new Image(); img.src = ${JSON.stringify(fish)}; await img.decode();
      const S = ${size}, u = S / 24, c = document.createElement('canvas'); c.width = c.height = S;
      const x = c.getContext('2d'); x.imageSmoothingEnabled = false;
      const R = (a, b, w, h, col) => { x.fillStyle = col; x.fillRect(Math.round(a*u), Math.round(b*u), Math.ceil(w*u), Math.ceil(h*u)); };
      // น้ำในบ่อ (สีจากฉากบ่อของต้นแบบ)
      R(0, 0, 24, 24, '#0E7490');
      for (let y = 3; y < 20; y += 4) for (let i = 0; i < 24; i += 7) R(i + (y % 8 ? 0 : 3), y, 3, .5, '#4c93cc');
      R(0, 20, 24, 4, '#23467a');
      for (const wx of [3, 20]) for (let j = 0; j < 3; j++) R(wx, 19.5 - j * 2, .8, 2, '#2f7d3a');
      // ฟองอากาศ
      for (const [bx, by] of [[17, 5], [19, 3], [6, 15], [15.5, 17]]) { R(bx, by, 1.2, 1.2, '#a5ddf5'); R(bx + .3, by + .3, .4, .4, '#fff'); }
      // ปลานิล (maskable เล็กลงให้อยู่ในวงปลอดภัย)
      // เฟรม 128x128 ตัวปลากว้างราว 80% ของเฟรม — ย่อแบบนุ่มเฉพาะตอนย่อภาพ
      const fw = (${maskable} ? 12 : 17) * 1.25;
      x.imageSmoothingEnabled = true; x.imageSmoothingQuality = 'high';
      x.drawImage(img, 0, 0, 128, 128, Math.round((12 - fw / 2) * u), Math.round((11.5 - fw / 2) * u), Math.round(fw * u), Math.round(fw * u));
      return c.toDataURL('image/png');
    })()`);
    writeFileSync(resolve(root, file), Buffer.from(url.split(',')[1], 'base64'));
    console.log('wrote', file, size + 'px');
  }
} finally {
  b.close();
}
