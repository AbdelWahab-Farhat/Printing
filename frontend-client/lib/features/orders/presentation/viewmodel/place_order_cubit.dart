import 'dart:async';

import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/utils/uuid.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/delivery/models/city.dart';
import 'package:dayaa_client/features/delivery/usecases/list_cities.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/usecases/list_designs.dart';
import 'package:dayaa_client/features/orders/models/basket_quote.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/deposit_rules.dart' as rules;
import 'package:dayaa_client/features/orders/models/order_draft.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/cart_cubit.dart';
import 'package:dayaa_client/features/orders/usecases/place_order.dart';
import 'package:dayaa_client/features/orders/usecases/quote_basket.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/usecases/list_shops.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
import 'package:dayaa_client/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'place_order_cubit.freezed.dart';
part 'place_order_state.dart';

/// الـ ViewModel للسلة: معالجٌ من خطوتين، «المنتجات» ثم «بيانات الطلب».
///
/// **يملك الاختيارات لا الكتابة.** الخطوة والمتجر والمدينة والمنطقة والتصاميم والسطور هنا؛ أما هاتف
/// الاستلام والملاحظة فيبقيان في متحكّمات الشاشة ويصلان عند [submit]. Cubit يبعث مع كل حرفٍ يعيد بناء
/// النموذج كله ليرسم حقلاً واحداً.
///
/// **الخطوة الثانية تُملأ من الحساب:** أول متاجر العميل مختارٌ عند الفتح ومدينته ومنطقته معه، ورقمه
/// في [PlaceOrderReady.customerPhone]. **ولا اسمَ مستلمٍ ولا عنوانَ حرّاً** — المستلم هو العميل نفسه،
/// والخادم لا يقبلهما من هذا التطبيق أصلاً. **ولا إضافةَ متجرٍ من هنا:** المتاجر تُدار من «حسابي»،
/// والسلة تختار مما هناك.
///
/// **والتكلفة النهائية من الخادم لا من هنا.** كلما تغيّرت السطور أو المدينة سُئل الخادم عن سعر السلة
/// — بالطريق الذي يسعّر به الطلبية حين تُرسل — وهذا الـ Cubit لا يضرب سعراً في كمية ولا يجمع مبلغين.
///
/// **والخطوة الثالثة «العربون»** (صاحب العمل، 2026-10-19) حين يعرضها التسعير: ربعُ البضاعة على
/// الأقل، في المكتب أو من المحفظة أو إلكترونياً. الحدّان من الخادم، والخادم يفحصهما ثانيةً.
class PlaceOrderCubit extends Cubit<PlaceOrderState> {
  PlaceOrderCubit({
    required ListCities cities,
    required ListDesigns designs,
    required ListShops shops,
    required GetCurrentCustomer customer,
    required QuoteBasket quote,
    required PlaceOrder place,
    required CartCubit cart,
    GetWalletBalance? walletBalance,
    GetTopUpMethods? topUpMethods,
  }) : _cities = cities,
       _designs = designs,
       _shops = shops,
       _customer = customer,
       _quote = quote,
       _place = place,
       _cart = cart,
       _walletBalance = walletBalance,
       _topUpMethods = topUpMethods,
       super(const PlaceOrderState.loading()) {
    // **السلة تتغيّر من خارج هذه الشاشة أيضاً**: العميل يلمس سطراً، فتُفتح صفحة منتجه، فيغيّر الكمية
    // ويعود. لقطةٌ أُخذت عند الفتح كانت ستعرض الكمية القديمة وتسعّرها.
    _cartChanges = _cart.stream.listen((cart) => _linesChanged(cart.lines));
  }

  final ListCities _cities;
  final ListDesigns _designs;
  final ListShops _shops;
  final GetCurrentCustomer _customer;
  final QuoteBasket _quote;
  final PlaceOrder _place;

  /// خيارا «من المحفظة» و«دفع إلكتروني» في خطوة العربون. **بدونهما لا يُعرضان**، ويبقى المكتب.
  final GetWalletBalance? _walletBalance;
  final GetTopUpMethods? _topUpMethods;

  /// مفتاح دفعة المحفظة حتى تنجح: إرسالٌ انقطع بعد أن دفع الخادم يُعاد بالمفتاح نفسه فلا يدفع ثانية.
  String? _depositToken;

