/// บทพูดของโหมดเนื้อเรื่อง: "ลุงทอง" เล่าเรื่องและสอนไปพร้อมกัน 9 บท
///
/// ไฟล์ข้อมูลเดียวของบทพูดทั้งหมด (UI ไม่ฝังข้อความเอง) — แก้คำพูดที่นี่ได้เลย
/// - ทุกบรรทัดยาว 1-2 ประโยค พร้อมอารมณ์ของลุง (ยิ้ม/คิด/กังวล)
/// - [ScriptLine.point] = สิ่งที่ลุงกำลังพูดถึง (UI ไฮไลต์เฉพาะสิ่งนั้น)
/// - ตัวเลขในการ์ดความรู้อ่านจากข้อมูลเกมจริง (lib/data) และติดป้าย "ค่าในเกม"
library;

import '../game/story.dart' show StoryCh, StoryTarget;
import 'constants.dart';
import 'disaster_data.dart';
import 'equipment_data.dart';
import 'fish_data.dart';
import 'food_data.dart';
import 'health_data.dart';

/// ชื่อและภาพของตัวละครผู้สอน
abstract final class Uncle {
  static const name = 'ลุงทอง';

  /// ภาพตามอารมณ์: วางไฟล์ใหม่ทับชื่อเดิมได้เลย (ภาพพิกเซลสี่เหลี่ยมจัตุรัส)
  static String asset(UncleMood m) => 'assets/characters/uncle_${m.name}.png';
}

/// อารมณ์ของลุงในแต่ละบรรทัด
enum UncleMood { smile, think, worry }

/// บทพูด 1 บรรทัด (1-2 ประโยค)
class ScriptLine {
  const ScriptLine(this.mood, this.text, {this.point});

  final UncleMood mood;
  final String text;

  /// สิ่งที่ลุงพูดถึง → ไฮไลต์เฉพาะสิ่งนี้ (null = ไม่ไฮไลต์)
  final StoryTarget? point;
}

const _s = UncleMood.smile;
const _t = UncleMood.think;
const _w = UncleMood.worry;

/// ตัวเลือก 1 ข้อของจุดตัดสินใจ — [id] ใช้ในตรรกะเกมเพื่อทำผลจริง
class ScriptChoice {
  const ScriptChoice({
    required this.id,
    required this.label,
    required this.detail,
    required this.reply,
  });

  final String id;

  /// ข้อความบนปุ่ม (สั้น)
  final String label;

  /// บรรทัดรองใต้ปุ่ม
  final String detail;

  /// ลุงตอบหลังเลือก
  final List<ScriptLine> reply;
}

/// จุดตัดสินใจของผู้เล่น (บทลงบ่อ ตลาด ถนอมอาหาร ภัยจริง)
class ChoiceScene {
  const ChoiceScene({
    required this.id,
    required this.ask,
    required this.options,
  });

  final String id;

  /// ลุงถามก่อนให้เลือก (บรรทัดสุดท้ายแสดงพร้อมปุ่มตัวเลือก)
  final List<ScriptLine> ask;
  final List<ScriptChoice> options;
}

/// ตัวเลือกของคำถามสั้น (บทเรียนย่อย) — ตอบผิดไม่ลงโทษ ลุงอธิบายแล้วให้เลือกใหม่
class QuizOption {
  const QuizOption(this.text, {this.correct = false, required this.explain});

  final String text;
  final bool correct;

  /// ลุงอธิบายหลังเลือกข้อนี้
  final String explain;
}

class Quiz {
  const Quiz(this.question, this.options);

  final String question;
  final List<QuizOption> options;
}

/// บทเรียนย่อย: สอนทีละเรื่อง → ถาม → ลองทำ
/// (บทคุณภาพน้ำ: ดูแลน้ำ · บทถนอมอาหาร: ทีละวิธี · บทปลาป่วย: อาการ/ป้องกัน)
class Lesson {
  const Lesson({
    required this.id,
    required this.teach,
    required this.quiz,
    required this.tryIt,
  });

  /// รหัสบทเรียน (บทถนอมอาหาร = id ใน kPreserveMethods)
  final String id;
  final List<ScriptLine> teach;
  final Quiz quiz;

  /// ชวนลองทำวิธีนี้
  final List<ScriptLine> tryIt;
}

/// ข้อเท็จจริง 1 แถวบนการ์ด
class CardFact {
  const CardFact(this.label, this.value, {this.inGame = true});

  final String label;
  final String value;

  /// ตัวเลขมาจากเกม → แสดงป้าย "ค่าในเกม" (ไม่ใช่ค่าจริงในชีวิตจริง)
  final bool inGame;
}

/// การ์ดความรู้ "ลุงรู้มา" (1 ใบต่อบท เก็บในสมุดบันทึกลุงทอง)
class KnowledgeCard {
  const KnowledgeCard({
    required this.id,
    required this.title,
    required this.body,
    required this.facts,
  });

  final String id;
  final String title;

  /// เรื่องเล่า/เหตุผลสั้น ๆ จากประสบการณ์ลุง
  final String body;

  /// ตัวเลขจากข้อมูลเกม (คำนวณทุกครั้งที่แสดง ข้อมูลเปลี่ยน การ์ดเปลี่ยนตาม)
  final List<CardFact> Function() facts;
}

/// บทพูดทั้งบท
class ChapterScript {
  const ChapterScript({
    required this.chapter,
    required this.title,
    required this.intro,
    this.onTarget = const {},
    required this.onDone,
    this.choice,
    this.lessons = const [],
    this.dayLines = const {},
    this.ready = const [],
    this.notReady = const [],
    this.onFail = const [],
    required this.card,
  });

  /// 1-9 (ดู [StoryCh])
  final int chapter;
  final String title;

  /// เปิดบท: ลุงเล่า "ทำไม" ก่อนให้ทำ
  final List<ScriptLine> intro;

  /// ลุงพูดก่อนผู้เล่นทำสิ่งนั้นครั้งแรกในบท (ไฮไลต์ตาม point)
  final Map<StoryTarget, List<ScriptLine>> onTarget;

  /// ทำเป้าหมายบทสำเร็จ
  final List<ScriptLine> onDone;
  final ChoiceScene? choice;

  /// บทเรียนย่อยตามลำดับ
  final List<Lesson> lessons;

  /// บทภัยจริง: ลุงพูดคั่นแต่ละวันของภัย (key = วันของภัย 0..)
  final Map<int, List<ScriptLine>> dayLines;

