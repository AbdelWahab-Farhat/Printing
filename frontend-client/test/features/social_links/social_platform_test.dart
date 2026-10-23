import 'package:dayaa_client/features/social_links/models/social_platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// المنصّة تُعرف من نطاق الرابط، والتطبيقان يعرفانها بالجدول نفسه — انظر
/// Docs/customers/CUSTOMER-SOCIAL-LINKS.md §٥.
///
/// Arrange - Act - Assert throughout.
void main() {
  group('SocialPlatform.of', () {
    for (final (url, platform) in [
      ('https://facebook.com/alnoor.print', SocialPlatform.facebook),
      ('https://www.facebook.com/alnoor.print', SocialPlatform.facebook),
      ('https://m.facebook.com/alnoor.print', SocialPlatform.facebook),
      ('https://fb.com/alnoor', SocialPlatform.facebook),
      ('https://fb.me/alnoor', SocialPlatform.facebook),
      ('https://fb.watch/xyz', SocialPlatform.facebook),
      ('https://instagram.com/alnoor.print', SocialPlatform.instagram),
      ('https://instagr.am/alnoor', SocialPlatform.instagram),
      ('https://www.tiktok.com/@alnoor', SocialPlatform.tiktok),
      ('https://vm.tiktok.com/ZM123', SocialPlatform.tiktok),
      ('https://wa.me/218912345678', SocialPlatform.whatsapp),
      ('https://api.whatsapp.com/send?phone=218912345678', SocialPlatform.whatsapp),
      ('https://snapchat.com/add/alnoor', SocialPlatform.snapchat),
      ('https://t.me/alnoor', SocialPlatform.telegram),
      ('https://telegram.me/alnoor', SocialPlatform.telegram),
      ('https://x.com/alnoor', SocialPlatform.x),
      ('https://twitter.com/alnoor', SocialPlatform.x),
      ('https://youtube.com/@alnoor', SocialPlatform.youtube),
      ('https://youtu.be/abc', SocialPlatform.youtube),
      ('https://alnoor.ly', SocialPlatform.other),
    ]) {
      test('$url → ${platform.name}', () {
        // Arrange — the table above.

        // Act
        final detected = SocialPlatform.of(url);

        // Assert
        expect(detected, platform);
      });
    }

    test('a link typed without its scheme is still recognised', () {
      // Arrange
      const typed = 'instagram.com/alnoor.print';

      // Act
      final detected = SocialPlatform.of(typed);

      // Assert
      expect(detected, SocialPlatform.instagram);
    });

    test('the domain is matched whole: notfacebook.com is not Facebook', () {
      // Arrange
      const lookalike = 'https://notfacebook.com/alnoor';

      // Act
      final detected = SocialPlatform.of(lookalike);

      // Assert
      expect(detected, SocialPlatform.other);
    });

    test('capitals do not hide a platform', () {
      // Arrange
      const shouted = 'HTTPS://WWW.FACEBOOK.COM/Alnoor';

      // Act
      final detected = SocialPlatform.of(shouted);

      // Assert
      expect(detected, SocialPlatform.facebook);
    });

    for (final input in ['', '   ', 'صفحة النور', 'alnoor print']) {
      test('«$input» is a plain link, not a platform', () {
        // Arrange — the input above.

        // Act
        final detected = SocialPlatform.of(input);

        // Assert
        expect(detected, SocialPlatform.other);
      });
    }
  });

  group('labels', () {
    test('every platform is named in Arabic, and the unknown one is «رابط»', () {
      // Arrange
      const expected = {
        SocialPlatform.facebook: 'فيسبوك',
        SocialPlatform.instagram: 'إنستغرام',
        SocialPlatform.tiktok: 'تيك توك',
        SocialPlatform.whatsapp: 'واتساب',
        SocialPlatform.snapchat: 'سناب شات',
        SocialPlatform.telegram: 'تيليجرام',
        SocialPlatform.x: 'X',
        SocialPlatform.youtube: 'يوتيوب',
        SocialPlatform.other: 'رابط',
      };

      // Act
      final labels = {for (final platform in SocialPlatform.values) platform: platform.label};

      // Assert
      expect(labels, expected);
    });
  });

  group('marks', () {
    test('every known platform has its own SVG bundled with the app; «رابط» has none', () async {
      // Arrange — ملفٌّ غير مُعلَنٍ في pubspec لا يُحزَم، والشعار يختفي بلا خطأٍ على الشاشة.
      TestWidgetsFlutterBinding.ensureInitialized();
      final known = SocialPlatform.values.where((platform) => platform != SocialPlatform.other);

      // Act
      final sources = [for (final platform in known) await rootBundle.loadString(platform.asset!)];

      // Assert
      expect(sources, everyElement(contains('<svg')));
      expect(SocialPlatform.other.asset, isNull);
    });

    test('brand colours are the platforms’ own; black marks take the ink of the theme', () {
      // Arrange
      const dark = Brightness.dark;
      const light = Brightness.light;

      // Act & Assert — the platforms' colours, not ours to theme.
      expect(SocialPlatform.facebook.brandColor(light), const Color(0xFF0866FF));
      expect(SocialPlatform.instagram.brandColor(dark), const Color(0xFFE4405F));
      expect(SocialPlatform.whatsapp.brandColor(light), const Color(0xFF25D366));
      expect(SocialPlatform.telegram.brandColor(light), const Color(0xFF26A5E4));
      expect(SocialPlatform.youtube.brandColor(dark), const Color(0xFFFF0000));
      // أسودان لا يُريان على الداكن، فيأخذان حبر الثيم في الوضعين.
      expect(SocialPlatform.tiktok.brandColor(dark), isNull);
      expect(SocialPlatform.x.brandColor(light), isNull);
      // أصفر سناب شات لا يُقرأ على الفاتح.
      expect(SocialPlatform.snapchat.brandColor(dark), const Color(0xFFFFFC00));
      expect(SocialPlatform.snapchat.brandColor(light), isNull);
    });
  });

  group('normalizeSocialLink', () {
    for (final (raw, normalized) in [
      ('instagram.com/alnoor', 'https://instagram.com/alnoor'),
      ('  https://facebook.com/alnoor  ', 'https://facebook.com/alnoor'),
      ('http://alnoor.ly', 'http://alnoor.ly'),
      ('HTTPS://x.com/alnoor', 'HTTPS://x.com/alnoor'),
      ('', ''),
      ('   ', ''),
    ]) {
      test('«$raw» → «$normalized»', () {
        // Arrange — the pair above.

        // Act
        final result = normalizeSocialLink(raw);

        // Assert
        expect(result, normalized);
      });
    }
  });

  group('displaySocialLink', () {
    for (final (url, shown) in [
      ('https://facebook.com/alnoor.print', 'facebook.com/alnoor.print'),
      ('https://www.instagram.com/alnoor.print/', 'instagram.com/alnoor.print'),
      ('http://alnoor.ly', 'alnoor.ly'),
      ('https://wa.me/218912345678', 'wa.me/218912345678'),
    ]) {
      test('«$url» reads «$shown»', () {
        // Arrange — the pair above.

        // Act
        final result = displaySocialLink(url);

        // Assert
        expect(result, shown);
      });
    }
  });
}
