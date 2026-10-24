import 'dart:collection';
import 'dart:convert';

/// على الويب: يُبقي `extra` كما هو عبر زرَّي الرجوع والتقدّم في المتصفّح.
///
/// **المتصفّح يحفظ كلَّ خطوةٍ في سجلّه نصّاً**، وgo_router يكتب `extra` معها بـJSON. والـ`extra`
/// في هذا التطبيق كائناتٌ — الطلبية، الفلتر، خانةُ `PopResult` — فيُكتب `null` مكانها، والشاشةُ
/// التي يُرجع إليها بزرّ المتصفّح تُبنى من جديد كأنها رابطٌ فُتح من خارج التطبيق: الفلترُ يصير
/// «الكل»، والعنوانُ يفقد اسمه. هنا يُكتب في السجلّ رقمٌ، والكائنُ نفسه يبقى في الذاكرة تحت ذلك
/// الرقم ما بقيت الصفحة.
///
/// **تحديثُ الصفحة يمحو الذاكرة**، فيعود `extra` إلى `null` — وهذا ما صُمّمت له كلُّ شاشة: رابطٌ
/// بلا `extra` يفتح أوسعَ ما يقدر عليه، أو صفحةَ السجلّ نفسه كما في روابط التعديل.
///
/// ما يُكتب بـJSON كما هو (نصٌّ، رقم، `null`) يُكتب بنفسه؛ والكائنات وحدها تُحفظ بالرقم. والعددُ
/// محدودٌ بـ[_capacity]، يُرمى أقدمُها — جلسةُ يومٍ كاملٍ من التنقّل لا تملأ الذاكرة.
final class SessionExtraCodec extends Codec<Object?, Object?> {
  SessionExtraCodec();

  static const int _capacity = 500;

  /// المفتاحُ الذي يميّز رقمَ كائنٍ محفوظٍ عن قيمةٍ كُتبت بنفسها.
  static const String _held = 'held';
  static const String _plain = 'plain';

  final LinkedHashMap<int, Object?> _byId = LinkedHashMap();
  final LinkedHashMap<Object?, int> _ids = LinkedHashMap.identity();
  int _next = 0;

  @override
  late final Converter<Object?, Object?> encoder = _Encoder(this);

  @override
  late final Converter<Object?, Object?> decoder = _Decoder(this);

  Object? _encode(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return [_plain, value];
    }

    final id = _ids[value] ?? _hold(value);

    return [_held, id];
  }

  int _hold(Object value) {
    final id = _next++;
    _byId[id] = value;
    _ids[value] = id;

    if (_byId.length > _capacity) {
      final oldest = _byId.keys.first;
      _ids.remove(_byId.remove(oldest));
    }

    return id;
  }

  Object? _decode(Object? encoded) => switch (encoded) {
    [_plain, final Object? value] => value,
    [_held, final int id] => _byId[id],
    _ => null,
  };
}

final class _Encoder extends Converter<Object?, Object?> {
  const _Encoder(this._codec);

  final SessionExtraCodec _codec;

  @override
  Object? convert(Object? input) => _codec._encode(input);
}

final class _Decoder extends Converter<Object?, Object?> {
  const _Decoder(this._codec);

  final SessionExtraCodec _codec;

  @override
  Object? convert(Object? input) => _codec._decode(input);
}