  /// مفتاح الطلبية نفسها حتى تصل، بالقاعدة نفسها: **ردٌّ ضاع بعد أن كتبها الخادم** يترك السلة ممتلئة،
  /// فيضغط العميل «إرسال» ثانية — والمفتاح نفسه يُرجع الطلبية الأولى لا ثانيةً على طابور المراجعة.
  /// ولا يتغيّر بتعديل السلة بعد انقطاع: إن كانت الأولى وصلت فهي طلبيته، وإن لم تصل كُتبت المعدّلة.
  String? _orderToken;

  late final StreamSubscription<CartState> _cartChanges;

  /// رقم آخر تسعيرٍ طُلب. جوابٌ لسلةٍ أقدم يصل بعد جوابٍ أحدث لا يُكتب فوقه — تبديل المدينة
  /// مرتين بسرعة كان سيترك توصيل الأولى على شاشة الثانية.
  int _pricingRequest = 0;

  /// **السلة هي الحقيقة عمّا في الطلبية، وهذا الـ Cubit لا يحتفظ بنسخة منها.** سطرٌ يُحذف هنا ويبقى
  /// في السلة كان سيعود أولَ مرةٍ تُفتح فيها الشاشة ثانية.
  final CartCubit _cart;

  List<OrderDraftLine> get _lines => _cart.state.lines;

  Future<void> load() async {
    emit(const PlaceOrderState.loading());

    // تبدأ الأربعة معاً: الخطوتان شاشةٌ واحدة.
    final citiesResult = _cities();
    final designsResult = _designs();
    final shopsResult = _shops();
    final customerResult = _customer();
    final onlineResult = _onlineMethods();

    final cities = await citiesResult;
    final shops = await shopsResult;

    // **المكتبة والحساب لا يوقفان طلبية.** إرفاق التصميم اختياري، والهاتف يكتبه العميل إن لم يصل
    // رقمه — ورفضُ طلبيةٍ لأن قائمةً تأخّرت هو التطبيق يخترع قاعدة.
    final library = (await designsResult).fold(
      (_) => const <CustomerDesign>[],
      (list) => list,
    );
    final account = (await customerResult).fold((_) => null, (CustomerAccount me) => me);
    final onlineMethods = await onlineResult;

    if (isClosed) return;

    final failure = cities.fold((f) => f, (_) => null) ?? shops.fold((f) => f, (_) => null);

    if (failure != null) {
      emit(PlaceOrderState.failure(failure));

      return;
    }

    final ready = PlaceOrderReady(
      cities: cities.getOrElse(() => const []),
      designs: library,
      shops: shops.getOrElse(() => const []),
      lines: List<OrderDraftLine>.unmodifiable(_lines),
      customerPhone: account?.phone,
      onlineMethods: onlineMethods,
    );

    // أول المتاجر مختارٌ سلفاً، فيصل العميل إلى خطوة البيانات وهي ممتلئة. وبلا متجر، فعنوانُ الحساب
    // إن سجّله الموظفون — وإلا فالوجهة فارغةٌ يختارها العميل بيده كما كانت.
    final first = ready.shops.firstOrNull;
    final addressCityId = account?.cityId;

    emit(switch (first) {
      final shop? => _withShop(ready, shop),
      null when addressCityId != null => _placed(ready, addressCityId, account?.regionId),
      null => ready,
    });

    await _price();
  }

  /// «إتمام الطلب». سلةٌ فارغة لا خطوة بعدها.
  void proceed() {
    final ready = _ready;
    if (ready == null || !ready.canProceed || ready.step != CheckoutStep.products) return;

    emit(ready.copyWith(step: CheckoutStep.details, lastFailure: null));
  }

  /// «التالي» من «بيانات الطلب» إلى «العربون» — حين يعرضه التسعير. يبدأ المبلغ بأقلّه، ويُقرأ رصيد
  /// المحفظة من جديد: ربما شُحنت منذ فُتحت السلة.
  void toDeposit() {
    final ready = _ready;
    final offer = ready?.depositOffer;
    if (ready == null || offer == null || ready.step != CheckoutStep.details || !ready.canSubmit) {
      return;
    }

    emit(
      ready.copyWith(
        step: CheckoutStep.deposit,
        // بالدينار الكامل: «125.00» من الخادم يُكتب «125».
        depositAmount: ready.depositAmount ?? offer.minAmount!.asPlainNumber,
        lastFailure: null,
      ),
    );

    unawaited(_readWallet());
  }

