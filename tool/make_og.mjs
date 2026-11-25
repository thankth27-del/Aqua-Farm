// สร้างภาพตัวอย่างลิงก์ (Open Graph 1200x630) — web/og.png
// โลโก้ AQUA FARM ใหญ่กลางภาพ (ฟอนต์ Mali แบบโลโก้ในเกม) + ปลาจริงจากเกมกระโดดพ้นน้ำรอบโลโก้
// รัน: node tool/make_og.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { launch } from './cdp.mjs';

const root = resolve(import.meta.dirname, '..');
const data = (p, type) => `data:${type};base64,` + readFileSync(resolve(root, p)).toString('base64');
const fish = Object.fromEntries(
  ['nila', 'chon', 'carp', 'tap', 'swai', 'rad', 'nuan', 'dook'].map((f) => [
    f,
    data(`assets/fish/${f}_strip.png`, 'image/png'),
  ]),
);
const fonts = {
  bold: data('assets/fonts/Mali-Bold.ttf', 'font/ttf'),
  semi: data('assets/fonts/Mali-SemiBold.ttf', 'font/ttf'),
};

const W = 1200, H = 630;
const b = await launch({ width: W, height: H, port: 9335 });
try {
  const url = await b.evaluate(`(async () => {
    const fonts = ${JSON.stringify(fonts)};
    for (const [n, src] of Object.entries(fonts)) {
      const f = new FontFace('Mali' + n, 'url(' + src + ')'); await f.load(); document.fonts.add(f);
    }
    const img = {};
    for (const [k, src] of Object.entries(${JSON.stringify(fish)})) {
      const i = new Image(); i.src = src; await i.decode(); img[k] = i;
    }
    const W = ${W}, H = ${H}, CX = W / 2, CY = 268;
    const c = document.createElement('canvas'); c.width = W; c.height = H;
    const x = c.getContext('2d');
    // สุ่มแบบคงที่ (ภาพเหมือนเดิมทุกครั้งที่รัน)
    let seed = 7; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
    const px = (a, b, w, h, col) => { x.fillStyle = col; x.fillRect(Math.round(a), Math.round(b), w, h); };

    // ---------- พื้นหลัง: แสงพุ่งจากกลางโลโก้ (sunburst)
    x.fillStyle = '#0b5f86'; x.fillRect(0, 0, W, H);
    const rays = 24;
    for (let i = 0; i < rays; i++) {
      const a0 = (i / rays) * Math.PI * 2, a1 = a0 + Math.PI / rays;
      x.beginPath(); x.moveTo(CX, CY);
      x.lineTo(CX + Math.cos(a0) * 1400, CY + Math.sin(a0) * 1400);
      x.lineTo(CX + Math.cos(a1) * 1400, CY + Math.sin(a1) * 1400);
      x.closePath(); x.fillStyle = '#1478a3'; x.fill();
    }
    // แสงสว่างกลาง + ขอบมืด ให้สายตาพุ่งไปที่โลโก้
    let g = x.createRadialGradient(CX, CY, 40, CX, CY, 520);
    g.addColorStop(0, 'rgba(160,236,255,.75)'); g.addColorStop(.45, 'rgba(90,200,240,.25)'); g.addColorStop(1, 'rgba(90,200,240,0)');
    x.fillStyle = g; x.fillRect(0, 0, W, H);
    g = x.createRadialGradient(CX, CY, 380, CX, CY, 820);
    g.addColorStop(0, 'rgba(3,20,40,0)'); g.addColorStop(1, 'rgba(3,20,40,.7)');
    x.fillStyle = g; x.fillRect(0, 0, W, H);

    // ---------- ผิวน้ำด้านล่าง (แถบพิกเซลเป็นคลื่น)
    const waterTop = 520;
    const wave = (y0, amp, len, col, phase) => {
      x.fillStyle = col; x.beginPath(); x.moveTo(0, H);
      for (let xx = 0; xx <= W; xx += 10) x.lineTo(xx, Math.round((y0 + Math.sin(xx / len + phase) * amp) / 5) * 5);
      x.lineTo(W, H); x.closePath(); x.fill();
    };
    wave(waterTop, 10, 70, '#38b6e0', 0);
    wave(waterTop + 18, 9, 55, '#1d93c4', 1.7);
    wave(waterTop + 44, 7, 48, '#106f9e', .6);
    for (let i = 0; i < 40; i++) px(rnd() * W, waterTop + 30 + rnd() * 80, 16 + rnd() * 26, 4, 'rgba(200,245,255,.55)');

    // ---------- ฟองอากาศ + ประกาย
    const bubble = (bx, by, r) => {
      x.strokeStyle = 'rgba(220,250,255,.85)'; x.lineWidth = 3; x.beginPath(); x.arc(bx, by, r, 0, Math.PI * 2); x.stroke();
      px(bx - r * .45, by - r * .5, Math.max(3, r * .35), Math.max(3, r * .35), '#ffffff');
    };
    for (let i = 0; i < 22; i++) {
      const bx = rnd() * W, by = 40 + rnd() * 470;
      if (Math.abs(bx - CX) < 330 && Math.abs(by - CY) < 190) continue; // ไม่ทับโลโก้
      bubble(bx, by, 5 + rnd() * 9);
    }
    const sparkle = (sx, sy, s, col) => {
      x.fillStyle = col;
      x.fillRect(sx - s / 6, sy - s, s / 3, s * 2); x.fillRect(sx - s, sy - s / 6, s * 2, s / 3);
      x.fillRect(sx - s / 3, sy - s / 3, s * 2 / 3, s * 2 / 3);
    };

    // ---------- น้ำกระเซ็น
    const splash = (sx, sy, w) => {
      for (let i = 0; i < 16; i++) {
        const a = Math.PI + (i / 15) * Math.PI, d = w * (.4 + rnd() * .7), s = 6 + rnd() * 10;
        px(sx + Math.cos(a) * d * .9, sy + Math.sin(a) * d * .8, s, s, i % 3 ? '#e6fbff' : '#8fdcf5');
      }
      x.fillStyle = '#e6fbff';
      x.beginPath(); x.ellipse(sx, sy + 6, w * .75, 12, 0, 0, Math.PI * 2); x.fill();
      x.fillStyle = '#8fdcf5';
      x.beginPath(); x.ellipse(sx, sy + 10, w * .5, 7, 0, 0, Math.PI * 2); x.fill();
    };
    // หยดน้ำตามแนวกระโดด (จากจุดกระเซ็นถึงตัวปลา)
    const trail = (x0, y0, x1, y1) => {
      for (let i = 1; i < 9; i++) {
        const t = i / 9, tx = x0 + (x1 - x0) * t + (rnd() - .5) * 24, ty = y0 + (y1 - y0) * t + (rnd() - .5) * 24;
        const s = 5 + (1 - t) * 8; px(tx, ty, s, s, 'rgba(230,251,255,.9)');
      }
    };

    // ---------- ปลา (เฟรมแรกของ strip 128x128) หมุนตามแนวกระโดด
    const drawFish = (k, fx, fy, size, angle, flip) => {
      x.save(); x.translate(fx, fy); x.rotate(angle); if (flip) x.scale(-1, 1);
      x.shadowColor = 'rgba(0,20,40,.45)'; x.shadowOffsetY = 10; x.shadowBlur = 0;
      x.imageSmoothingEnabled = true; x.imageSmoothingQuality = 'high';
      x.drawImage(img[k], 0, 0, 128, 128, -size / 2, -size / 2, size, size);
      x.restore();
    };
    // [ปลา, x, y, ขนาด, มุม, กลับด้าน, จุดกระเซ็น x]
    const leaps = [
      ['nila', 205, 300, 250, -0.55, false, 120],
      ['chon', 1005, 300, 255, 0.55, true, 1090],
      ['carp', 300, 470, 170, -0.25, false, 230],
      ['swai', 905, 470, 175, 0.3, true, 980],
    ];
    for (const [k, fx, fy, size, a, flip, sx] of leaps) { splash(sx, waterTop + 6, 70); trail(sx, waterTop, fx, fy + size * .2); }
    for (const [k, fx, fy, size, a, flip] of leaps) drawFish(k, fx, fy, size, a, flip);
    // ปลาเล็กลอยมุมบน
    drawFish('tap', 110, 95, 120, -0.15, false);
    drawFish('nuan', 1095, 100, 115, 0.2, true);
    drawFish('rad', 470, 585, 110, 0, true);
    drawFish('dook', 760, 590, 110, 0, false);

    // ---------- โลโก้: AQUA / FARM ทองนูน 3 มิติ เอียงนิดให้มีพลัง
    x.save(); x.translate(CX, CY); x.rotate(-0.045);
    const logoLine = (t, y, size) => {
      x.font = size + 'px Malibold'; x.textAlign = 'center'; x.textBaseline = 'middle'; x.lineJoin = 'round';
      // ความหนา (extrude)
      for (let d = 18; d > 0; d -= 2) {
        x.lineWidth = size / 5; x.strokeStyle = '#2a1405'; x.strokeText(t, 0, y + d);
        x.fillStyle = d > 10 ? '#7a3a0c' : '#a8541a'; x.fillText(t, 0, y + d);
      }
      x.lineWidth = size / 5; x.strokeStyle = '#2a1405'; x.strokeText(t, 0, y);
      const gr = x.createLinearGradient(0, y - size / 2, 0, y + size / 2);
      gr.addColorStop(0, '#fff7c2'); gr.addColorStop(.35, '#ffe066'); gr.addColorStop(.7, '#ffb627'); gr.addColorStop(1, '#f08a12');
      x.fillStyle = gr; x.fillText(t, 0, y);
      // แสงเงาวาวด้านบน
      x.save(); x.beginPath(); x.rect(-600, y - size / 2, 1200, size * .32); x.clip();
      x.fillStyle = 'rgba(255,255,255,.55)'; x.fillText(t, 0, y); x.restore();
    };
    logoLine('AQUA', -88, 188);
    logoLine('FARM', 82, 188);
    // ริบบิ้น From Farm to Food (เหมือนในเกม)
    x.font = '40px Malisemi'; const rw = x.measureText('From Farm to Food').width + 70, ry = 196;
    px(-rw / 2 + 6, ry - 30 + 8, rw, 62, '#24521c');
    px(-rw / 2, ry - 30, rw, 62, '#4f9a2e');
    px(-rw / 2, ry - 30, rw, 6, '#79c24a');
    x.fillStyle = '#fffbe8'; x.textAlign = 'center'; x.textBaseline = 'middle'; x.fillText('From Farm to Food', 0, ry + 2);
    x.restore();

    // ประกายรอบโลโก้
    for (const [sx, sy, s] of [[340, 120, 16], [870, 150, 20], [905, 330, 12], [300, 360, 12], [620, 50, 14], [780, 95, 9]]) {
      sparkle(sx, sy, s, '#fffbe0'); sparkle(sx, sy, s * .45, '#ffe066');
    }
    return c.toDataURL('image/png');
  })()`);
  writeFileSync(resolve(root, 'web/og.png'), Buffer.from(url.split(',')[1], 'base64'));
  console.log('wrote web/og.png', W + 'x' + H);
} finally {
  b.close();
}
