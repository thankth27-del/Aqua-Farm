// ภาพชั่วคราว (placeholder) ของ "ลุงทอง" 3 อารมณ์ → assets/characters/uncle_<อารมณ์>.png
// ภาพพิกเซล 32x32 (เกมขยายแบบไม่เบลอ) — มีภาพจริงเมื่อไร วางไฟล์ทับชื่อเดิมได้เลย
// รัน: node tool/make_uncle.mjs
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { deflateSync } from 'node:zlib';

const root = resolve(import.meta.dirname, '..');
const out = resolve(root, 'assets/characters');
mkdirSync(out, { recursive: true });

const N = 32;
const C = {
  k: [43, 29, 20], // เส้นขอบ
  s: [217, 160, 102], // ผิว
  S: [185, 122, 69], // เงาผิว
  h: [232, 196, 106], // งอบ
  H: [176, 136, 56], // เงางอบ
  w: [240, 240, 236], // ผม/หนวดขาว
  g: [170, 170, 165], // ผมเทา
  c: [47, 93, 138], // เสื้อม่อฮ่อม
  C: [33, 63, 94],
  m: [122, 59, 46], // ปาก
  p: [236, 130, 120], // แก้มแดง
  b: [120, 190, 240], // หยดเหงื่อ
  W: [255, 255, 255],
};

function base() {
  const g = Array.from({ length: N }, () => Array(N).fill(null));
  const set = (x, y, c) => {
    if (x >= 0 && y >= 0 && x < N && y < N) g[y][x] = c;
  };
  // เสื้อ (ไหล่กว้างลงล่าง)
  for (let y = 24; y < N; y++) {
    const hw = 9 + (y - 24);
    for (let x = 16 - hw; x < 16 + hw; x++) set(x, y, y === 24 || x === 16 - hw || x === 15 + hw ? 'k' : (x < 16 ? 'c' : 'C'));
  }
  for (let y = 25; y < N; y++) set(15, y, 'k'), set(16, y, 'k'); // สาบเสื้อ
  // คอ
  for (let y = 21; y < 25; y++) for (let x = 13; x < 19; x++) set(x, y, x === 13 || x === 18 ? 'k' : 'S');
  // หัว (วงรี)
  for (let y = 8; y < 24; y++)
    for (let x = 6; x < 26; x++) {
      const d = ((x - 15.5) / 8.5) ** 2 + ((y - 15) / 7.6) ** 2;
      if (d <= 1) set(x, y, d > 0.82 ? 'k' : (x > 20 ? 'S' : 's'));
    }
  // หู
  for (const ex of [6, 25]) for (let y = 14; y < 18; y++) set(ex, y, y === 14 || y === 17 ? 'k' : 's');
  // ผมข้างสีเทา/ขาว
  for (let y = 10; y < 15; y++) {
    set(8, y, 'g'), set(9, y, 'w'), set(22, y, 'w'), set(23, y, 'g');
  }
  // งอบ (ทรงกรวยกว้าง)
  for (let y = 1; y < 10; y++) {
    const hw = y === 1 ? 2 : 2 + (y - 1) * 1.75;
    for (let x = Math.round(16 - hw); x < Math.round(16 + hw); x++) {
      const edge = x === Math.round(16 - hw) || x === Math.round(16 + hw) - 1 || y === 1;
      set(x, y, edge ? 'k' : ((x + y) % 4 === 0 ? 'H' : 'h'));
    }
  }
  for (let x = 0; x < N; x++) set(x, 10, x === 0 || x === N - 1 ? 'k' : 'H'); // ปีกงอบ
  for (let x = 1; x < N - 1; x++) set(x, 11, 'k');
  // หนวดขาว
  for (let x = 11; x < 21; x++) set(x, 19, 'w');
  for (let x = 12; x < 20; x++) set(x, 18, 'w');
  set(11, 20, 'w'), set(20, 20, 'w');
  return { g, set };
}

const moods = {
  smile({ set }) {
    // ตายิ้ม (โค้งคว่ำ) + คิ้วขาว + แก้มแดง + ปากยิ้ม
    for (const ex of [11, 19]) {
      set(ex, 15, 'k'), set(ex + 1, 14, 'k'), set(ex + 2, 15, 'k');
      set(ex, 13, 'w'), set(ex + 1, 13, 'w'), set(ex + 2, 13, 'w');
    }
    set(10, 17, 'p'), set(11, 17, 'p'), set(21, 17, 'p'), set(22, 17, 'p');
    for (let x = 13; x < 19; x++) set(x, 21, 'm');
    set(12, 20, 'm'), set(19, 20, 'm');
  },
  think({ set }) {
    // ตามองขึ้น + คิ้วข้างหนึ่งยก + ปากตรง
    for (const ex of [11, 19]) {
      set(ex + 1, 14, 'k'), set(ex + 2, 14, 'k'), set(ex + 1, 15, 'k'), set(ex + 2, 15, 'W');
    }
    for (let x = 11; x < 14; x++) set(x, 13, 'w');
    for (let x = 19; x < 22; x++) set(x, 12, 'w');
    for (let x = 14; x < 18; x++) set(x, 21, 'm');
    // มือแตะคาง
    for (let y = 21; y < 25; y++) for (let x = 20; x < 24; x++) set(x, y, x === 20 || y === 24 ? 'k' : 's');
  },
  worry({ set }) {
    // ตากลม + คิ้วเอียงขึ้นตรงกลาง + ปากเบะ + เหงื่อ
    for (const ex of [11, 19]) {
      set(ex + 1, 14, 'k'), set(ex + 1, 15, 'k'), set(ex, 15, 'k'), set(ex, 14, 'W');
    }
    set(11, 13, 'w'), set(12, 12, 'w'), set(13, 12, 'w');
    set(21, 13, 'w'), set(20, 12, 'w'), set(19, 12, 'w');
    for (let x = 14; x < 18; x++) set(x, 20, 'm');
    set(13, 21, 'm'), set(18, 21, 'm');
    set(24, 9, 'b'), set(24, 10, 'b'), set(23, 11, 'b'), set(24, 11, 'b'), set(25, 11, 'b');
  },
};

function crc32(buf) {
  let c, crc = 0xffffffff;
  for (let n = 0; n < buf.length; n++) {
    c = (crc ^ buf[n]) & 0xff;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    crc = (crc >>> 8) ^ c;
  }
  return (crc ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
}
function png(g) {
  const raw = Buffer.alloc(N * (N * 4 + 1));
  for (let y = 0; y < N; y++) {
    raw[y * (N * 4 + 1)] = 0;
    for (let x = 0; x < N; x++) {
      const c = g[y][x];
      const o = y * (N * 4 + 1) + 1 + x * 4;
      if (c) [raw[o], raw[o + 1], raw[o + 2], raw[o + 3]] = [...C[c], 255];
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(N, 0), ihdr.writeUInt32BE(N, 4);
  ihdr[8] = 8, ihdr[9] = 6;
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(raw)),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

for (const [name, draw] of Object.entries(moods)) {
  const b = base();
  draw(b);
  writeFileSync(resolve(out, `uncle_${name}.png`), png(b.g));
}
console.log('wrote', Object.keys(moods).length, 'portraits to', out);
