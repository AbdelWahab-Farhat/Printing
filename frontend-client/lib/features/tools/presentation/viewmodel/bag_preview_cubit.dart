import 'dart:ui' as ui;

import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/features/tools/models/bag_type.dart';
import 'package:dayaa_client/features/tools/usecases/load_bag_mockup.dart';
import 'package:dayaa_client/features/tools/usecases/load_design_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bag_preview_cubit.freezed.dart';
part 'bag_preview_state.dart';

/// الكيس المختار والتصميم المفكوك ترميزه — ولا شيء غيرهما.
///
/// **وضعُ التصميم (الإزاحة والتكبير) ليس هنا، وهذا مقصود.** السحب بالإصبع يغيّره عشرات المرات
/// في الثانية، و`emit` لكل إطار يجعل كل مشترك في التيار يُعاد بناؤه بينما الإصبع على الشاشة —
/// وهو أضمن طريق إلى معاينةٍ تتلعثم. الوضع حالةٌ بصرية بحتة داخل الشاشة (§4)، وقاعدتُه —
/// وهي الشيء الوحيد الذي يستحق اختباراً — تعيش في [DesignPlacement] خالصةً بلا ويدجت.
///
/// **وتبديل الكيس لا يمسّ التصميم.** الموظف يجرّب نفس الشعار على ثلاثة مقاسات؛ إعادةُ رفعه في
/// كل مرة هو العمل الذي جاءت الأداة لتوفّره. الوضع يُقيَّد من جديد على منطقة الطباعة الجديدة،
/// والشاشة هي من تفعل ذلك عند أول رسم.
class BagPreviewCubit extends Cubit<BagPreviewState> {
  BagPreviewCubit({required LoadDesignImage loadImage, required LoadBagMockup loadMockup})
    : _loadImage = loadImage,
      _loadMockup = loadMockup,
      super(const BagPreviewState.empty(bag: BagType.initial));

  final LoadDesignImage _loadImage;
  final LoadBagMockup _loadMockup;

  /// يجلب صورة الكيس الحالي. تُنادى مرة عند فتح الشاشة.
  Future<void> load() => selectBag(state.bag);

  /// يبدّل الكيس ويجلب صورته.
  ///
  /// الحالة تتبدّل **قبل** أن تصل الصورة، فيتغيّر الاسم في القائمة فوراً ويصل الكيس بعده بلحظة
  /// — وهو أصدق من قائمةٍ تتجمّد حتى يُفكّ ترميز صورة.
  Future<void> selectBag(BagType bag) async {
    emit(state.withBag(bag));

    final result = await _loadMockup(bag);

    if (isClosed) return;

    // **يُتجاهل ردٌّ عن كيسٍ لم يعد مختاراً.** الموظف يمرّ على الأنواع الخمسة بسرعة، وردٌّ
    // بطيء عن «أكياس ورقية» يجب ألّا يرسم الورقي فوق ما اختاره بعده.
    if (state.bag != bag) return;

    emit(
      result.fold(
        (failure) => state.withMockup(null),
        (image) => state.withMockup(image),
      ),
    );
  }

  /// يقرأ الملف المرفوع ويستبدل به التصميم المعروض.
  Future<void> loadDesign(PickedFile file) async {
    final previous = state.design;

    emit(BagPreviewState.loading(bag: state.bag, mockup: state.mockup));

    final result = await _loadImage(file);

    if (isClosed) {
      // الشاشة أُغلقت والقراءة في الطريق. الصورة تحمل ذاكرةً خارج كومة دارت لا يحرّرها جامع
      // القمامة، فلو تُركت هنا لتسرّبت بصمت — ولا أحد سيراها بعد الآن.
      result.forEach((image) => image.dispose());

      return;
    }

    // **يُتخلَّص من القديمة بعد نجاح الجديدة لا قبله**: لو فشل فكّ الترميز لبقي المعروض كما هو،
    // وقد رسمته الشاشة بالفعل — التخلّص منه مبكراً يعني الرسم بصورةٍ مُتلَفة.
    result.forEach((_) => previous?.dispose());

    emit(
      result.fold(
        (failure) =>
            BagPreviewState.failure(bag: state.bag, mockup: state.mockup, failure: failure),
        (image) => BagPreviewState.ready(bag: state.bag, mockup: state.mockup, design: image),
      ),
    );
  }

  @override
  Future<void> close() {
    // التصميم وحده. صورة الكيس مشتركة ومحفوظة في [LoadBagMockup] لعمر العملية، والتخلّص منها
    // هنا يترك الشاشة التالية ترسم بصورةٍ مُتلَفة.
    state.design?.dispose();

    return super.close();
  }
}
