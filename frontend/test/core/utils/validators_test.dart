import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/utils/validators.dart';

/// Validators are pure functions, so they are tested directly — no widget, no pump.
///
/// Arrange - Act - Assert throughout, matching the backend's standard.
void main() {
  group('required', () {
    test('rejects an empty or whitespace-only value', () {
      expect(Validators.required(null), ValidationMessages.required);
      expect(Validators.required(''), ValidationMessages.required);
      expect(Validators.required('   '), ValidationMessages.required);
    });

    test('accepts real text', () {
      expect(Validators.required('طرابلس'), isNull);
    });
  });

  group('libyanPhone', () {
    test('accepts every valid prefix', () {
      for (final prefix in ['091', '092', '093', '094', '095']) {
        expect(Validators.libyanPhone('${prefix}1234567'), isNull, reason: prefix);
      }
    });

    test('rejects a number that is not ten digits', () {
      expect(Validators.libyanPhone('09112345'), ValidationMessages.phoneLength);
      expect(Validators.libyanPhone('091123456789'), ValidationMessages.phoneLength);
    });

    test('rejects an unknown prefix', () {
      expect(Validators.libyanPhone('0991234567'), ValidationMessages.phonePrefix);
    });

    test('accepts Arabic-Indic digits, because that is what the keyboard produces', () {
      // ٠٩١٢٣٤٥٦٧٨ — the same number a Libyan keyboard types.
      expect(Validators.libyanPhone('٠٩١٢٣٤٥٦٧٨'), isNull);
    });
  });

  group('contactPhone', () {
    test('accepts a landline, which libyanPhone refuses', () {
      // A customer may be a shop reached on a landline. Refusing one here would be refusing a
      // real customer over a rule that only ever applied to staff signing in.
      expect(Validators.contactPhone('0213334444'), isNull);
      expect(Validators.libyanPhone('0213334444'), ValidationMessages.phonePrefix);
    });

    test('accepts a mobile too', () {
      expect(Validators.contactPhone('0913334444'), isNull);
    });

    test('holds the API\'s own bounds of nine to fifteen digits', () {
      expect(Validators.contactPhone('12345678'), ValidationMessages.contactPhoneLength);
      expect(Validators.contactPhone('1234567890123456'), ValidationMessages.contactPhoneLength);
      expect(Validators.contactPhone('123456789'), isNull);
      expect(Validators.contactPhone('123456789012345'), isNull);
    });

    test('rejects anything that is not a digit', () {
      expect(Validators.contactPhone('091-333-4444'), ValidationMessages.contactPhoneLength);
    });

    test('accepts Arabic-Indic digits, because that is what the keyboard produces', () {
      expect(Validators.contactPhone('٠٩١٣٣٣٤٤٤٤'), isNull);
    });

    test('is still required', () {
      expect(Validators.contactPhone(''), ValidationMessages.required);
    });
  });

  group('integer', () {
    test('rejects a fraction, a sign and a leading zero', () {
      final validate = Validators.integer();

      expect(validate('1.5'), ValidationMessages.digitsOnly);
      expect(validate('-3'), ValidationMessages.digitsOnly);
      expect(validate('007'), ValidationMessages.digitsOnly);
    });

    test('honours the bounds it was given', () {
      final validate = Validators.integer(min: 100, max: 1000);

      expect(validate('99'), 'أقل قيمة مسموحة هي 100');
      expect(validate('1001'), 'أكبر قيمة مسموحة هي 1000');
      expect(validate('100'), isNull);
    });

    test('rejects zero when told to', () {
      expect(Validators.integer(allowZero: false)('0'), ValidationMessages.positiveNumber);
      expect(Validators.integer()('0'), isNull);
    });
  });

  group('decimal', () {
    test('reads a comma as the decimal mark', () {
      expect(Validators.decimal()('20,5'), isNull);
    });

    test('bounds latitude and longitude to real coordinates', () {
      expect(Validators.latitude('91'), isNotNull);
      expect(Validators.latitude('32.8872'), isNull);
      expect(Validators.longitude('181'), isNotNull);
      expect(Validators.longitude('13.1913'), isNull);
    });

    test('a coordinate is optional, so empty passes', () {
      expect(Validators.latitude(''), isNull);
      expect(Validators.latitude(null), isNull);
    });
  });

  group('coordinatePair', () {
    test('refuses half a pin', () {
      expect(
        Validators.coordinatePair(latitude: '32.8', longitude: ''),
        ValidationMessages.coordinatePair,
      );
      expect(
        Validators.coordinatePair(latitude: null, longitude: '13.1'),
        ValidationMessages.coordinatePair,
      );
    });

    test('accepts both or neither', () {
      expect(Validators.coordinatePair(latitude: '32.8', longitude: '13.1'), isNull);
      expect(Validators.coordinatePair(latitude: '', longitude: ''), isNull);
    });
  });

  group('compose', () {
    test('reports the first complaint only', () {
      final validate = Validators.compose([
        Validators.required,
        Validators.minLength(3, label: 'الاسم'),
      ]);

      expect(validate(''), ValidationMessages.required);
      expect(validate('اب'), 'الاسم يجب ألا يقل عن 3 أحرف');
      expect(validate('طرابلس'), isNull);
    });
  });

  group('optional', () {
    test('lets an empty value through but still checks a filled one', () {
      final validate = Validators.optional(Validators.email);

      expect(validate(''), isNull);
      expect(validate('not-an-email'), ValidationMessages.email);
      expect(validate('a@b.ly'), isNull);
    });
  });
}