  /// บทภัยจริง เริ่มภัย: เตรียมพร้อม / เตรียมไม่พอ (ไม่ตำหนิ เสนอทางออก)
  final List<ScriptLine> ready;
  final List<ScriptLine> notReady;

  /// แพ้บทนี้ (ให้กำลังใจ + บอกทางแก้)
  final List<ScriptLine> onFail;
  final KnowledgeCard card;
}

String _shelf(String food) => '${kFoods[food]!.shelfDays} วัน';
String _baht(int v) => '$v฿';

/// บท 1-9 (index 0-8)
final List<ChapterScript> kStoryScript = [
  // ------------------------------------------------------------------ บท 1
  ChapterScript(
    chapter: StoryCh.farm,
    title: 'ลงบ่อ',
    intro: const [
      ScriptLine(
        _s,
        'อ้าว หลาน! มาอยู่บ้านข้าง ๆ ลุงแล้วสินะ ลุงชื่อทอง เลี้ยงปลามาสี่สิบปีแล้ว',
      ),
      ScriptLine(_t, 'บ่อปลาไม่ได้ให้แค่เงินนะ มันคือตู้กับข้าวของบ้านเราด้วย'),
      ScriptLine(
        _w,
        'ตอนน้ำท่วมใหญ่ครั้งนั้น ถนนตัดขาด ตลาดปิดเป็นอาทิตย์ บ้านไหนมีปลามีเสบียงถึงจะอยู่รอด',
      ),
      ScriptLine(
        _s,
        'เพราะงั้นเริ่มจากเลือกปลาให้ดีก่อน แล้วค่อยปล่อยลงบ่อกัน',
      ),
    ],
    choice: const ChoiceScene(
      id: 'fish',
      ask: [
        ScriptLine(
          _t,
          'ปลาแต่ละชนิดนิสัยไม่เหมือนกัน หลานอยากเริ่มกับตัวไหนดี?',
        ),
      ],
      options: [
        ScriptChoice(
          id: 'nila',
          label: 'ปลานิล',
          detail: 'ทนทาน โตปานกลาง',
          reply: [
            ScriptLine(
              _s,
              'ปลานิลนี่ลุงชอบ เลี้ยงง่าย ไม่ค่อยป่วย เหมาะกับมือใหม่ที่สุด',
            ),
          ],
        ),
        ScriptChoice(
          id: 'dook',
          label: 'ปลาดุก',
          detail: 'ทนที่สุด แต่โตช้า',
          reply: [
            ScriptLine(
              _t,
              'ปลาดุกอึดมาก น้ำแย่ก็ยังรอด แต่ต้องใจเย็นรอมันโตหน่อยนะ',
            ),
          ],
        ),
        ScriptChoice(
          id: 'tap',
          label: 'ปลาตะเพียน',
          detail: 'ถูก โตเร็ว ขายได้น้อย',
          reply: [
            ScriptLine(
              _s,
              'ตะเพียนโตไว ได้กินได้ขายเร็ว แต่ราคาขายไม่สูงนักนะหลาน',
            ),
          ],
        ),
      ],
    ),
    onTarget: const {
      StoryTarget.buyFish: [
        ScriptLine(
          _s,
          'ไปที่ร้านปลา ซื้อตัวที่เลือกไว้ 3 ตัว',
          point: StoryTarget.buyFish,
        ),
      ],
      StoryTarget.feed: [
        ScriptLine(
          _t,
          'ปลาหิวก็ไม่โต ให้มากไปน้ำก็เสีย ให้ "พอดี" นี่แหละดีที่สุด',
          point: StoryTarget.feed,
        ),
      ],
      StoryTarget.endDay: [
        ScriptLine(
          _s,
          'ให้อาหารแล้วก็พักได้ กด "จบวัน" ไปดูกันพรุ่งนี้',
          point: StoryTarget.endDay,
        ),
      ],
    },
    onDone: const [
      ScriptLine(_s, 'เห็นไหม ปลาตัวโตขึ้นทุกวัน หลานเลี้ยงเป็นแล้วนะ'),
    ],
    card: KnowledgeCard(
      id: 'fish',
      title: 'ปลาแต่ละชนิดเหมาะกับคนละแบบ',
      body: 'ลุงเลือกปลาจากสองเรื่อง: ทนน้ำแย่ได้แค่ไหน และโตเร็วแค่ไหน ปลาที่ทนจะช่วยตอนน้ำเสียหรือน้ำท่วม',
      facts: () => [
        for (final id in const ['nila', 'dook', 'tap'])
          CardFact(
            kFish[id]!.name,
            'ราคา ${_baht(kFish[id]!.buyPrice)} · โต${kFish[id]!.growthLabel} '
            '(~${kFish[id]!.daysToGrow} วัน) · ทน ${kFish[id]!.toughness}/5',
          ),
      ],
    ),
  ),

  // ------------------------------------------------------------------ บท 2
  ChapterScript(
    chapter: StoryCh.water,
    title: 'คุณภาพน้ำ',
    intro: const [
      ScriptLine(_s, 'ปลาโตดีนะหลาน แต่สังเกตไหม น้ำในบ่อเริ่มขุ่นแล้ว'),
      ScriptLine(
        _t,
        'อาหารที่เหลือกับขี้ปลากลายเป็นของเสียในน้ำ ตัวกรองต้องทำงานหนักขึ้นทุกวัน',
      ),
      ScriptLine(
        _w,
        'ถ้าปล่อยไว้ น้ำเสีย ปลาจะป่วยและโตช้า ยิ่งช่วงภัยพิบัติยิ่งแก้ยาก',
      ),
    ],
    lessons: const [
      Lesson(
        id: 'filter',
        teach: [
          ScriptLine(
            _s,
            'ตัวกรองเหมือนฟองน้ำ ดักเศษอาหารกับขี้ปลา และเป็นบ้านของแบคทีเรียดีที่ช่วยกินของเสีย',
          ),
          ScriptLine(
            _t,
            'พอสกปรกมากก็กรองได้น้อยลง ต้องล้าง แต่ล้างบ่อยเกินไปแบคทีเรียดีก็หายไปด้วย',
          ),
        ],
        quiz: Quiz('ควรล้างตัวกรองเมื่อไร?', [
          QuizOption(
            'เมื่อตัวกรองเริ่มสกปรก',
            correct: true,
            explain: 'ใช่เลย! ล้างเมื่อสกปรก ไม่ต้องล้างทุกวัน แบคทีเรียดีจะได้อยู่ต่อ',
          ),
          QuizOption(
            'ทุกวัน ยิ่งบ่อยยิ่งดี',
            explain:
                'ล้างบ่อยไป แบคทีเรียดีที่ช่วยกินของเสียจะหายนะ ลองเลือกใหม่ดู',
          ),
          QuizOption(
            'ไม่ต้องล้างเลย',
            explain: 'ปล่อยไว้ตัวกรองจะตัน กรองของเสียไม่ไหว ลองใหม่นะ',
          ),
        ]),
        tryIt: [
          ScriptLine(
            _s,
            'ไปหน้าปลา กด "ดูแลน้ำ" แล้วลองล้างตัวกรองดู',
            point: StoryTarget.water,
          ),
        ],
      ),
      Lesson(
        id: 'change',
        teach: [
          ScriptLine(
            _s,
            'เปลี่ยนน้ำบางส่วนช่วยเจือจางของเสียได้เร็ว แต่ต้องเสียค่าน้ำ',
          ),
          ScriptLine(
            _t,
            'ปลาหายใจทั้งคืน ออกซิเจนต่ำไปก็เติมอากาศ หรือซื้อเครื่องเติมอากาศเปิดไว้',
          ),
          ScriptLine(
            _t,
            'อยากรู้ค่าน้ำจริง ๆ ต้องมีชุดตรวจน้ำ ไม่มีก็ดูจากสีน้ำกับอาการปลาไปก่อน',
          ),
        ],
        quiz: Quiz('น้ำแย่และออกซิเจนต่ำ ทำอะไรได้บ้าง?', [
          QuizOption(
            'เปลี่ยนน้ำ และเติมอากาศ',
            correct: true,
            explain: 'เก่งมาก! สองอย่างนี้ช่วยให้น้ำดีขึ้นได้ทันที',
          ),
          QuizOption(
            'ให้อาหารเพิ่ม',
            explain:
                'อาหารยิ่งมาก ของเสียยิ่งเยอะ น้ำจะแย่ลงอีกนะ ลองเลือกใหม่ดู',
          ),
          QuizOption(
            'รอให้น้ำดีขึ้นเอง',
            explain: 'รอเฉย ๆ ปลาอาจป่วยก่อนน้ำจะดีขึ้น ลองใหม่นะ',
          ),
        ]),
        tryIt: [
          ScriptLine(
            _t,
            'ล้างตัวกรองแล้วน้ำยังไม่ "ดี" ค่อยเปลี่ยนน้ำนะ',
            point: StoryTarget.water,
          ),
        ],
      ),
    ],
    onTarget: const {
      StoryTarget.water: [
        ScriptLine(
          _s,
          'กด "ดูแลน้ำ" ล้างตัวกรองที่สกปรก ถ้าน้ำยังแย่ค่อยเปลี่ยนน้ำ',
          point: StoryTarget.water,
        ),
      ],
      StoryTarget.feed: [
        ScriptLine(
          _t,
          'ให้อาหาร "พอดี" ก็พอ ให้มากไปตัวกรองจะสกปรกเร็ว',
          point: StoryTarget.feed,
        ),
      ],
      StoryTarget.endDay: [
        ScriptLine(
          _s,
          'วันนี้ทำครบแล้ว กด "จบวัน" แล้วมาดูน้ำกันพรุ่งนี้',
          point: StoryTarget.endDay,
        ),
      ],
    },
    onDone: const [
      ScriptLine(_s, 'น้ำใสขึ้นเยอะเลย! ปลาสบายตัว โตได้ดี'),
      ScriptLine(
        _t,
        'จำไว้นะ ตัวกรองสกปรกขึ้นทุกวัน ยิ่งให้อาหารมากยิ่งสกปรกเร็ว',
      ),
    ],
    card: KnowledgeCard(
      id: 'water',
      title: 'น้ำดี ปลาดี',
      body: 'ของเสียจากอาหารและขี้ปลาสะสมทุกวัน ตัวกรองกับแบคทีเรียดีช่วยกำจัด ล้างตัวกรองเมื่อสกปรก เปลี่ยนน้ำเมื่อของเสียสูง',
      facts: () => [
        CardFact(
          'ตัวกรองสกปรกขึ้นต่อวัน',
          'ให้อาหารน้อย +${kFilterDirtPerDay[1]} · พอดี +${kFilterDirtPerDay[2]} · มาก +${kFilterDirtPerDay[3]}',
        ),
        CardFact(
          'ล้างตัวกรองได้เมื่อสกปรก',
          'ตั้งแต่ $kCleanFilterMin · แบคทีเรียดีลด $kCleanFilterBioLoss',
        ),
        CardFact('เปลี่ยนน้ำ', 'ครั้งละ ${_baht(kChangeWaterCost)}'),
        CardFact(
          'เครื่องเติมอากาศ',
          'ค่าไฟคืนละ ${_baht(kAeratorPowerCost)} · ออกซิเจนตอนเช้าไม่ต่ำกว่า ${kAeratorO2Floor.toInt()}%',
        ),
        CardFact('น้ำ "ดี"', 'คะแนนน้ำตั้งแต่ $kWaterGoodLine'),
      ],
    ),
  ),

  // ------------------------------------------------------------------ บท 3
  ChapterScript(
    chapter: StoryCh.market,
    title: 'ตลาด',
    intro: const [
      ScriptLine(_s, 'ปลาโตแล้ว! ปลาที่โตเต็มวัยขายได้ราคาเต็ม'),
      ScriptLine(
        _t,
        'เงินจากปลาเอาไปซื้อเครื่องปรุงกับอุปกรณ์ ที่จะช่วยเราตอนเกิดภัย',
      ),
      ScriptLine(
        _s,
        'จับปลาที่โตแล้วก่อน แล้วค่อยไปตลาดกัน',
        point: StoryTarget.catchFish,
      ),
    ],
    choice: const ChoiceScene(
      id: 'sell',
      ask: [
        ScriptLine(_t, 'ได้ปลามาแล้ว จะขายหมดเลย หรือเก็บไว้ทำกับข้าวบ้าง?'),
      ],
      options: [
        ScriptChoice(
          id: 'sell_one',
          label: 'ขาย 1 ตัว เก็บที่เหลือ',
          detail: 'ได้เงินบ้าง มีปลาไว้ทำอาหาร',
          reply: [ScriptLine(_s, 'ฉลาด! มีเงินติดตัว และยังมีปลาไว้เข้าครัว')],
        ),
        ScriptChoice(
          id: 'sell_all',
          label: 'ขายทั้งหมด',
          detail: 'ได้เงินมากตอนนี้',
          reply: [
            ScriptLine(
              _t,
              'ได้เงินก้อนดี แต่จำไว้นะ ปลาที่เหลือในบ่อจะต้องโตทันให้เราทำกับข้าวด้วย',
            ),
          ],
        ),
      ],
    ),
    onTarget: const {
      StoryTarget.sellFish: [
        ScriptLine(
          _s,
          'ขายปลาที่ตลาดได้เลย กดยืนยันก่อนขายทุกครั้งนะ',
          point: StoryTarget.sellFish,
        ),
      ],
      StoryTarget.buyIngredient: [
        ScriptLine(
          _t,
          'ราคาวัตถุดิบเปลี่ยนทุกวัน ดูลูกศรเทียบกับเมื่อวาน วันไหนถูกค่อยซื้อเยอะ',
          point: StoryTarget.buyIngredient,
        ),
      ],
    },
    onDone: const [
      ScriptLine(_s, 'ได้เงินก้อนแรกแล้ว! เก็บไว้ใช้ให้คุ้มนะหลาน'),
    ],
    card: KnowledgeCard(
      id: 'market',
      title: 'ขายตอนโตเต็มวัย ซื้อตอนราคาลง',
      body: 'ปลาที่ยังไม่โตขายได้น้อย ส่วนวัตถุดิบราคาขึ้นลงทุกวัน คนที่ดูราคาก่อนซื้อจะเหลือเงินไว้เตรียมภัย',
      facts: () => [
        for (final id in const ['nila', 'dook', 'tap'])
          CardFact(
            'ขาย${kFish[id]!.name} (โตเต็มวัย)',
            _baht(kFish[id]!.sellPrice),
          ),
        const CardFact('ราคาวัตถุดิบ', 'เปลี่ยนทุกวัน', inGame: false),
      ],
    ),
  ),

  // ------------------------------------------------------------------ บท 4
  ChapterScript(
    chapter: StoryCh.kitchen,
    title: 'ครัว',
    intro: const [
      ScriptLine(_t, 'ปลาสดเก็บไว้นานไม่ได้ ต้องทำเป็นอาหารก่อน'),
      ScriptLine(
        _s,
        'อาหารสุกกินแล้วอิ่ม มีแรงทำงานต่อ แต่ก็เสียภายในไม่กี่วันนะ',
      ),
      ScriptLine(
        _s,
        'ไปครัวกัน ลองทำเมนูแรกด้วยปลาของเราเอง',
        point: StoryTarget.cook,
      ),
    ],
    onTarget: const {
      StoryTarget.buyIngredient: [
        ScriptLine(
          _t,
          'ทำอาหารต้องมีเครื่องปรุง ไปซื้อที่ตลาดก่อนนะ',
          point: StoryTarget.buyIngredient,
        ),
      ],
      StoryTarget.cook: [
        ScriptLine(
          _s,
          'เลือกเมนูที่มีวัตถุดิบครบ แล้วกด "ทำอาหาร" ได้เลย',
          point: StoryTarget.cook,
        ),
      ],
      StoryTarget.eat: [
        ScriptLine(
          _w,
          'ท้องร้องแล้วนั่น! ไปกินที่คลัง หิวนาน ๆ จะหมดแรงนะ',
          point: StoryTarget.eat,
        ),
      ],
    },
    onDone: const [
      ScriptLine(_s, 'หอมจริง! ฝีมือหลานใช้ได้เลยนะเนี่ย'),
      ScriptLine(
        _t,
        'แต่อาหารสุกอยู่ได้ไม่กี่วัน บทหน้าลุงจะสอนเก็บให้นานขึ้น',
      ),
    ],
    card: KnowledgeCard(
      id: 'kitchen',
      title: 'อาหารสุกอร่อย แต่อยู่ได้ไม่นาน',
      body: 'ทำอาหารพอกินไม่ต้องทำเยอะเกิน ถ้ามีตู้เย็นจะช่วยชะลอการเสีย แต่ตู้เย็นต้องใช้ไฟฟ้า',
      facts: () => [
        CardFact('ปลาทอด เก็บได้', _shelf('fry')),
        CardFact('ปลาทอด เพิ่มความอิ่ม', '+${kFoods['fry']!.hunger}'),
        CardFact('ตู้เย็น', kEquipment['fridge']!.description),
      ],
    ),
  ),

  // ------------------------------------------------------------------ บท 5
  ChapterScript(
    chapter: StoryCh.preserve,
    title: 'ถนอมอาหาร',
    intro: const [
      ScriptLine(
        _w,
        'ตอนน้ำท่วม ไฟดับ ตู้เย็นใช้ไม่ได้ ตลาดก็ปิด อาหารสุกเสียหมดในไม่กี่วัน',
      ),
      ScriptLine(_t, 'คนรุ่นลุงเลยถนอมปลาไว้ เก็บได้เป็นอาทิตย์เป็นเดือน'),
      ScriptLine(_s, 'มีอยู่ 4 วิธี ลุงจะสอนทีละวิธี แล้วหลานลองทำดูนะ'),
    ],
    lessons: const [
      Lesson(
        id: 'dried',
        teach: [
          ScriptLine(_s, 'วิธีแรก ตากแห้ง แค่ผ่าปลาแล้วตากแดดบนแผงตาก'),
          ScriptLine(_t, 'ไม่ต้องใช้ไฟฟ้าเลย น้ำในตัวปลาหายไป เชื้อโรคก็โตยาก'),
        ],
        quiz: Quiz('ทำไมปลาตากแห้งถึงเก็บได้นาน?', [
          QuizOption(
            'เพราะน้ำในตัวปลาน้อยลง',
            correct: true,
            explain:
                'ถูกต้อง! เชื้อที่ทำให้อาหารเน่าต้องการน้ำ ไม่มีน้ำก็โตไม่ได้',
          ),
          QuizOption(
            'เพราะแดดทำให้ปลาสุก',
            explain: 'ไม่ใช่หรอก แดดแค่ช่วยไล่น้ำออกจากเนื้อปลา ลองดูอีกทีนะ',
          ),
          QuizOption(
            'เพราะเอาไปแช่เย็น',
            explain: 'ตากแห้งไม่ต้องใช้ตู้เย็นเลยนะหลาน ลองเลือกใหม่ดู',
          ),
        ]),
        tryIt: [
          ScriptLine(
            _s,
            'ลองตากปลาดู ต้องมีแผงตากปลาก่อน ซื้อได้ที่ตลาด',
            point: StoryTarget.preserve,
          ),
        ],
      ),
      Lesson(
        id: 'salted',
        teach: [
          ScriptLine(
            _s,
            'วิธีที่สอง หมักเกลือ ใช้เกลือคลุกปลาแล้วใส่โหลปิดไว้',
          ),
          ScriptLine(_t, 'เกลือดึงน้ำออกจากเนื้อปลา เก็บได้นานกว่าตากแห้งอีก'),
        ],
        quiz: Quiz('หมักเกลือต้องใช้อะไรบ้าง?', [
          QuizOption(
            'เกลือ กับ โหลหมัก',
            correct: true,
            explain: 'ใช่เลย! เกลือ 2 ส่วนกับโหลหมัก 1 ใบ',
          ),
          QuizOption(
            'น้ำส้มสายชู',
            explain:
                'น้ำส้มสายชูเป็นของการดองต่างหาก เดี๋ยวลุงสอนถัดไป ลองใหม่นะ',
          ),
          QuizOption(
            'ไฟฟ้า',
            explain: 'หมักเกลือไม่ต้องใช้ไฟเลย ดีตรงนี้แหละ ลองเลือกใหม่ดู',
          ),
        ]),
        tryIt: [
          ScriptLine(
            _s,
            'ถ้ามีเกลือกับโหล ลองหมักดูได้เลย',
            point: StoryTarget.preserve,
          ),
        ],
      ),
      Lesson(
        id: 'pickled',
        teach: [
          ScriptLine(_s, 'วิธีที่สาม ดอง ใช้น้ำส้มสายชูแช่ปลาในโหล'),
          ScriptLine(
            _t,
            'ความเปรี้ยวทำให้เชื้อโรคอยู่ไม่ได้ เก็บได้หลายสัปดาห์',
          ),
        ],
        quiz: Quiz('การดองใช้อะไรกันไม่ให้ปลาเสีย?', [
          QuizOption(
            'ความเปรี้ยวของน้ำส้มสายชู',
            correct: true,
            explain: 'เก่งมาก! ความเปรี้ยวคือตัวกันเชื้อของการดอง',
          ),
          QuizOption(
            'ความร้อนจากเตา',
            explain: 'การดองไม่ได้ใช้ความร้อนหรอกนะ ลองคิดถึงรสชาติของมันดู',
          ),
          QuizOption(
            'ความเค็มของเกลือ',
            explain: 'นั่นคือการหมักเกลือ ส่วนดองใช้อีกอย่าง ลองใหม่นะ',
          ),
        ]),
        tryIt: [
          ScriptLine(
            _s,
            'โหลใบเดียวกันใช้ดองได้ มีน้ำส้มสายชูก็ลองดูนะ',
            point: StoryTarget.preserve,
          ),
        ],
      ),
      Lesson(
        id: 'canned',
        teach: [
          ScriptLine(_s, 'วิธีสุดท้าย บรรจุกระป๋อง ปิดสนิทจนอากาศเข้าไม่ได้'),
          ScriptLine(
            _t,
            'เก็บได้นานที่สุด แต่เครื่องบรรจุราคาแพง ต้องเก็บเงินก่อน',
          ),
        ],
        quiz: Quiz('ถ้าต้องเก็บอาหารไว้นานที่สุด ควรเลือกวิธีไหน?', [
          QuizOption(
            'บรรจุกระป๋อง',
            correct: true,
            explain: 'ถูกแล้ว! กระป๋องเก็บได้นานที่สุดในสี่วิธี',
          ),
          QuizOption(
            'ทำปลาทอดเก็บไว้',
            explain: 'อาหารสุกอยู่ได้ไม่กี่วันเองนะ ลองนึกถึงวิธีที่ปิดสนิทดู',
          ),
          QuizOption(
            'ตากแห้ง',
            explain:
                'ตากแห้งอยู่ได้ราวสองอาทิตย์ ยังมีวิธีที่นานกว่านั้น ลองใหม่นะ',
          ),
        ]),
        tryIt: [
          ScriptLine(
            _t,
            'กระป๋องไว้ทีหลังก็ได้ ถ้ามีเงินพอค่อยซื้อเครื่องบรรจุ',
          ),
        ],
      ),
    ],
    choice: const ChoiceScene(
      id: 'method',
      ask: [
        ScriptLine(_t, 'รู้ครบสี่วิธีแล้ว หลานจะเริ่มถนอมด้วยวิธีไหนก่อน?'),
      ],
      options: [
        ScriptChoice(
          id: 'dried',
          label: 'ตากแห้ง',
          detail: 'แผงตากถูก ไม่ใช้ไฟ',
          reply: [ScriptLine(_s, 'เริ่มง่าย ๆ ประหยัดด้วย ดีมาก')],
        ),
        ScriptChoice(
          id: 'salted',
          label: 'หมักเกลือ',
          detail: 'เก็บนานขึ้น ต้องมีเกลือ',
          reply: [
            ScriptLine(_s, 'ปลาเค็มนี่ของคู่บ้านลุงเลย เก็บได้เป็นเดือน'),
          ],
        ),
        ScriptChoice(
          id: 'pickled',
          label: 'ดอง',
          detail: 'ใช้น้ำส้มสายชู + โหล',
          reply: [ScriptLine(_s, 'ปลาดองรสเด็ด แถมเก็บได้หลายอาทิตย์')],
        ),
        ScriptChoice(
          id: 'canned',
          label: 'กระป๋อง',
          detail: 'นานที่สุด เครื่องแพง',
          reply: [ScriptLine(_t, 'ลงทุนสูงหน่อย แต่ได้เสบียงที่ทนที่สุด')],
        ),
      ],
    ),
    onTarget: const {
      StoryTarget.buyTool: [
        ScriptLine(
          _t,
          'ต้องมีอุปกรณ์ก่อน ไปซื้อที่ตลาดหมวดอุปกรณ์ครัวนะ',
          point: StoryTarget.buyTool,
        ),
      ],
      StoryTarget.preserve: [
        ScriptLine(
          _s,
          'ไปครัว กด "ถนอม" แล้วเลือกวิธีที่ตัดสินใจไว้',
          point: StoryTarget.preserve,
        ),
      ],
    },
    onDone: const [
      ScriptLine(_s, 'เริ่มถนอมแล้ว! รออีกไม่กี่วันก็ได้เสบียงชุดแรก'),
    ],
    card: KnowledgeCard(
      id: 'preserve',
      title: 'ถนอมอาหาร 4 วิธี',
      body: 'ไล่น้ำออก ใช้เกลือ ใช้ความเปรี้ยว หรือปิดสนิท — ทุกวิธีทำให้เชื้อที่ทำให้อาหารเน่าโตไม่ได้',
      facts: () => [
        for (final m in kPreserveMethods.values)
          CardFact(
            kFoods[m.id]!.name,
            'เก็บได้ ${_shelf(m.id)} · ใช้เวลา ${m.days} วัน · '
            'ใช้${kEquipment[m.equipment]!.name}',
          ),
      ],
    ),
  ),

  // ------------------------------------------------------------------ บท 6
  ChapterScript(
    chapter: StoryCh.sick,
    title: 'ปลาป่วย',
    intro: const [
      ScriptLine(
        _w,
        'หลาน มาดูนี่เร็ว ปลาตัวหนึ่งถูตัวกับขอบบ่อ มีจุดขาวเล็ก ๆ เต็มตัวเลย',
      ),
      ScriptLine(
        _t,
        'ปลาก็ป่วยได้เหมือนคน น้ำแย่ อากาศร้อน หรือหลังน้ำท่วม โรคยิ่งมาง่าย',
      ),
      ScriptLine(
        _s,
        'ไม่ต้องตกใจ ดูอาการให้ดี แล้วเลือกยาให้ตรงโรค ปลาก็หายได้',
      ),
    ],
    lessons: const [
      Lesson(
        id: 'symptom',
        teach: [
          ScriptLine(
            _s,
            'โรคปลาที่เจอบ่อยมีสามแบบ: จุดขาว ตัวด่าง และตกเลือด ดูจากอาการได้',
          ),
          ScriptLine(
            _t,
            'แต่ละโรคใช้ยาไม่เหมือนกัน ใช้ผิดก็เปลืองยา ปลาไม่หาย',
          ),
        ],
        quiz: Quiz('ปลามีจุดขาวเล็ก ๆ ตามตัว ถูตัวกับขอบบ่อ ควรใช้อะไร?', [
          QuizOption(
            'เกลือแช่ปลา',
            correct: true,
            explain: 'ถูกต้อง! จุดขาวเกิดจากปรสิต แช่น้ำเกลือช่วยกำจัดได้',
          ),
          QuizOption(
            'ด่างทับทิม',
            explain: 'ด่างทับทิมใช้กับแผลด่างของโรคตัวด่างนะ ดูอาการอีกที',
          ),
          QuizOption(
            'ยาปฏิชีวนะ',
            explain: 'ยาปฏิชีวนะใช้กับโรคตกเลือดที่มีจุดเลือดออก ไม่ใช่จุดขาว ลองใหม่นะ',
          ),
        ]),
        tryIt: [
          ScriptLine(
            _s,
            'ไปตลาด ซื้อเกลือมาแช่ปลา แล้วกด "รักษาปลา" ที่หน้าปลา',
            point: StoryTarget.buyMedicine,
          ),
        ],
      ),
      Lesson(
        id: 'prevent',
        teach: [
          ScriptLine(
            _t,
            'ยาช่วยได้ แต่ต้นเหตุคือน้ำ ถ้าน้ำแย่มาก ยาก็ไม่ได้ผล',
          ),
          ScriptLine(
            _s,
            'ปลาป่วยแพร่เชื้อให้ตัวอื่นได้ ถ้ามีบ่อพักแยกปลา ย้ายตัวที่ป่วยออกไปก่อน',
          ),
        ],
        quiz: Quiz('ให้ยาถูกแล้ว แต่น้ำในบ่อแย่มาก จะเกิดอะไรขึ้น?', [
          QuizOption(
            'ยาไม่ได้ผล ต้องแก้น้ำด้วย',
            correct: true,
            explain: 'ใช่! รักษาปลาต้องดูแลน้ำไปพร้อมกันเสมอ',
          ),
          QuizOption(
            'ปลาหายเร็วขึ้น',
            explain: 'น้ำแย่ทำให้ปลาอ่อนแอลงนะ ยาจะสู้ไม่ไหว ลองใหม่ดู',
          ),
          QuizOption(
            'ไม่ต่างกันเลย',
            explain: 'ต่างกันมากเลยหลาน น้ำคือบ้านของปลา ลองเลือกใหม่นะ',
          ),
        ]),
        tryIt: [
          ScriptLine(
            _t,
            'ระหว่างรักษา หมั่นกด "ดูแลน้ำ" ให้น้ำดีไว้ด้วยนะ',
            point: StoryTarget.treat,
          ),
        ],
      ),
    ],
    onTarget: const {
      StoryTarget.buyMedicine: [
        ScriptLine(
          _s,
          'ยาปลาอยู่ที่ตลาด ปุ่ม "อุปกรณ์และยาปลา" ซื้อให้ตรงกับโรคนะ',
          point: StoryTarget.buyMedicine,
        ),
      ],
      StoryTarget.treat: [
        ScriptLine(
          _s,
          'กด "รักษาปลา" เลือกตัวที่ป่วย ดูอาการ แล้วเลือกยา',
          point: StoryTarget.treat,
        ),
      ],
      StoryTarget.endDay: [
        ScriptLine(
          _t,
          'ให้ยาแล้ว ต้องรอสักสองสามวันปลาถึงจะหาย กด "จบวัน" ได้เลย',
          point: StoryTarget.endDay,
        ),
      ],
    },
    onFail: const [
      ScriptLine(_w, 'ปลาตัวนั้นไปเสียแล้ว ไม่เป็นไรนะ โรคบางทีก็มาเร็ว'),
      ScriptLine(
        _t,
        'ลองใหม่อีกครั้ง รีบซื้อยาที่ตรงโรคมารักษาตั้งแต่วันแรกนะ',
      ),
    ],
    onDone: const [
      ScriptLine(_s, 'ปลาหายแล้ว! หลานดูอาการเป็นแล้วนะ'),
      ScriptLine(
        _t,
        'ต่อจากนี้ปลาอาจป่วยได้ทุกเมื่อ ดูแลน้ำไว้ก่อนเสมอ ป้องกันดีกว่ารักษา',
      ),
    ],
    card: KnowledgeCard(
      id: 'sick',
      title: 'ดูอาการ เลือกยาให้ตรงโรค',
      body: 'ป้องกันดีกว่ารักษา: น้ำดี ปลาไม่แน่นบ่อ แยกตัวที่ป่วย ถ้าป่วยแล้วให้ดูอาการก่อนเลือกยา',
      facts: () => [
        for (final d in kDiseases.values)
          CardFact(d.name, 'ใช้${_medicineText(d.medicine)}'),
        CardFact('ยาถูกโรค หายใน', '$kTreatDays วัน (ถ้าน้ำไม่แย่มาก)'),
        CardFact('ไม่รักษา ปลาอยู่ได้', 'ราว $kSickDaysToDie วัน'),
      ],
    ),
  ),

  // ------------------------------------------------------------------ บท 7
  ChapterScript(
    chapter: StoryCh.warning,
    title: 'คำเตือน',
    intro: const [
      ScriptLine(_w, 'หลาน! วิทยุประกาศว่าน้ำจะท่วมในอีกไม่กี่วัน'),
      ScriptLine(
        _t,
        'ไม่ต้องตกใจ เรามีเวลาเตรียมตัว ครั้งก่อนลุงรอดมาได้ก็เพราะเตรียมไว้ก่อน',
      ),
      ScriptLine(
        _s,
        'สองเรื่องที่ต้องทำ: อุปกรณ์กันน้ำ กับอาหารให้พอกินตลอดที่น้ำท่วม',
      ),
    ],
    onTarget: const {
      StoryTarget.buyEquipment: [
        ScriptLine(
          _t,
          'กระสอบทรายกั้นน้ำ เครื่องสูบไล่น้ำ ตาข่ายกันปลาหลุด เริ่มจากที่ไหวก่อน',
          point: StoryTarget.buyEquipment,
        ),
      ],
      StoryTarget.cook: [
        ScriptLine(
          _s,
          'ทำอาหารหรือถนอมเพิ่ม ดูช่อง "อาหารพอกิน" ให้ถึงเป้า',
          point: StoryTarget.cook,
        ),
      ],
      StoryTarget.buyIngredient: [
        ScriptLine(
          _w,
          'ก่อนน้ำมา ตลาดยังเปิด ซื้อของที่ต้องใช้ไว้ตอนนี้เลย',
          point: StoryTarget.buyIngredient,
        ),
      ],
    },
    onDone: const [
      ScriptLine(_s, 'เตรียมพร้อมแล้ว! คืนนี้นอนหลับได้สบายขึ้นเยอะ'),
    ],
    card: KnowledgeCard(
      id: 'warning',
      title: 'ของที่ต้องมีก่อนน้ำมา',
      body: 'เตรียมตอนน้ำยังไม่มาถูกกว่าและง่ายกว่าแก้ทีหลังเสมอ — ทั้งอุปกรณ์และอาหาร',
      facts: () {
        final d = kDisasters[DisasterType.flood]!;
        return [
          CardFact('เตือนล่วงหน้า', '${d.leadDays} วัน'),
          CardFact('น้ำท่วมนาน', '${d.duration} วัน'),
          for (final e in d.equipment.entries)
            CardFact(
              kEquipment[e.key]!.name,
              'แนะนำ ${e.value} · ${_baht(kEquipment[e.key]!.price)} · '
              '${kEquipment[e.key]!.use}',
            ),
        ];
      },
    ),
  ),

  // ------------------------------------------------------------------ บท 8
  ChapterScript(
    chapter: StoryCh.disaster,
    title: 'ภัยพิบัติจริง',
    intro: const [
      ScriptLine(_w, 'ฝนเริ่มตกหนักแล้ว ระดับน้ำขึ้นเร็วมาก'),
      ScriptLine(
        _t,
        'ช่วงนี้ตลาดอาจปิด ไฟอาจดับ เราต้องอยู่ด้วยของที่เตรียมไว้',
      ),
    ],
    ready: [
      ScriptLine(_s, 'ของเราพร้อมดี ใจเย็น ๆ กินเมื่อหิว ดูแลบ่อไปทีละวัน'),
    ],
    notReady: [
      ScriptLine(_w, 'อาหารเราอาจไม่พอทั้งช่วง แต่ไม่เป็นไร ค่อย ๆ แก้กันไป'),
      ScriptLine(
        _t,
        'ถ้าตลาดยังเปิด ซื้อของจำเป็นไว้ก่อน ปลาในบ่อก็จับมาทำกินได้นะ',
      ),
    ],
    choice: const ChoiceScene(
      id: 'eat_order',
      ask: [
        ScriptLine(_w, 'ไฟดับแล้ว ตู้เย็นหยุดทำงาน'),
        ScriptLine(_t, 'มีทั้งอาหารสุกและของถนอม หลานจะกินอะไรก่อน?'),
      ],
      options: [
        ScriptChoice(
          id: 'fresh_first',
          label: 'กินอาหารสุกก่อน',
          detail: 'ของสดจะเสียเร็วตอนไฟดับ',
          reply: [
            ScriptLine(
              _s,
              'ใช่เลย! ของที่ใกล้เสียกินก่อน ของถนอมเก็บไว้ยามจำเป็น',
            ),
          ],
        ),
        ScriptChoice(
          id: 'preserved_first',
          label: 'กินของถนอมก่อน',
          detail: 'เก็บอาหารสุกไว้ทีหลัง',
          reply: [
            ScriptLine(
              _t,
              'ได้อยู่ แต่ไฟดับแบบนี้อาหารสุกจะเสียเร็ว ครั้งหน้ากินของสดก่อนนะ',
            ),
          ],
        ),
      ],
    ),
    dayLines: const {
      0: [ScriptLine(_w, 'วันแรก น้ำเริ่มเข้าพื้นที่ ตรวจบ่อกับอุปกรณ์ให้ดี')],
      1: [
        ScriptLine(_w, 'น้ำสูงขึ้นอีกแล้ว ตลาดปิด ใช้เสบียงที่มีอย่างประหยัด'),
      ],
      2: [ScriptLine(_t, 'วันนี้หนักสุด อดทนอีกนิด อิ่มท้องไว้ก่อนนะหลาน')],
      3: [ScriptLine(_s, 'น้ำเริ่มลดแล้ว! เรามาถึงวันสุดท้ายด้วยกัน')],
    },
    onTarget: const {
      StoryTarget.eat: [
        ScriptLine(
          _t,
          'หิวเมื่อไรไปกินที่คลัง อย่าปล่อยให้หิวนาน',
          point: StoryTarget.eat,
        ),
      ],
      StoryTarget.endDay: [
        ScriptLine(
          _s,
          'ทำที่จำเป็นครบแล้ว กด "จบวัน" ไปต่อกัน',
          point: StoryTarget.endDay,
        ),
      ],
    },
    onFail: const [
      ScriptLine(
        _w,
        'ครั้งนี้ไม่รอด แต่ไม่ใช่ความผิดของหลานคนเดียวหรอก ภัยมันหนักจริง ๆ',
      ),
      ScriptLine(
        _t,
        'ลองใหม่อีกครั้ง คราวนี้เก็บอาหารถนอมเพิ่ม และซื้อตาข่ายกับกระสอบทรายให้พอ',
      ),
    ],
    onDone: const [
      ScriptLine(_s, 'น้ำลดแล้ว! เรารอดมาด้วยกัน ลุงภูมิใจในตัวหลานมาก'),
    ],
    card: KnowledgeCard(
      id: 'disaster',
      title: 'ระหว่างภัย กินของใกล้เสียก่อน',
      body: 'ไฟดับเมื่อไร ตู้เย็นช่วยไม่ได้ กินอาหารสุกก่อน เก็บของถนอมไว้ท้ายสุด และอย่าลืมดูแลบ่อทุกวัน',
      facts: () {
        final d = kDisasters[DisasterType.flood]!;
        return [
          CardFact(
            'วันที่ไฟดับ',
            '${d.powerOut.where((x) => x).length} จาก ${d.duration} วัน',
          ),
          CardFact(
            'วันที่ตลาดปิด',
            '${d.marketClosed.where((x) => x).length} จาก ${d.duration} วัน',
          ),
          CardFact('ปลาทอด (อาหารสุก) เก็บได้', _shelf('fry')),
          CardFact('ปลาเค็ม (ของถนอม) เก็บได้', _shelf('salted')),
        ];
      },
    ),
  ),

  // ------------------------------------------------------------------ บท 9
  ChapterScript(
    chapter: StoryCh.summary,
    title: 'สรุป',
    intro: const [
      ScriptLine(_s, 'มานั่งคุยกันหน่อย ลุงอยากเล่าว่าหลานทำได้แค่ไหน'),
    ],
    onDone: const [
      ScriptLine(
        _s,
        'ต่อจากนี้หลานดูแลฟาร์มเองได้แล้ว ภัยครั้งหน้าอาจมาไม่บอกล่วงหน้านะ',
      ),
    ],
    card: KnowledgeCard(
      id: 'summary',
      title: 'เตรียมก่อน รอดก่อน',
      body: 'สี่สิบปีที่ลุงเลี้ยงปลามา บทเรียนเดียวที่สำคัญที่สุดคือ เตรียมไว้ตอนยังมีเวลา',
      facts: () => [
        CardFact(
          'อาหารพอกินตลอดน้ำท่วม',
          '${kDisasters[DisasterType.flood]!.duration} วัน',
        ),
        CardFact(
          'ของถนอมที่เก็บได้นานสุด',
          '${kFoods['canned']!.name} ${_shelf('canned')}',
        ),
      ],
    ),
  ),
];

