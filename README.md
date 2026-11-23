# AQUA FARM — From Farm to Food

เกมมือถือจำลองฟาร์มปลา เล่นเป็นรายวัน (กด "จบวัน") ธีมภัยพิบัติ
เตรียมเสบียงรับมือน้ำท่วม / แล้ง / น้ำเสีย / ร้อนจัด

เล่นบนเว็บได้ทันที และติดตั้งลงหน้าจอ iPhone ให้เปิดเต็มจอเหมือนแอป (PWA)

---

## 📱 ติดตั้งบน iPhone (Add to Home Screen)

1. เปิดลิงก์เกมด้วย **Safari** (ต้องเป็น Safari)
   `https://<ชื่อผู้ใช้ GitHub>.github.io/<ชื่อ repo>/`
2. กดปุ่ม **Share** (สี่เหลี่ยมมีลูกศรชี้ขึ้น ⬆️) ที่แถบล่าง
3. เลื่อนลงแล้วเลือก **Add to Home Screen** (เพิ่มไปยังหน้าจอโฮม)
4. ชื่อจะขึ้นเป็น **AQUA FARM** แล้วกด **Add** (เพิ่ม)
5. เปิดเกมจากไอคอนปลาบนหน้าจอโฮม เกมจะเปิด **เต็มจอ** ไม่มีแถบของ Safari

> หมุนโทรศัพท์เป็นแนวตั้งเสมอ (ถ้าหมุนเป็นแนวนอน เกมจะขึ้นข้อความให้หมุนกลับ)

### ⚠️ เรื่องเซฟเกมบน iPhone

เกมบันทึกลงในเครื่อง (localStorage ของเบราว์เซอร์) ไม่ได้อัปโหลดขึ้นเซิร์ฟเวอร์ มีข้อควรรู้ดังนี้

- **ไอคอนบนหน้าจอโฮมกับแท็บ Safari เก็บเซฟแยกกัน** เซฟที่เล่นในแท็บ Safari จะไม่ปรากฏในแอปบนหน้าจอโฮม (และกลับกัน) จึงควรติดตั้งก่อน แล้วเล่นจากไอคอนตลอด
- **ลบไอคอนออกจากหน้าจอโฮม = ลบเซฟทั้งหมดของไอคอนนั้น**
- **โหมด Private Browsing** ปิดแท็บแล้วเซฟหาย
- ถ้าเล่นในแท็บ Safari (ไม่ได้ติดตั้ง) แล้วไม่ได้เปิดเว็บนานเกิน 7 วัน Safari อาจล้างข้อมูลเว็บทิ้ง แอปที่ติดตั้งบนหน้าจอโฮมไม่โดนกฎนี้
- เกมเซฟอัตโนมัติทุกครั้งที่กด "จบวัน" และตอนกลับเมนูหลัก หรือกด ⚙️ → "บันทึกเกม" ได้ตลอด

---

## 🚀 Deploy ขึ้น GitHub Pages (ทำครั้งเดียว)

ระบบ build และ deploy อัตโนมัติอยู่ใน `.github/workflows/deploy.yml`

1. สร้าง repo ใหม่บน GitHub (Public หรือ Private ก็ได้ ถ้า Private ต้องเป็นแพ็กเกจที่รองรับ Pages)
2. push โค้ดโฟลเดอร์นี้ขึ้น branch `main`
   ```bash
   git init
   git add .
   git commit -m "AQUA FARM"
   git branch -M main
   git remote add origin https://github.com/<ชื่อผู้ใช้>/<ชื่อ repo>.git
   git push -u origin main
   ```
3. ที่ repo บน GitHub ไปที่ **Settings → Pages → Build and deployment → Source** เลือก **GitHub Actions**
4. ไปที่แท็บ **Actions** แล้วรอ workflow **Deploy to GitHub Pages** ทำงานเสร็จ (ถ้ายังไม่เริ่ม กด **Run workflow**)
5. เปิดเกมได้ที่ `https://<ชื่อผู้ใช้>.github.io/<ชื่อ repo>/`

ทุกครั้งที่ push เข้า `main` จะ deploy ใหม่ให้อัตโนมัติ โดยรัน `flutter analyze` และ `flutter test` ก่อน
ถ้าเทสต์ไม่ผ่านจะไม่ deploy

**base-href ตั้งให้อัตโนมัติจากชื่อ repo** (`/<ชื่อ repo>/`) เปลี่ยนชื่อ repo ก็ไม่ต้องแก้อะไร
ถ้า repo ชื่อ `<ชื่อผู้ใช้>.github.io` จะใช้ `/` ให้เอง

---

## 🛠️ พัฒนาในเครื่อง

ต้องมี Flutter 3.50.1 (stable)

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome                 # เล่นบนเว็บ
flutter build web --release --base-href /<ชื่อ repo>/   # build แบบเดียวกับบน GitHub Pages
```

### โครงโปรเจกต์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `reference/index.html` | เกมต้นแบบ (แหล่งความจริงของกติกา) |
| `lib/data/` | ข้อมูลปลา อาหาร สูตร อุปกรณ์ ภัยพิบัติ |
| `lib/game/` | ตรรกะเกม (Dart ล้วน ไม่ผูกกับ UI) |
| `lib/save/` | เซฟ 3 ช่อง (shared_preferences) |
| `lib/ui/` | หน้าจอแนวตั้ง (Riverpod) |
| `assets/pixel/` | ภาพพิกเซลที่ส่งออกจากต้นแบบ |
| `web/` | หน้าเว็บ ไอคอน และ manifest ของ PWA |
| `tool/` | สคริปต์ Node: ส่งออกภาพพิกเซล, สร้างไอคอน, แคปหน้าจอ, ทดสอบเซฟบน Safari |

### สคริปต์ใน `tool/` (ต้องมี Node 22+ และ Chrome)

```bash
node tool/export_sprites.mjs   # ส่งออกภาพพิกเซลจาก reference/index.html → assets/pixel/
node tool/make_icons.mjs       # สร้างไอคอนแอป → web/icons/ และ web/favicon.png
```

ทดสอบเซฟบน WebKit (เอนจินเดียวกับ Safari) จำลอง iPhone:

```bash
npm i playwright && npx playwright install webkit
flutter build web --release --base-href /aqua_farm/ -o <โฟลเดอร์>/aqua_farm
node tool/safari_save_test.mjs <โฟลเดอร์> <โฟลเดอร์รูปผลลัพธ์>
```
