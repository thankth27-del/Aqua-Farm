/// ฟังก์ชันคณิตที่ให้ผลเหมือน JavaScript ของต้นแบบ
library;

/// เหมือน Math.round ของ JS (ปัดครึ่งขึ้นเสมอ รวมทั้งค่าติดลบ)
int jsRound(num x) => (x + 0.5).floor();

/// เหมือน +x.toFixed(2) ของ JS
double toFixed2(double x) => double.parse(x.toStringAsFixed(2));

/// ปัดทศนิยม 1 ตำแหน่ง เหมือน Math.round(x*10)/10
double round1(num x) => jsRound(x * 10) / 10;

int clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);
double clampDouble(double v, double lo, double hi) =>
    v < lo ? lo : (v > hi ? hi : v);