/// บทสรุป: ตอนจบต่างกันตามเกรดรวม
const Map<String, List<ScriptLine>> kStoryEndingScript = {
  'S': [
    ScriptLine(
      _s,
      'ยอดเยี่ยม! ปลาแทบไม่เสีย อาหารก็พอ หลานเตรียมตัวเก่งกว่าลุงตอนหนุ่ม ๆ อีก',
    ),
    ScriptLine(_s, 'ต่อไปถ้าเพื่อนบ้านลำบาก หลานคือคนที่ช่วยเขาได้นะ'),
  ],
  'A': [
    ScriptLine(_s, 'ทำได้ดีมาก! รอดน้ำท่วมครั้งแรกได้อย่างมั่นคง'),
    ScriptLine(_t, 'ครั้งหน้าเก็บเสบียงเพิ่มอีกนิด จะสบายกว่านี้อีก'),
  ],
  'B': [
    ScriptLine(_t, 'รอดมาได้ก็เก่งแล้ว ครั้งแรกของลุงยังแย่กว่านี้อีก'),
    ScriptLine(_s, 'จำไว้ว่าอุปกรณ์กับอาหารถนอมต้องเตรียมตั้งแต่ได้ยินคำเตือน'),
  ],
};

/// ลุงพูดตอนปลดล็อกโหมดเอาชีวิตรอด
const List<ScriptLine> kStoryUnlockScript = [
  ScriptLine(
    _s,
    'ปลดล็อก "โหมดเอาชีวิตรอด" แล้ว! ไปลองดูแลฟาร์มเองนานขึ้นดูนะ',
  ),
];

