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
/// اثنان: العميل، والمورّد. والطلبية أو أمر الشراء حالةٌ هنا ومسارٌ على الخادم — ولا يُضاف أيٌّ
/// منهما قبل أن تطلبه شاشة، وهي القاعدة نفسها التي أبقت هذه الميزة على العميل وحده حتى احتاجها
/// المورّد. انظر GENERAL-COMMENTS.md.
///
/// **وكانت تذكرةُ التصميم ثالثهما**، حتى صارت محادثتُها على محرّك التذاكر الداخلية بصورٍ وصوت
/// (DESIGN-TICKET-CHAT). ملاحظاتُها القديمة على الخادم للنسخة القديمة من التطبيق وحدها.
enum CommentSubjectKind {
  customer('customer'),
  vendor('vendor');

  const CommentSubjectKind(this.wire);

  /// الـ`commentable_type` الذي يعيده الخادم — الاسم القصير للتحوّل، لا مسارَ صنفٍ أبداً.
  final String wire;
}
