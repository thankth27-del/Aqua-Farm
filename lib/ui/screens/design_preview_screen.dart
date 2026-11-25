import 'package:material_ui/material_ui.dart';

import '../design/design_system.dart';
import '../theme/pixel_icon.dart';

/// หน้า debug "ตัวอย่างระบบดีไซน์": รวมทุกโทเคนและ widget กลางไว้ดูในที่เดียว
/// (เปิดจากเมนูหลักเฉพาะโหมด debug หรือเว็บที่มี ?ds ใน URL)
class DesignPreviewScreen extends StatelessWidget {
  const DesignPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildDesignTheme(),
      child: Scaffold(
        backgroundColor: DsColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(DsSpace.m),
                children: const [
                  _Header(),
                  _Section('สี', child: _Colors()),
                  _Section('ตัวอักษร (Sarabun)', child: _Type()),
                  _Section('ระยะห่าง 4 / 8 / 16 / 24', child: _Spacing()),
                  _Section('ปุ่ม', child: _Buttons()),
                  _Section('ค่าสถานะ (StatChip)', child: _Stats()),
                  _Section('การ์ด (GameCard)', child: _Cards()),
                  _Section('แถบความคืบหน้า', child: _Bars()),
                  _Section('หน้าต่างยืนยัน / แผ่นล่าง', child: _Dialogs()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DsSpace.m),
    child: Row(
      children: [
        SecondaryButton(
          label: 'กลับ',
          onPressed: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: DsSpace.m),
        const Expanded(child: Text('ตัวอย่างระบบดีไซน์', style: DsText.title)),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section(this.title, {required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DsSpace.l),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [SectionTitle(title), child],
    ),
  );
}

class _Colors extends StatelessWidget {
  const _Colors();

  static const swatches = [
    ('หลัก', DsColors.primary),
    ('หลัก (อ่อน)', DsColors.primarySoft),
    ('เน้น', DsColors.accent),
    ('เน้น (อ่อน)', DsColors.accentSoft),
    ('เตือน', DsColors.danger),
    ('เตือน (อ่อน)', DsColors.dangerSoft),
    ('สำเร็จ', DsColors.success),
    ('สำเร็จ (อ่อน)', DsColors.successSoft),
    ('พื้นหลัง', DsColors.background),
    ('การ์ด', DsColors.surface),
    ('ตัวอักษร', DsColors.text),
    ('ตัวอักษรรอง', DsColors.textMuted),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: DsSpace.s,
    runSpacing: DsSpace.s,
    children: [
      for (final (name, c) in swatches)
        SizedBox(
          width: 96,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(DsRadius.small),
                  border: Border.all(color: DsColors.border),
                ),
              ),
              const SizedBox(height: DsSpace.xs),
              Text(name, style: DsText.caption),
            ],
          ),
        ),
    ],
  );
}

class _Type extends StatelessWidget {
  const _Type();

  @override
  Widget build(BuildContext context) => const GameCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('หัวข้อ 20 — ตลาดวันนี้', style: DsText.title),
        SizedBox(height: DsSpace.s),
        Text(
          'เนื้อหา 16 — ขายปลาที่โตแล้วเพื่อซื้อวัตถุดิบ ทำอาหารเก็บเป็นเสบียงก่อนน้ำท่วม',
          style: DsText.body,
        ),
        SizedBox(height: DsSpace.s),
        Text('ค่าเด่น 16 หนา — 500 บาท', style: DsText.strong),
        SizedBox(height: DsSpace.s),
        Text('คำอธิบายเล็ก 13 — ราคาเปลี่ยนทุกวัน', style: DsText.caption),
      ],
    ),
  );
}

class _Spacing extends StatelessWidget {
  const _Spacing();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      for (final s in const [DsSpace.xs, DsSpace.s, DsSpace.m, DsSpace.l]) ...[
        Column(
          children: [
            Container(width: s, height: s, color: DsColors.primary),
            const SizedBox(height: DsSpace.xs),
            Text('${s.toInt()}', style: DsText.caption),
          ],
        ),
        const SizedBox(width: DsSpace.l),
      ],
    ],
  );
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PrimaryButton(
        key: const ValueKey('ds-primary'),
        label: 'ขายปลา',
        icon: const PixelIcon('coin', size: 24),
        expand: true,
        onPressed: () {},
      ),
      const SizedBox(height: DsSpace.s),
      Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'ไปตลาด',
              expand: true,
              onPressed: () {},
            ),
          ),
          const SizedBox(width: DsSpace.s),
          Expanded(
            child: SecondaryButton(
              label: 'ทิ้ง',
              danger: true,
              expand: true,
              onPressed: () {},
            ),
          ),
        ],
      ),
      const SizedBox(height: DsSpace.s),
      Row(
        children: [
          const Expanded(
            child: PrimaryButton(
              label: 'ทำอาหาร (กดไม่ได้)',
              expand: true,
              onPressed: null,
            ),
          ),
          const SizedBox(width: DsSpace.s),
          Expanded(
            child: PrimaryButton(
              label: 'ยืนยันทิ้ง',
              danger: true,
              expand: true,
              onPressed: () {},
            ),
          ),
        ],
      ),
      const SizedBox(height: DsSpace.xs),
      const Text(
        'หน้าหนึ่งมีปุ่มหลัก (ส้ม) ปุ่มเดียว ที่เหลือเป็นปุ่มรอง · ปุ่มแดงใช้ยืนยันการลบเท่านั้น',
        style: DsText.caption,
      ),
    ],
  );
}

