// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/orders_filter.dart';
import 'package:dayaa/features/orders/models/orders_sort.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/filtered_orders_cubit.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/get_orders.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

/// The orders behind one number on the home screen.
///
/// **What is worth proving is that the tap and the number agree.** A card saying «نواقص ١٤» that
/// opens a list of forty is worse than a card that does nothing, and the two ways that happens
/// are asking for the wrong statuses and forgetting the filter on page two.
///
/// Arrange - Act - Assert throughout.
void main() {
  // `any(named: 'sort')` needs something to hand back when nothing was captured, and
  // mocktail cannot invent a value for an enum.
  setUpAll(() => registerFallbackValue(OrdersSort.newest));

  late _MockOrderRepository repository;

  setUp(() => repository = _MockOrderRepository());

  Order orderWith({
    int id = 1,
    OrderStatus status = OrderStatus.shortage,
    DateTime? deletedAt,
  }) {
    return Order(
      id: id,
      code: '$id',
      status: status,
      statusLabel: 'نواقص',
      isFinal: false,
      customerId: 5,
      cityId: 3,
      designSource: 'none',
      cityName: 'طرابلس',
      fulfilmentTypeLabel: 'توصيل',
      isOfficePickup: false,
      designSourceLabel: 'بدون تصميم',
      itemsTotal: '100.00',
      designFee: '0.00',
      deliveryPrice: '20.00',
      discount: '0.00',
      grandTotal: '120.00',
      deletedAt: deletedAt,
    );
  }

  void stub({List<Order> orders = const []}) {
    when(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        sort: any(named: 'sort'),
        customerId: any(named: 'customerId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => Right(
        Paginated<Order>(
          items: orders,
          meta: PageMeta(
            currentPage: 1,
            perPage: 20,
            lastPage: 2,
            total: orders.length,
          ),
        ),
      ),
    );
  }

  FilteredOrdersCubit cubitFor(OrdersFilter filter) =>
      FilteredOrdersCubit(getOrders: GetOrders(repository), filter: filter);

  test('a status card asks for exactly the status it counted', () async {
    // Arrange
    stub(orders: [orderWith()]);
    final cubit = cubitFor(
      const OrdersFilter(title: 'نواقص', statuses: ['shortage']),
    );

    // Act
    await cubit.load();

    // Assert — one status, not the «رواجع»-shaped group a queue chip would have selected.
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: captureAny(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        sort: any(named: 'sort'),
        customerId: any(named: 'customerId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured.last;

    expect(captured, ['shortage']);
  });

  test('a day card asks for that day at both ends', () async {
    // Arrange
    stub(orders: [orderWith()]);
    final cubit = cubitFor(
      const OrdersFilter(title: 'طلبات اليوم', from: '2026-08-06', to: '2026-08-06'),
    );

    // Act
    await cubit.load();

    // Assert — plain days: where a day begins is the server's business, since it is the one
    // that knows the shop's timezone.
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        sort: any(named: 'sort'),
        customerId: any(named: 'customerId'),
        from: captureAny(named: 'from'),
        to: captureAny(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured;

    expect(captured, ['2026-08-06', '2026-08-06']);
  });

  test('page two carries the same filter as page one', () async {
    // Arrange
    stub(orders: [orderWith()]);
    final cubit = cubitFor(
      const OrdersFilter(title: 'نواقص', statuses: ['shortage']),
    );
    await cubit.load();

    // Act
    await cubit.loadMore();

    // Assert — a second page of everything appended to a first page of «نواقص» is a list that
    // stops matching its own title halfway down.
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: captureAny(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        sort: any(named: 'sort'),
        customerId: any(named: 'customerId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured;

    expect(captured.last, ['shortage']);
  });

  test('an order moved out of this answer leaves the screen', () async {
    // Arrange
    stub(orders: [orderWith(id: 1), orderWith(id: 2)]);
    final cubit = cubitFor(
      const OrdersFilter(title: 'نواقص', statuses: ['shortage']),
    );
    await cubit.load();

    // Act — the shortage was resolved while the detail screen was open.
    cubit.replace(orderWith(id: 1, status: OrderStatus.ready));

    // Assert — a row contradicting the title above it is worse than a row that vanished.
    final state = cubit.state as PagedLoaded<Order>;
    expect(state.page.items.map((order) => order.id), [2]);
  });

  test('an order that still belongs is updated in place', () async {
    // Arrange
    stub(orders: [orderWith(id: 1)]);
    final cubit = cubitFor(
      const OrdersFilter(title: 'نواقص', statuses: ['shortage']),
    );
    await cubit.load();

    // Act — it went in and out of «نواقص» and came back to it.
    cubit.replace(orderWith(id: 1));

    // Assert
    final state = cubit.state as PagedLoaded<Order>;
    expect(state.page.items, hasLength(1));
    expect(state.page.items.single.id, 1);
  });

  // ── the customer axis ──────────────────────────────────────────────────────
  // Opened from the customer screen rather than from the home board, and it is the one axis a
  // reader cannot check for themselves: «كل طلبات العميل» over somebody else's orders looks
  // exactly like a correct screen. See CUSTOMER-ORDERS-SECTION.md.

  test('a customer card asks for that customer', () async {
    // Arrange
    stub(orders: [orderWith()]);
    final cubit = cubitFor(
      const OrdersFilter(title: 'كل طلبات العميل', customerId: 7),
    );

    // Act
    await cubit.load();

    // Assert
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        sort: any(named: 'sort'),
        customerId: captureAny(named: 'customerId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured.last;

    expect(captured, 7);
  });

  test('page two stays on the same customer', () async {
    // Arrange
    stub(orders: [orderWith()]);
    final cubit = cubitFor(
      const OrdersFilter(
        title: 'الطلبات الجارية',
        statuses: ['new', 'printing'],
        customerId: 7,
      ),
    );
    await cubit.load();

    // Act
    await cubit.loadMore();

    // Assert — the failure this guards is the quiet one: page two of *everybody's* orders
    // appended under a title naming one person.
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        sort: any(named: 'sort'),
        customerId: captureAny(named: 'customerId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured;

    expect(captured.last, 7);
  });

  test('a screen about nobody in particular sends no customer', () async {
    // Arrange
    stub(orders: [orderWith()]);
    final cubit = cubitFor(const OrdersFilter(title: 'نواقص', statuses: ['shortage']));

    // Act
    await cubit.load();

    // Assert — null rather than a customer id nobody asked for, so the home board's cards keep
    // counting the whole shop.
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        sort: any(named: 'sort'),
        customerId: captureAny(named: 'customerId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured.last;

    expect(captured, isNull);
  });

  // ── الترتيب ────────────────────────────────────────────────────────────────
  // زرٌّ على هذه الشاشة كما هو على تبويب الطلبيات، لأن السؤال الذي فُتحت من أجله لا يجيب عنه:
  // الكرت يقول «كم»، والقارئ بعده يسأل «أيّها ينتظر منذ أطول وقت؟».

  test('«جاهزة للطباعة» تُفتح بالأقدم أولاً', () async {
    // Arrange — الكرت الذي على الرئيسية، بحالته وحدها.
    stub(orders: [orderWith()]);
    final cubit = cubitFor(
      const OrdersFilter(title: 'جاهزة للطباعة', statuses: ['ready_to_print']),
    );

    // Act
    await cubit.load();

    // Assert — طابورُ مطبعةٍ يُقرأ من طرفه البعيد: ما دخله أولاً يُطبع أولاً، وترتيبٌ بالأحدث
    // يدفن أقدم طلبيةٍ خلف صفحاتٍ لا تُفتح.
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        sort: captureAny(named: 'sort'),
        customerId: any(named: 'customerId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured.last;

    expect(captured, OrdersSort.oldest);
  });

  test('بقيّة الكروت تُفتح بالأحدث أولاً', () async {
    // Arrange
    stub(orders: [orderWith()]);
    final cubit = cubitFor(
      const OrdersFilter(title: 'جاهزة', statuses: ['ready']),
    );

    // Act
    await cubit.load();

    // Assert — الاستثناء واحدٌ مسمّى، لا قاعدةٌ جديدة لكل شاشة.
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        sort: captureAny(named: 'sort'),
        customerId: any(named: 'customerId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured.last;

    expect(captured, OrdersSort.newest);
  });

  test('«جاهزة للطباعة» ضمن مجموعةٍ من الحالات لا تقلب الترتيب', () async {
    // Arrange — قسمُ العميل يفتح حالاتٍ عدّة معاً، والسؤال هناك ليس سؤال المطبعة.
    stub(orders: [orderWith()]);
    final cubit = cubitFor(
      const OrdersFilter(
        title: 'الطلبات الجارية',
        statuses: ['ready_to_print', 'printing'],
        customerId: 7,
      ),
    );

    // Act
    await cubit.load();

    // Assert
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        sort: captureAny(named: 'sort'),
        customerId: any(named: 'customerId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured.last;

    expect(captured, OrdersSort.newest);
  });

  test('ضغطة الزر تقلب القائمة وتُبقي السؤال الذي فُتحت به', () async {
    // Arrange
    stub(orders: [orderWith()]);
    final cubit = cubitFor(
      const OrdersFilter(title: 'نواقص', statuses: ['shortage']),
    );
    await cubit.load();

    // Act
    await cubit.showSort(OrdersSort.oldest);

    // Assert — الترتيب تغيّر والحالة لم تتغيّر: الشاشة ما تزال تجيب عن الرقم الذي فُتحت منه.
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: captureAny(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        sort: captureAny(named: 'sort'),
        customerId: any(named: 'customerId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured;

    expect(captured.last, OrdersSort.oldest);
    expect(cubit.sort, OrdersSort.oldest);
    expect(captured[captured.length - 2], ['shortage']);
  });

  test('الصفحة الثانية تحمل الترتيب المختار', () async {
    // Arrange
    stub(orders: [orderWith()]);
    final cubit = cubitFor(
      const OrdersFilter(title: 'جاهزة للطباعة', statuses: ['ready_to_print']),
    );
    await cubit.load();

    // Act
    await cubit.loadMore();

    // Assert — صفحةٌ ثانيةٌ بالأحدث تُلحق تحت صفحةٍ أولى بالأقدم طلبياتٍ رآها القارئ للتوّ.
    final captured = verify(
      () => repository.orders(
        search: any(named: 'search'),
        statuses: any(named: 'statuses'),
        paymentStatuses: any(named: 'paymentStatuses'),
        isUrgent: any(named: 'isUrgent'),
        sort: captureAny(named: 'sort'),
        customerId: any(named: 'customerId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured;

    expect(captured.last, OrdersSort.oldest);
  });

  test('طلبيةٌ حُذفت تسقط من القائمة المفلترة كما تسقط من الطلبيات', () async {
    // Arrange — هذه الشاشة تقرأ الطلبات الحيّة، فالمحذوفة لم تكن يوماً من إجاباتها. لكن الحذف
    // نفسه يقع من هنا: الصفّ يفتح شاشة التفاصيل، وزرّ «حذف الطلبية» عليها، والطلبية المؤرشفة
    // تُسلَّم إلى هذه القائمة مباشرةً بـ`handBack`. فبلا هذا الشرط تبقى تحت عنوانٍ مثل «نواقص»
    // حتى يسحب أحدٌ الشاشة ليحدّثها — وهو بالضبط العطل الذي يوجد `belongs` ليمنعه.
    stub(orders: [orderWith(id: 1), orderWith(id: 2)]);
    final cubit = cubitFor(const OrdersFilter(title: 'نواقص', statuses: ['shortage']));
    await cubit.load();

    // Act
    final moved = cubit.replace(orderWith(id: 1, deletedAt: DateTime(2026, 9, 10)));

    // Assert — بلا طلبٍ واحد: الجواب كان في الصفّ المسلَّم.
    expect(moved, isTrue);
    expect(
      (cubit.state as PagedLoaded<Order>).page.items.map((order) => order.id),
      [2],
    );
  });
}