  /// «السابق» — خطوةً إلى الوراء، وكلُّ ما اختير باقٍ.
  void back() {
    final ready = _ready;
    if (ready == null || ready.step == CheckoutStep.products || ready.isSubmitting) return;

    emit(
      ready.copyWith(
        step: ready.step == CheckoutStep.deposit ? CheckoutStep.details : CheckoutStep.products,
        lastFailure: null,
      ),
    );
  }

  /// يختار كيف يُدفع العربون: في المكتب أو من المحفظة. الإلكتروني بطريقته — [chooseOnline].
  void choosePayment(CheckoutPayment payment) {
    final ready = _ready;
    if (ready == null || ready.payment == payment) return;

    emit(ready.copyWith(payment: payment, onlineMethodId: null, lastFailure: null));
  }

  /// يختار طريقة شحنٍ إلكترونية — صفّها في «أو عبّئ محفظتك وادفع مباشرة».
  void chooseOnline(int methodId) {
    final ready = _ready;
    if (ready == null) return;

    emit(
      ready.copyWith(
        payment: CheckoutPayment.online,
        onlineMethodId: methodId,
        lastFailure: null,
      ),
    );
  }

  /// يختار مبلغ العربون مكتوباً بأرقامٍ عربية أو غربية — **بالدينار الكامل**.
  void chooseDepositAmount(String amount) {
    final ready = _ready;
    if (ready == null) return;

    final normalized = topUpAmount(amount);

    // مبلغٌ آخر دفعةٌ أخرى، لا إعادةٌ للأولى.
    if (normalized != ready.depositAmount) _depositToken = null;

    emit(ready.copyWith(depositAmount: normalized, lastFailure: null));
  }

  /// «ادفع كامل القيمة»: العربون أعلى ما يقبله الخادم — البضاعة كلّها بالدينار الكامل.
  void payFull() {
    final max = _ready?.depositOffer?.maxAmount;
    if (max != null) chooseDepositAmount(max.asPlainNumber);
  }

  /// **الشحن الإلكتروني تمّ** — والآن فقط تُرسل الطلبية (صاحب العمل، 2026-10-19). العربون صار في
  /// المحفظة، فيُدفع منها: يُقرأ الرصيد من جديد ويصير الطريقُ المحفظة. فإن رُفض الإرسال بعدها بقي المال
  /// في المحفظة واختيارُها جاهزٌ لإعادة المحاولة — لا شحنٌ ثانٍ.
  Future<void> toppedUp() async {
    await _readWallet();

    if (_ready case final now?) {
      emit(now.copyWith(payment: CheckoutPayment.wallet, onlineMethodId: null));
    }
  }

  /// زرّ التحديث بجانب الرصيد في صفّ المحفظة.
  Future<void> refreshWallet() => _readWallet();

  Future<void> _readWallet() async {
    final read = _walletBalance;
    if (read == null) return;

    final result = await read();

    if (isClosed) return;

    result.fold((_) {}, (balance) {
      if (_ready case final now?) emit(now.copyWith(walletBalance: balance));
    });
  }

  /// طرق الشحن التي يدعمها التطبيق — كما تقرّرها ورقة الشحن نفسها. شحنٌ مطفأ أو سؤالٌ فشل: لا شيء.
  Future<List<TopUpMethod>> _onlineMethods() async {
    final ask = _topUpMethods;
    if (ask == null) return const [];

    return (await ask()).fold(
      (_) => const [],
      (methods) => methods.enabled
          ? [
              for (final method in methods.methods)
                if (method.isSupported) method,
            ]
          : const [],
    );
  }

  /// يختار متجراً، فتذهب الطلبية إلى مدينته ومنطقته.
  void chooseShop(int shopId) {
    final ready = _ready;
    if (ready == null) return;

    for (final shop in ready.shops) {
      if (shop.id == shopId) {
        final chosen = _withShop(ready, shop);

        // التوصيل بالمدينة، فمتجرٌ في المدينة نفسها لا يغيّر السعر.
        if (chosen.cityId == ready.cityId) {
          emit(chosen);
        } else {
          emit(_repricing(chosen));
          unawaited(_price());
        }

        return;
      }
    }
  }