class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(
        child: StatChip(
          label: 'เงิน',
          value: '500฿',
          icon: PixelIcon('coin', size: 22),
        ),
      ),
      SizedBox(width: DsSpace.xs),
      Expanded(
        child: StatChip(
          label: 'วันที่',
          value: '3/20',
          icon: PixelIcon('cal', size: 22),
        ),
      ),
      SizedBox(width: DsSpace.xs),
      Expanded(
        child: StatChip(
          label: 'น้ำ',
          value: 'ดีมาก',
          tone: DsTone.success,
          icon: PixelIcon('drop', size: 22),
        ),
      ),
      SizedBox(width: DsSpace.xs),
      Expanded(
        child: StatChip(
          label: 'อาหาร',
          value: '1 วัน',
          tone: DsTone.danger,
          icon: PixelIcon('crate', size: 22),
        ),
      ),
    ],
  );
}

class _Cards extends StatelessWidget {
  const _Cards();

  Widget _fish(String id, String name, int price, {bool selected = false}) =>
      Expanded(
        child: GameCard(
          selected: selected,
          onTap: () {},
          semanticLabel: '$name ราคา $price บาท',
          child: Column(
            children: [
              PixelIcon('f_$id', size: 64),
              const SizedBox(height: DsSpace.xs),
              Text(name, style: DsText.strong),
              Text('$price บาท', style: DsText.caption),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          _fish('nila', 'ปลานิล', 40, selected: true),
          const SizedBox(width: DsSpace.s),
          _fish('dook', 'ปลาดุก', 30),
        ],
      ),
      const SizedBox(height: DsSpace.s),
      const GameCard(
        tone: DsTone.danger,
        child: Row(
          children: [
            PixelIcon('warn', size: 32),
            SizedBox(width: DsSpace.s),
            Expanded(
              child: Text(
                'พรุ่งนี้น้ำท่วม — เตรียมกระสอบทรายและเสบียง 4 วัน',
                style: DsText.body,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: DsSpace.s),
      const GameCard(
        tone: DsTone.success,
        child: Row(
          children: [
            Expanded(child: Text('เสบียงพอแล้ว', style: DsText.strong)),
            DsTag('5 วัน', tone: DsTone.success),
          ],
        ),
      ),
    ],
  );
}

class _Bars extends StatelessWidget {
  const _Bars();

  @override
  Widget build(BuildContext context) => const GameCard(
    child: Column(
      children: [
        ProgressBar(
          value: .8,
          label: 'ความอิ่ม',
          trailing: '80',
          color: DsColors.accent,
        ),
        SizedBox(height: DsSpace.m),
        ProgressBar(value: .6, label: 'ปลาโต', trailing: '60%'),
        SizedBox(height: DsSpace.m),
        ProgressBar(
          value: .25,
          label: 'คุณภาพน้ำ',
          trailing: 'แย่',
          color: DsColors.danger,
        ),
      ],
    ),
  );
}

class _Dialogs extends StatelessWidget {
  const _Dialogs();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SecondaryButton(
          key: const ValueKey('ds-open-dialog'),
          label: 'เปิดหน้าต่างยืนยัน',
          expand: true,
          onPressed: () => showGameDialog(
            context,
            title: 'ขายปลานิล 1 ตัว?',
            message: 'ได้ 90 บาท (เงินคงเหลือ 590 บาท)',
            icon: const PixelIcon('f_nila', size: 64),
            confirmLabel: 'ขาย',
          ),
        ),
      ),
      const SizedBox(width: DsSpace.s),
      Expanded(
        child: SecondaryButton(
          key: const ValueKey('ds-open-sheet'),
          label: 'เปิดแผ่นล่าง',
          expand: true,
          onPressed: () => showGameSheet<void>(
            context,
            title: 'เมนู / พัก',
            builder: (c) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryButton(
                  label: 'เล่นต่อ',
                  expand: true,
                  onPressed: () => Navigator.pop(c),
                ),
                const SizedBox(height: DsSpace.s),
                SecondaryButton(
                  label: 'บันทึกเกม',
                  expand: true,
                  onPressed: () => Navigator.pop(c),
                ),
                const SizedBox(height: DsSpace.s),
                SecondaryButton(
                  label: 'กลับเมนูหลัก',
                  expand: true,
                  onPressed: () => Navigator.pop(c),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
