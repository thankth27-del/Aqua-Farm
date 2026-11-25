/// ข้อมูลเวอร์ชันที่ฝังตอน build (ตั้งใน .github/workflows/deploy.yml)
///   `--dart-define=BUILD_SHA=<commit 7 ตัว> --dart-define=BUILD_TIME=<วันเวลาไทย>`
/// build ในเครื่องโดยไม่ตั้งค่า → "dev"
library;

const kBuildSha = String.fromEnvironment('BUILD_SHA', defaultValue: 'dev');
const kBuildTime = String.fromEnvironment('BUILD_TIME');

/// ข้อความเวอร์ชันมุมเมนูพัก เช่น "เวอร์ชัน e75dea1 · 25/11/2026 15:19"
String get buildLabel => kBuildTime.isEmpty
    ? 'เวอร์ชัน $kBuildSha'
    : 'เวอร์ชัน $kBuildSha · $kBuildTime';