  /// يختار وجهةً بيده. **يمسح المنطقة**، لأنها تخصّ المدينة التي اختيرت فيها.
  ///
  /// **والمتجر يبقى مختاراً:** المتجر لمن البضاعة، والوجهة أين تُسلَّم — وأكياسٌ لمتجرٍ في بنغازي قد
  /// تُستلم من المكتب.
  void chooseCity(int cityId) {
    final ready = _ready;
    if (ready == null || ready.cityId == cityId) return;

    emit(_repricing(ready.copyWith(cityId: cityId, regionId: null, lastFailure: null)));

    unawaited(_price());
  }

  /// **لا يعيد التسعير**: التوصيل بالمدينة لا بالمنطقة.
  void chooseRegion(int? regionId) {
    final ready = _ready;
    if (ready == null) return;

    emit(ready.copyWith(regionId: regionId, lastFailure: null));
  }

  /// يرفق تصميماً من مكتبة العميل أو يرفعه عن الطلبية.
  void toggleDesign(int designId) {
    final ready = _ready;
    if (ready == null) return;

    final attached = ready.designIds.contains(designId);

    emit(
      ready.copyWith(
        designIds: attached
            ? [...ready.designIds.where((id) => id != designId)]
            : [...ready.designIds, designId],
      ),
    );
  }

  void removeLineAt(int index) {
    final ready = _ready;
    if (ready == null || index < 0 || index >= _lines.length) return;

    _cart.removeAt(index);

    // الآن لا حين يصل خبر السلة: السطر يغادر الشاشة مع اللمسة التي حذفته.
    _linesChanged(_lines);
  }

  /// سطور السلة تغيّرت — من هنا أو من صفحة منتج — فتُعرض ويُعاد تسعيرها.
  ///
  /// **لا شيء بعد إرسال الطلبية**: السلة تُفرغ حين يستلمها المتجر، وشاشةٌ ذاهبةٌ إلى الطلبية لا
  /// تُعيد تسعير سلةٍ فارغة.
  void _linesChanged(List<OrderDraftLine> lines) {
    final ready = _ready;
    if (ready == null || ready.placed != null || listEquals(ready.lines, lines)) return;

    emit(_repricing(ready.copyWith(lines: List<OrderDraftLine>.unmodifiable(lines))));

    unawaited(_price());
  }

  /// ما غيّر السعر ينتظر تسعيره الجديد **في الحالة نفسها التي غيّرته**: حالةٌ بمدينةٍ جديدة وسعر
  /// توصيلٍ قديم كانت تُرسم إطاراً واحداً وتقول رقماً لا يخصّها.
  PlaceOrderReady _repricing(PlaceOrderReady next) =>
      next.copyWith(pricing: const BasketPricing.pending());

  /// يسأل الخادم عن سعر السلة الحالية بمدينتها. السلة الفارغة لا تُسعَّر.
  Future<void> _price() async {
    final ready = _ready;
    if (ready == null || ready.lines.isEmpty) return;

    final request = ++_pricingRequest;

    emit(ready.copyWith(pricing: const BasketPricing.pending()));

    final result = await _quote(
      items: [for (final draft in ready.lines) draft.line],
      cityId: ready.cityId,
    );

    if (isClosed || request != _pricingRequest) return;

    final current = _ready;
    if (current == null) return;

    final priced = current.copyWith(
      pricing: result.fold(
        (failure) => BasketPricing.failed(failure),
        (quote) => BasketPricing.priced(quote),
      ),
    );

    // سلةٌ تغيّرت وهي على خطوة العربون — صار فيها «حسب الطلب» — لا عربون لها بعد الآن، فتعود
    // إلى «بيانات الطلب» حيث تُرسل للمراجعة.
    emit(
      priced.step == CheckoutStep.deposit && !priced.hasDepositStep
          ? priced.copyWith(step: CheckoutStep.details)
          : priced,
    );
  }

