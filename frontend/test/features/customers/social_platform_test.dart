import 'package:dayaa/features/customers/models/social_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SocialPlatform.of', () {
    final cases = <String, SocialPlatform>{
      'https://facebook.com/alnoor.print': SocialPlatform.facebook,
      'https://www.facebook.com/alnoor.print': SocialPlatform.facebook,
      'https://m.facebook.com/alnoor.print': SocialPlatform.facebook,
      'https://fb.com/alnoor': SocialPlatform.facebook,
      'https://fb.me/alnoor': SocialPlatform.facebook,
      'https://instagram.com/alnoor.print': SocialPlatform.instagram,
      'https://INSTAGRAM.com/alnoor.print': SocialPlatform.instagram,
      'https://www.tiktok.com/@alnoor': SocialPlatform.tiktok,
      'https://vm.tiktok.com/ZMabc/': SocialPlatform.tiktok,
      'https://wa.me/218912345678': SocialPlatform.whatsapp,
      'https://api.whatsapp.com/send?phone=218912345678': SocialPlatform.whatsapp,
      'https://snapchat.com/add/alnoor': SocialPlatform.snapchat,
      'https://t.me/alnoor': SocialPlatform.telegram,
      'https://x.com/alnoor': SocialPlatform.x,
      'https://twitter.com/alnoor': SocialPlatform.x,
      'https://youtube.com/@alnoor': SocialPlatform.youtube,
      'https://youtu.be/abc': SocialPlatform.youtube,
      'https://alnoor.ly': SocialPlatform.other,
    };

    for (final MapEntry(key: url, value: expected) in cases.entries) {
      test('$url → ${expected.name}', () {
        // Arrange — the table above.

        // Act
        final platform = SocialPlatform.of(url);

        // Assert
        expect(platform, expected);
      });
    }

    test('a link typed without https is still recognised', () {
      // Arrange
      const typed = 'instagram.com/alnoor.print';

      // Act
      final platform = SocialPlatform.of(typed);

      // Assert
      expect(platform, SocialPlatform.instagram);
    });

    test('a domain that only ends in a platform name is not that platform', () {
      // Arrange — «notfacebook.com» is somebody else's site.
      const lookalike = 'https://notfacebook.com/alnoor';

      // Act
      final platform = SocialPlatform.of(lookalike);

      // Assert
      expect(platform, SocialPlatform.other);
    });

    test('an empty box and plain words are a generic link', () {
      // Arrange
      const inputs = ['', '   ', 'صفحة النور'];

      // Act
      final platforms = inputs.map(SocialPlatform.of).toList();

      // Assert
      expect(platforms, everyElement(SocialPlatform.other));
    });
  });

  group('labels', () {
    test('every platform is named in Arabic, and an unknown one is «رابط»', () {
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

    test('every known platform has its logo, and «رابط» draws the generic icon', () {
      // Arrange
      final known = SocialPlatform.values.where((p) => p != SocialPlatform.other);

      // Act
      final assets = {for (final platform in known) platform: platform.asset};

      // Assert
      expect(assets.values, everyElement(startsWith('assets/icons/social/')));
      expect(SocialPlatform.other.asset, isNull);
    });
  });

  group('normalizeSocialLink', () {
    test('adds https to a link typed without a scheme', () {
      // Arrange
      const typed = '  facebook.com/alnoor.print ';

      // Act
      final normalized = normalizeSocialLink(typed);

      // Assert
      expect(normalized, 'https://facebook.com/alnoor.print');
    });

    test('leaves a link that already has one alone', () {
      // Arrange
      const typed = 'http://alnoor.ly';

      // Act
      final normalized = normalizeSocialLink(typed);

      // Assert
      expect(normalized, 'http://alnoor.ly');
    });

    test('an empty box stays empty', () {
      // Arrange
      const typed = '   ';

      // Act
      final normalized = normalizeSocialLink(typed);

      // Assert
      expect(normalized, isEmpty);
    });
  });

  group('displaySocialLink', () {
    test('drops the scheme, www and a trailing slash', () {
      // Arrange
      const url = 'https://www.facebook.com/alnoor.print/';

      // Act
      final shown = displaySocialLink(url);

      // Assert
      expect(shown, 'facebook.com/alnoor.print');
    });
  });
}
