// โหลดแอป: ใช้ CanvasKit ที่ build มาพร้อมแอป (โฟลเดอร์ canvaskit/) ไม่ดึงจาก CDN
// — เครื่องที่เน็ตช้า/บล็อก gstatic จะได้ไม่ค้างหน้าโหลด (ไม่ต้องใส่ --no-web-resources-cdn เอง)
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: 'canvaskit/',
  },
});