  /// يرسلها.
  ///
  /// يعيد الطلبية التي أنشأها المتجر لتعرضها الشاشة. **من «بيانات الطلب» تُرسل للمراجعة** — لا شيء
  /// أُكِّد ولا شيء سُعِّر من المخزن؛ يقرأها أحدٌ أولاً. **ومن «العربون» تُرسل معه**، فتولد «بانتظار
  /// العربون» — أو مدفوعاً عربونها حين دفعته المحفظة.
  ///
  /// `null` يعني أنها لم تُرسل، و`lastFailure` يقول لماذا.
  Future<CustomerOrderDetail?> submit({String? recipientPhone, String? note}) async {
    final ready = _ready;
    if (ready == null || ready.isSubmitting || !ready.canSubmit) return null;

    final payment = ready.payment;

    // **الإلكتروني لا يُرسل طلبيةً قبل أن ينجح الشحن** — الشاشة تشحن أولاً ثم تنادي [toppedUp]،
    // فيصير الطريقُ المحفظة. طلبيةٌ وصلت هنا وطريقها ما زال إلكترونياً لم يُدفع عربونها بعد.
    if (ready.step == CheckoutStep.deposit && payment == CheckoutPayment.online) return null;

    final deposit = ready.step == CheckoutStep.deposit && payment != null
        ? CheckoutDeposit(
            payment: payment,
            amount: ready.depositAmount!,
            clientToken: payment == CheckoutPayment.wallet ? (_depositToken ??= uuidV4()) : null,
          )
        : null;

    emit(ready.copyWith(isSubmitting: true, lastFailure: null));

    final result = await _place(
      NewOrder(
        cityId: ready.cityId!,
        regionId: ready.regionId,
        customerShopId: ready.shopId,
        // المعرِّفات وحدها كما يتوقعها `RequestOrderRequest`: اسم المنتج في الجسم كان سيصير مصدراً
        // ثانياً لشيءٍ تعرفه الطلبية من `product_id`.
        items: [for (final draft in ready.lines) draft.line],
        designIds: ready.designIds,
        recipientPhone: _orNull(recipientPhone),
        customerNote: _orNull(note),
        deposit: deposit,
        clientToken: _orderToken ??= uuidV4(),
      ),
    );

    if (isClosed) return null;

    final current = _ready;
    if (current == null) return result.fold((_) => null, (order) => order);

    return result.fold(
      (failure) {
        // لم يُجب الخادم: لعلّه دفع، فالإعادة بالمفتاح نفسه. أجاب بالرفض: المحاولة التالية جديدة.
        if (failure is! NetworkFailure) {
          _depositToken = null;
          _orderToken = null;
        }

        emit(current.copyWith(isSubmitting: false, lastFailure: failure));

        return null;
      },
      (order) {
        // **السلة تفرغ حين يستلم المتجر الطلبية لا قبلها.** إرسالٌ فشل يتركها كما هي، فيصلح العميل
        // حقلاً ويعيد المحاولة بدل أن يبني ما كان قد اختاره من جديد.
        _cart.clear();

        // وصلت: الطلبية التالية من هذه الشاشة طلبيةٌ أخرى بمفتاحَين جديدَين.
        _orderToken = null;
        _depositToken = null;

        emit(current.copyWith(isSubmitting: false, placed: order));

        return order;
      },
    );
  }

  /// يختار [shop] ويوجّه الطلبية إلى مدينته ومنطقته — **ما دامتا على الخريطة**. مدينةٌ أُخرجت منها لا
  /// تطابق شيئاً في المنتقي، فتبقى فارغةً ليختارها العميل بدل أن تُرسَل وجهةٌ يرفضها الخادم.
  static PlaceOrderReady _withShop(PlaceOrderReady ready, Shop shop) =>
      _placed(ready.copyWith(shopId: shop.id), shop.cityId, shop.regionId);

  /// يوجّه الطلبية إلى [cityId] و[regionId] — بالقاعدة نفسها التي يتبعها المتجر: ما ليس على الخريطة
  /// يبقى فارغاً.
  static PlaceOrderReady _placed(PlaceOrderReady ready, int? cityId, int? regionId) {
    City? city;
    for (final candidate in ready.cities) {
      if (candidate.id == cityId) city = candidate;
    }

    final hasRegion = city?.regions.any((region) => region.id == regionId) ?? false;

    return ready.copyWith(
      cityId: city?.id,
      regionId: hasRegion ? regionId : null,
      lastFailure: null,
    );
  }

  /// المسافات ليست رقماً. إرسال `"   "` يضع سطراً فارغاً في الطلبية التي يقرؤها المتجر.
  static String? _orNull(String? value) {
    final trimmed = value?.trim();

    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  PlaceOrderReady? get _ready => switch (state) {
    final PlaceOrderReady ready => ready,
    _ => null,
  };

  @override
  Future<void> close() async {
    await _cartChanges.cancel();

    return super.close();
  }
}