/// บทของบทที่ [chapter] (1-9)
ChapterScript scriptOf(int chapter) => kStoryScript[chapter - 1];

/// ชื่อยาพร้อมราคา (เกลือใช้ราคาตลาดวันนั้น จึงบอกจำนวนถุงแทน)
String _medicineText(String id) {
  final m = kMedicines[id]!;
  return m.ingredient
      ? '${m.name} (เกลือ ${m.dose} ถุง)'
      : '${m.name} · ${_baht(m.price)}';
}

/// ให้ยาผิดโรค: ลุงอธิบายว่ายานั้นใช้กับโรคไหน อาการของโรคนี้ และยาที่ถูก
List<ScriptLine> wrongMedicineLines(String med, String disease) {
  final d = kDiseases[disease]!;
  final m = kMedicines[med]!;
  final forD = kDiseases.values.where((x) => x.medicine == med);
  return [
    ScriptLine(
      _t,
      forD.isEmpty
          ? '${m.name}ไม่ได้ใช้กับ${d.name}นะหลาน ปลาเลยยังไม่ดีขึ้น'
          : '${m.name}ใช้กับ${forD.first.name}นะหลาน แต่ตัวนี้เป็น${d.name}',
    ),
    ScriptLine(
      _s,
      'ดูอาการอีกที: ${d.symptom} ต้องใช้${kMedicines[d.medicine]!.name} ลองเลือกใหม่นะ',
      point: StoryTarget.treat,
    ),
  ];
}

/// การ์ดความรู้ทั้งหมดตามลำดับบท
List<KnowledgeCard> get kKnowledgeCards => [
  for (final c in kStoryScript) c.card,
];
