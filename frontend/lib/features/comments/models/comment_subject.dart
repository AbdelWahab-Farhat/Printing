import 'package:flutter/foundation.dart';

/// عمّاذا الملاحظة — أيُّ سجلّ، وأيُّ نوعٍ من السجلات هو.
///
/// **الشيء الوحيد الذي يحتاجه كلّ نداءٍ في هذه الميزة، والوحيد الذي يختلف بين ملاحظات العميل
/// وملاحظات المورّد.** الواجهة تُعشّش الملاحظات تحت مالكها (`/customers/7/comments`,
/// `/vendors/4/comments`)، فالمستودعُ المُعطى معرّفاً مجرّداً لا سبيل له لمعرفة أيَّ بابٍ يطرق؛
/// والمُعطى هذا يملك باباً واحداً بالضبط.
///
/// و[kind] هو الاسم القصير نفسه الذي يكتبه الخادم في `commentable_type`، وهو ما يتيح مطابقة
/// ملاحظةٍ مقروءةٍ من الشبكة بالشاشة التي تعرضها.
@immutable
class CommentSubject {
  const CommentSubject.customer(this.id) : kind = CommentSubjectKind.customer;

  const CommentSubject.vendor(this.id) : kind = CommentSubjectKind.vendor;

  const CommentSubject.designTicket(this.id) : kind = CommentSubjectKind.designTicket;

  final CommentSubjectKind kind;
  final int id;

  @override
  bool operator ==(Object other) =>
      other is CommentSubject && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

/// السجلات التي تقبل ملاحظاتٍ اليوم.
///
/// ثلاثة: العميل، والمورّد، وتذكرة التصميم. والطلبية أو أمر الشراء حالةٌ هنا ومسارٌ على الخادم —
/// ولا يُضاف أيٌّ منهما قبل أن تطلبه شاشة، وهي القاعدة نفسها التي أبقت هذه الميزة على العميل
/// وحده حتى احتاجها المورّد. انظر GENERAL-COMMENTS.md.
enum CommentSubjectKind {
  customer('customer'),
  vendor('vendor'),

  /// **الوحيد الذي ملاحظاتُه هي مقصود السجلّ لا هامشه.** ملاحظات العميل أشياءُ تستحقّ أن تُتذكّر
  /// عنه؛ وملاحظات التذكرة هي المحادثة التي وُجدت التذكرة لتحملها — «الشعار في المرفقات»، «وصلني،
  /// أبدأ اليوم». النداءات الأربعة نفسها، والقواعد نفسها.
  designTicket('design_ticket');

  const CommentSubjectKind(this.wire);

  /// الـ`commentable_type` الذي يعيده الخادم — الاسم القصير للتحوّل، لا مسارَ صنفٍ أبداً.
  final String wire;
}
