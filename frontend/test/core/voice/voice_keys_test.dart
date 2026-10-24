import 'package:dayaa/core/voice/voice_note_cache.dart';
import 'package:dayaa/core/voice/voice_playback.dart';
import 'package:flutter_test/flutter_test.dart';

/// مفاتيحُ الرسائل الصوتية — للتشغيل وللملف على الهاتف.
///
/// **محادثتان ورقمان من جدولين** (DESIGN-TICKET-CHAT): مرفقُ رقم ٥ في تذكرةٍ داخلية ومرفقُ رقم ٥ في
/// تذكرة تصميم صوتان مختلفان. بلا اسمِ المحادثة في المفتاح كان أحدهما يُسمع مكان الآخر من الملف
/// نفسه. **ومفاتيحُ التذاكر الداخلية كما كانت**، فلا يضيع ما حُفظ على الهواتف قبل هذا.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('an internal ticket voice note keeps the key it always had', () {
    // Act
    final playback = VoicePlayback.keyForAttachment(5);
    final cached = VoicePlayback.cacheKeyFor(playback);

    // Assert
    expect(playback, 'voice-5');
    expect(cached, VoiceNoteCache.keyFor(5));
    expect(cached, 'a5.m4a');
  });

  test('the same number in another conversation is another file', () {
    // Act
    final internal = VoicePlayback.cacheKeyFor(VoicePlayback.keyForAttachment(5));
    final design = VoicePlayback.cacheKeyFor(VoicePlayback.keyForAttachment(5, scope: 'design'));

    // Assert
    expect(design, 'design-a5.m4a');
    expect(design, VoiceNoteCache.keyFor(5, scope: 'design'));
    expect(design, isNot(internal));
  });

  test('a recording that has not reached the server has no file key', () {
    // Act
    final cached = VoicePlayback.cacheKeyFor('unsent-3fa2');

    // Assert
    expect(cached, isNull);
  });
}
