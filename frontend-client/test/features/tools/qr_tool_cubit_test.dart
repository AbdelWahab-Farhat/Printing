import 'package:bloc_test/bloc_test.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/tools/presentation/viewmodel/qr_tool_cubit.dart';
import 'package:dayaa_client/features/tools/usecases/generate_qr_code.dart';
import 'package:flutter_test/flutter_test.dart';

/// **لا تزييف هنا، خلافاً لبقية اختبارات الـ Cubit.**
///
/// التزييف في هذا المستودع يشتري شيئاً واحداً: ألّا يلمس الاختبارُ Dio ولا الشبكة. و
/// [GenerateQrCode] لا شبكة تحتها ولا مستودع — حسابٌ متزامن على الجهاز — فتزييفها كان سيستبدل
/// المرمِّز الحقيقي بمرمِّزٍ يقول «نعم»، ويترك السؤالَ الوحيد الذي يستحق أن يُسأل هنا — ماذا
/// يحدث حين لا يسع المحتوى رمزاً — بلا جواب.
///
/// Arrange - Act - Assert throughout.
void main() {
  late QrToolCubit cubit;

  setUp(() {
    cubit = QrToolCubit(generate: const GenerateQrCode());
  });

  tearDown(() async {
    await cubit.close();
  });

  test('يفتح فارغاً — لا رمز قبل أن يُطلب', () {
    // Assert
    expect(cubit.state, const QrToolState.blank());
  });

  group('generate', () {
    blocTest<QrToolCubit, QrToolState>(
      'يعرض رمزاً يحمل ما أُدخل حرفياً',
      build: () => cubit,
      act: (cubit) => cubit.generate('https://daaya.ly'),
      expect: () => [
        isA<QrReady>().having((s) => s.art.data, 'data', 'https://daaya.ly'),
      ],
    );

    blocTest<QrToolCubit, QrToolState>(
      'يقلّم الفراغ حول المحتوى',
      build: () => cubit,
      act: (cubit) => cubit.generate('  0910000000  '),
      // مسافةٌ لاصقة في آخر رابط تُرمَّز معه ويحملها الماسح — وهي أثر لصقٍ لا محتوى قصده أحد.
      expect: () => [
        isA<QrReady>().having((s) => s.art.data, 'data', '0910000000'),
      ],
    );

    blocTest<QrToolCubit, QrToolState>(
      'لا يبعث شيئاً على حقل فارغ — الرسالة مكانها تحت الحقل',
      build: () => cubit,
      act: (cubit) => cubit
        ..generate('')
        ..generate('     '),
      expect: () => <QrToolState>[],
    );

    blocTest<QrToolCubit, QrToolState>(
      'يقول إن المحتوى أطول من أن يسعه رمز، لا «حدث خطأ ما»',
      build: () => cubit,
      act: (cubit) => cubit.generate('x' * 3000),
      expect: () => [
        isA<QrToolFailure>().having(
          (s) => s.failure.message,
          'message',
          'المحتوى أطول مما يسعه رمز QR واحد، اختصره وحاول مجدداً',
        ),
      ],
    );

    blocTest<QrToolCubit, QrToolState>(
      'يحمل سبب الفشل التقني بجانب الرسالة',
      build: () => cubit,
      act: (cubit) => cubit.generate('x' * 3000),
      // الجملة للموظف، و`cause` لمن يقرأ البلاغ عن هاتفه بعد أسبوع.
      expect: () => [
        isA<QrToolFailure>().having(
          (s) => (s.failure as UnexpectedFailure).cause,
          'cause',
          isNotNull,
        ),
      ],
    );

    blocTest<QrToolCubit, QrToolState>(
      'محتوى جديد يستبدل الرمز المعروض',
      build: () => cubit,
      act: (cubit) => cubit
        ..generate('https://daaya.ly')
        ..generate('0910000000'),
      expect: () => [
        isA<QrReady>().having((s) => s.art.data, 'data', 'https://daaya.ly'),
        isA<QrReady>().having((s) => s.art.data, 'data', '0910000000'),
      ],
    );

    blocTest<QrToolCubit, QrToolState>(
      'فشلٌ بعد نجاح يمسح المعاينة بدل أن يترك الرمز القديم تحت رسالة عن رمز جديد',
      build: () => cubit,
      act: (cubit) => cubit
        ..generate('https://daaya.ly')
        ..generate('x' * 3000),
      expect: () => [isA<QrReady>(), isA<QrToolFailure>()],
    );
  });
}
