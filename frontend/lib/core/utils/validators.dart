/// Form validation, in one place, in Arabic.
///
/// Every function has the shape `TextFormField.validator` wants — `String? Function(String?)` —
/// so it drops straight in and composes:
///
/// ```dart
/// TextFormField(validator: Validators.libyanPhone)
/// TextFormField(validator: Validators.compose([Validators.required, Validators.minLength(3)]))
/// ```
///
/// **These are a courtesy, not a guarantee.** The server validates everything again and its
/// 422 is the real answer — a client check exists to save a round-trip and to put the message
/// next to the field, never to be trusted. Where a rule here is looser or stricter than the
/// API's, the API wins.
///
/// No `BuildContext` and no localisation lookup: the app is Arabic-only, and threading a
/// context into a validator is what pushes teams into calling them from places that have none.
/// If a second language ever lands, these become the `ar` implementation behind one interface.
library;

abstract final class ValidationMessages {
  static const String required = 'هذا الحقل مطلوب';
  static const String digitsOnly = 'يجب إدخال أرقام فقط';
  static const String invalidNumber = 'رقم غير صحيح';
  static const String positiveNumber = 'يجب أن يكون الرقم أكبر من صفر';
  static const String email = 'البريد الإلكتروني غير صحيح';
  static const String phoneLength = 'رقم الهاتف يجب أن يكون 10 أرقام';
  static const String phonePrefix = 'رقم الهاتف يجب أن يبدأ بـ 091 أو 092 أو 093 أو 094 أو 095';
  static const String contactPhoneLength = 'رقم الهاتف يجب أن يكون من 9 إلى 15 رقماً';
  static const String passwordLength = 'كلمة المرور يجب ألا تقل عن 8 أحرف';
  static const String passwordMismatch = 'كلمتا المرور غير متطابقتين';
  static const String url = 'الرابط غير صحيح';
  static const String coordinatePair = 'أدخل خط العرض وخط الطول معاً أو اتركهما فارغين';
}

typedef Validator = String? Function(String?);

abstract final class Validators {
  // ── presence ───────────────────────────────────────────────────────────────

  static String? required(String? input) =>
      (input == null || input.trim().isEmpty) ? ValidationMessages.required : null;

  /// Runs the checks in order and stops at the first complaint, so the user is told one thing
  /// at a time rather than handed a list.
  static Validator compose(List<Validator> validators) {
    return (String? input) {
      for (final validate in validators) {
        final error = validate(input);
        if (error != null) return error;
      }

      return null;
    };
  }

  /// Wraps a validator so an empty value passes. This is how an optional field is expressed —
  /// never by writing a second, near-identical validator.
  static Validator optional(Validator validator) {
    return (String? input) =>
        (input == null || input.trim().isEmpty) ? null : validator(input);
  }

  // ── text ───────────────────────────────────────────────────────────────────

  static Validator minLength(int min, {String? label}) {
    return (String? input) {
      final error = required(input);
      if (error != null) return error;

      // Runes, not code units: an Arabic name with a combining mark, or an emoji, counts as
      // one character to the person typing it.
      if (input!.trim().runes.length < min) {
        return '${label ?? 'النص'} يجب ألا يقل عن $min أحرف';
      }

      return null;
    };
  }

  static Validator maxLength(int max, {String? label}) {
    return (String? input) {
      if (input == null) return null;
      if (input.trim().runes.length > max) {
        return '${label ?? 'النص'} يجب ألا يزيد عن $max حرفاً';
      }

      return null;
    };
  }

  // ── numbers ────────────────────────────────────────────────────────────────

  /// A whole number, with Arabic-Indic digits accepted — a Libyan keyboard produces ١٢٣ and
  /// refusing it would be a bug the user cannot diagnose.
  static Validator integer({bool allowZero = true, int? min, int? max}) {
    return (String? input) {
      final error = required(input);
      if (error != null) return error;

      final normalised = toWesternDigits(input!.trim());

      // No sign, no fraction, no leading zeros except "0" itself.
      if (!RegExp(r'^(?:0|[1-9]\d*)$').hasMatch(normalised)) {
        return ValidationMessages.digitsOnly;
      }

      final value = int.tryParse(normalised);
      if (value == null) return ValidationMessages.digitsOnly;
      if (!allowZero && value == 0) return ValidationMessages.positiveNumber;
      if (min != null && value < min) return 'أقل قيمة مسموحة هي $min';
      if (max != null && value > max) return 'أكبر قيمة مسموحة هي $max';

      return null;
    };
  }

