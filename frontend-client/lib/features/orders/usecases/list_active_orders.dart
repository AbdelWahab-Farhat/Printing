import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';

/// الطلبيات التي لم تصل صاحبها بعد، وهي ما تعرضه الرئيسية تحت «طلبياتي الجارية».
///
/// **سؤالان للخادم لا سؤال، والسبب قرارٌ في الخادم لا يُعاد هنا.** `open=1` يستثني «جاهزة»
/// عمداً: في «طلباتي» تجلس شريحتها بجانب «قيد التنفيذ»، وشريحةٌ تحوي جارتها تُجيب السؤال نفسه
/// مرتين. أما الرئيسية فتسأل سؤالاً آخر هو «ما الذي لم يصلني بعد؟»، والطلبية الجاهزة أول جوابٍ
/// عنه. فيُسأل الخادم بلغته مرتين، `open=1` و`stage=ready`، ويُجمع الجوابان هنا.
///
/// **الصفحة الأولى من كلٍّ منهما تكفي.** بطاقات الرئيسية تحت بعضها، ومن تتحرك له أكثر من خمس
/// عشرة طلبيةً في وقتٍ واحد يجدها كلها في «طلباتي».
class ListActiveOrders {
  const ListActiveOrders(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, List<CustomerOrder>>> call() async {
    final (moving, ready) = await (
      _repository.list(page: 1, openOnly: true),
      _repository.list(page: 1, stage: OrdersFilter.ready.stageParameter),
    ).wait;

    return moving.fold(
      (failure) => Left(failure),
      (movingPage) => ready.fold(
        (failure) => Left(failure),
        (readyPage) => Right(_merge(movingPage.items, readyPage.items)),
      ),
    );
  }

  /// «نواقص» و«مرفوضة» أولاً، لتُرى، ثم «استلام مكتب»، فلا يمرّر العميل ليجد ما ينتظره (طلب
  /// المستخدم، 2026-10-23) — ثم الأحدث أولاً، كما في «طلباتي»، وكذلك داخل كل فريق. الخادم يرتّب
  /// `open=1` كذلك، فتصل الصفحة الأولى بها.
  ///
  /// وطلبيةٌ في الجوابين (صارت جاهزةً بين السؤالين) تُرسم مرةً واحدة بمرحلتها الأبعد، أي كما
  /// جاءت في جواب «جاهزة»: الطلبية لا ترجع من الجاهزية إلى الإنتاج.
  static List<CustomerOrder> _merge(List<CustomerOrder> moving, List<CustomerOrder> ready) {
    final byId = <int, CustomerOrder>{
      for (final order in moving) order.id: order,
      for (final order in ready) order.id: order,
    };

    return byId.values.toList()..sort(_attentionThenNewest);
  }

  static int _attentionThenNewest(CustomerOrder a, CustomerOrder b) {
    final byRank = _rank(a).compareTo(_rank(b));

    return byRank != 0 ? byRank : _newestFirst(a, b);
  }

  static int _rank(CustomerOrder order) => switch (order.stage) {
    final stage when stage.needsAttention => 0,
    OrderStage.officePickup => 1,
    _ => 2,
  };

  /// طلبيةٌ بلا تاريخ بعد المؤرَّخة لا قبلها: مكانها بين الأحدث والأقدم غير معروف.
  static int _newestFirst(CustomerOrder a, CustomerOrder b) {
    final (first, second) = (a.placedAt, b.placedAt);

    if (first == null && second == null) return 0;
    if (first == null) return 1;
    if (second == null) return -1;

    return second.compareTo(first);
  }
}