  /// A price or a weight. Accepts a comma as the decimal mark, because that is what an Arabic
  /// keyboard offers first.
  static Validator decimal({bool allowZero = true, double? min, double? max}) {
    return (String? input) {
      final error = required(input);
      if (error != null) return error;

      final normalised = toWesternDigits(input!.trim()).replaceAll(',', '.');
      final value = double.tryParse(normalised);

      if (value == null) return ValidationMessages.invalidNumber;
      if (!allowZero && value <= 0) return ValidationMessages.positiveNumber;
      if (min != null && value < min) return 'أقل قيمة مسموحة هي $min';
      if (max != null && value > max) return 'أكبر قيمة مسموحة هي $max';

      return null;
    };
  }

  // ── identity ───────────────────────────────────────────────────────────────

  static String? email(String? input) {
    final error = required(input);
    if (error != null) return error;

    final pattern = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

    return pattern.hasMatch(input!.trim()) ? null : ValidationMessages.email;
  }

  /// A Libyan mobile: ten digits starting 091–095.
  ///
  /// The API accepts 9–15 digits so it can also hold a landline; the app is stricter because
  /// every number it collects today is a mobile, and catching a typo here beats a 422.
  static String? libyanPhone(String? input) {
    final error = required(input);
    if (error != null) return error;

    final digits = toWesternDigits(input!.trim());

    if (digits.length != 10 || !RegExp(r'^\d{10}$').hasMatch(digits)) {
      return ValidationMessages.phoneLength;
    }

    const prefixes = ['091', '092', '093', '094', '095'];

    return prefixes.any(digits.startsWith) ? null : ValidationMessages.phonePrefix;
  }

  /// A number a *customer* can be reached on — nine to fifteen digits, exactly what the API
  /// accepts.
  ///
  /// Looser than [libyanPhone] on purpose, and this is the one place the difference matters:
  /// a customer may be a shop reached on a landline (0213334444), and the stricter mobile rule
  /// would refuse a real customer with a message they cannot act on. Staff sign in with a
  /// mobile, so [libyanPhone] stays as it is for that.
  static String? contactPhone(String? input) {
    final error = required(input);
    if (error != null) return error;

    final digits = toWesternDigits(input!.trim());

    return RegExp(r'^\d{9,15}$').hasMatch(digits)
        ? null
        : ValidationMessages.contactPhoneLength;
  }

  static String? password(String? input) {
    final error = required(input);
    if (error != null) return error;

    return input!.length < 8 ? ValidationMessages.passwordLength : null;
  }

  static Validator confirmPassword(String Function() original) {
    return (String? input) {
      final error = required(input);
      if (error != null) return error;

      return input == original() ? null : ValidationMessages.passwordMismatch;
    };
  }

  static String? url(String? input) {
    final error = required(input);
    if (error != null) return error;

    final uri = Uri.tryParse(input!.trim());
    final isHttp = uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');

    return (isHttp && uri.host.contains('.')) ? null : ValidationMessages.url;
  }

  // ── domain ─────────────────────────────────────────────────────────────────

  /// A pin is both numbers or neither — the API rejects half of one, and so should the form,
  /// before the user has to find out over the network.
  static String? coordinatePair({String? latitude, String? longitude}) {
    final hasLat = latitude != null && latitude.trim().isNotEmpty;
    final hasLng = longitude != null && longitude.trim().isNotEmpty;

    if (hasLat != hasLng) return ValidationMessages.coordinatePair;

    return null;
  }

  static Validator get latitude => optional(decimal(min: -90, max: 90));

  static Validator get longitude => optional(decimal(min: -180, max: 180));

  // ── helpers ────────────────────────────────────────────────────────────────

  /// ٠١٢٣ and ۰۱۲۳ become 0123. Both the Arabic-Indic and the Persian sets appear on keyboards
  /// people actually use here.
  static String toWesternDigits(String input) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();

    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);

      final arabicIndex = arabicIndic.indexOf(char);
      if (arabicIndex != -1) {
        buffer.write(arabicIndex);
        continue;
      }

      final persianIndex = persian.indexOf(char);
      if (persianIndex != -1) {
        buffer.write(persianIndex);
        continue;
      }

      buffer.write(char);
    }

    return buffer.toString();
  }
}
