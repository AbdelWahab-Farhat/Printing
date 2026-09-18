import 'package:dayaa_client/core/config/app_config.dart';
import 'package:dayaa_client/core/files/attachment_picker.dart';
import 'package:dayaa_client/core/files/attachment_picker_impl.dart';
import 'package:dayaa_client/core/network/dio_client.dart';
import 'package:dayaa_client/core/storage/token_storage.dart';
import 'package:dayaa_client/core/theme/theme_mode_cubit.dart';
import 'package:dayaa_client/features/auth/presentation/viewmodel/login_cubit.dart';
import 'package:dayaa_client/features/auth/presentation/viewmodel/register_cubit.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository_impl.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/auth/usecases/has_stored_session.dart';
import 'package:dayaa_client/features/auth/usecases/login.dart';
import 'package:dayaa_client/features/auth/usecases/logout.dart';
import 'package:dayaa_client/features/auth/usecases/register.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/badges/repositories/badge_repository.dart';
import 'package:dayaa_client/features/badges/repositories/badge_repository_impl.dart';
import 'package:dayaa_client/features/badges/usecases/get_badges.dart';
import 'package:dayaa_client/features/billboards/presentation/viewmodel/billboard_cubit.dart';
import 'package:dayaa_client/features/billboards/repositories/billboard_repository.dart';
import 'package:dayaa_client/features/billboards/repositories/billboard_repository_impl.dart';
import 'package:dayaa_client/features/billboards/usecases/get_billboards.dart';
import 'package:dayaa_client/features/catalog/presentation/viewmodel/product_detail_cubit.dart';
import 'package:dayaa_client/features/catalog/presentation/viewmodel/products_cubit.dart';
import 'package:dayaa_client/features/catalog/repositories/catalog_repository.dart';
import 'package:dayaa_client/features/catalog/repositories/catalog_repository_impl.dart';
import 'package:dayaa_client/features/catalog/usecases/browse_products.dart';
import 'package:dayaa_client/features/catalog/usecases/get_product.dart';
import 'package:dayaa_client/features/catalog/usecases/list_categories.dart';
import 'package:dayaa_client/features/catalog/usecases/quote_price.dart';
import 'package:dayaa_client/features/delivery/repositories/delivery_repository.dart';
import 'package:dayaa_client/features/delivery/repositories/delivery_repository_impl.dart';
import 'package:dayaa_client/features/delivery/usecases/list_cities.dart';
import 'package:dayaa_client/features/designs/presentation/viewmodel/designs_cubit.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository_impl.dart';
import 'package:dayaa_client/features/designs/usecases/list_designs.dart';
import 'package:dayaa_client/features/designs/usecases/remove_design.dart';
import 'package:dayaa_client/features/designs/usecases/rename_design.dart';
import 'package:dayaa_client/features/designs/usecases/upload_design.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/cart_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/place_order_cubit.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository_impl.dart';
import 'package:dayaa_client/features/orders/usecases/browse_orders.dart';
import 'package:dayaa_client/features/orders/usecases/get_order.dart';
import 'package:dayaa_client/features/orders/usecases/place_order.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/support_cubit.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/ticket_thread_cubit.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';
import 'package:dayaa_client/features/support/repositories/support_repository_impl.dart';
import 'package:dayaa_client/features/support/usecases/browse_tickets.dart';
import 'package:dayaa_client/features/support/usecases/get_ticket.dart';
import 'package:dayaa_client/features/support/usecases/open_ticket.dart';
import 'package:dayaa_client/features/support/usecases/reply_to_ticket.dart';
import 'package:dayaa_client/features/tools/presentation/viewmodel/bag_preview_cubit.dart';
import 'package:dayaa_client/features/tools/presentation/viewmodel/qr_tool_cubit.dart';
import 'package:dayaa_client/features/tools/usecases/generate_qr_code.dart';
import 'package:dayaa_client/features/tools/usecases/load_bag_mockup.dart';
import 'package:dayaa_client/features/tools/usecases/load_design_image.dart';
import 'package:dayaa_client/features/tools/usecases/save_bag_preview_image.dart';
import 'package:dayaa_client/features/tools/usecases/save_qr_code_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt sl = GetIt.instance;

/// Wires the object graph. Nothing else in the app calls `GetIt.registerX`.
///
/// **Which registration to use.** The choice is not stylistic — it decides whether two screens
/// see the same data:
///
/// | Kind | Use for | Why |
/// |---|---|---|
/// | `registerSingleton` | things that must exist before `runApp` (Dio, prefs) | already built |
/// | `registerLazySingleton` | repositories, use cases, app-wide Cubits | built once, on first use |
/// | `registerFactory` | screen-scoped Cubits | a fresh one per screen, so a closed Cubit is never reused |
///
/// A screen-scoped Cubit registered as a singleton is the classic bug here: `close()` on the
/// first screen leaves every later one emitting into a dead stream.
///
/// **One `_registerX()` per feature**, called in [init] in the order the features were built.
/// The staff app's injector is what this grows into; keeping the shape from the first feature
/// means it never has to be reorganised.
abstract final class Injector {
  static bool _isInitialized = false;

  static Future<void> init({
    required Future<void> Function() onUnauthorized,
  }) async {
    if (_isInitialized) {
      debugPrint('⚠️ Injector already initialised — skipping');

      return;
    }

    // ── things the rest of the graph needs before it can be built ──────────────
    await AppConfig.load();

    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final tokens = TokenStorage(secureStorage);

    // Warms the in-memory cache so the first request and the first routing guard both have
    // the token without awaiting.
    await tokens.read();

    sl
      ..registerSingleton<SharedPreferences>(prefs)
      // Above the router like the basket, because a palette is the app's and not a screen's —
      // and eagerly, because `app.dart` reads it on the very first build.
      ..registerSingleton<ThemeModeCubit>(ThemeModeCubit(prefs))
      ..registerSingleton<TokenStorage>(tokens)
      ..registerSingleton<Dio>(
        DioClient.create(tokens: tokens, onUnauthorized: onUnauthorized),
      )
      // Getting files off the device. Registered here rather than in a feature block because
      // nothing about it is a feature's. Behind its interface so a widget test can substitute
      // one — both packages answer through a platform channel that does not exist under
      // `flutter_test`, so the real one would hang there.
      ..registerLazySingleton<AttachmentPicker>(AttachmentPickerImpl.new);

    _registerAuth();
    _registerDesigns();
    _registerCatalog();
    _registerDelivery();
    _registerOrders();
    _registerBagPreview();
    _registerBillboards();
    _registerSupport();
    _registerTools();

    _isInitialized = true;
  }

  /// Signing in, and the session.
  ///
  /// **The two Cubits are factories, the rest are lazy singletons**, and the split is the table
  /// above applied: a repository and a use case are stateless and shared, while a Cubit belongs
  /// to one screen and is closed with it. Registering `LoginCubit` as a singleton is the classic
  /// bug — the second visit to the screen gets the one that was already closed, and every
  /// `emit` after that throws into a dead stream.
  static void _registerAuth() {
    sl
      ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl<Dio>(), sl<TokenStorage>()),
      )
      ..registerLazySingleton(() => Login(sl<AuthRepository>()))
      ..registerLazySingleton(() => Register(sl<AuthRepository>()))
      ..registerLazySingleton(() => Logout(sl<AuthRepository>()))
      ..registerLazySingleton(() => GetCurrentCustomer(sl<AuthRepository>()))
      ..registerLazySingleton(() => HasStoredSession(sl<AuthRepository>()))
      ..registerFactory(() => LoginCubit(login: sl<Login>()))
      ..registerFactory(() => RegisterCubit(register: sl<Register>()));
  }

  /// «تصاميمي» — the artwork a customer uploads once and points every order at.
  static void _registerDesigns() {
    sl
      ..registerLazySingleton<DesignRepository>(() => DesignRepositoryImpl(sl<Dio>()))
      ..registerLazySingleton(() => ListDesigns(sl<DesignRepository>()))
      ..registerLazySingleton(() => UploadDesign(sl<DesignRepository>()))
      ..registerLazySingleton(() => RenameDesign(sl<DesignRepository>()))
      ..registerLazySingleton(() => RemoveDesign(sl<DesignRepository>()))
      ..registerFactory(
        () => DesignsCubit(
          list: sl<ListDesigns>(),
          upload: sl<UploadDesign>(),
          rename: sl<RenameDesign>(),
          remove: sl<RemoveDesign>(),
        ),
      );
  }

  /// The catalogue.
  ///
  /// **`ProductDetailCubit` is a plain factory although it shows one product**, because the id
  /// arrives at `load()` rather than in the constructor — which keeps the same instance usable
  /// for a screen that switches product without being rebuilt.
  static void _registerCatalog() {
    sl
      ..registerLazySingleton<CatalogRepository>(() => CatalogRepositoryImpl(sl<Dio>()))
      ..registerLazySingleton(() => BrowseProducts(sl<CatalogRepository>()))
      ..registerLazySingleton(() => GetProduct(sl<CatalogRepository>()))
      ..registerLazySingleton(() => ListCategories(sl<CatalogRepository>()))
      ..registerLazySingleton(() => QuotePrice(sl<CatalogRepository>()))
      ..registerFactory(
        () => ProductsCubit(
          browse: sl<BrowseProducts>(),
          categories: sl<ListCategories>(),
        ),
      )
      ..registerFactory(
        () => ProductDetailCubit(getProduct: sl<GetProduct>(), quote: sl<QuotePrice>()),
      );
  }

  /// Where an order can be sent. No Cubit of its own — the picker belongs to the order screen,
  /// which is the only place a destination is chosen.
  static void _registerDelivery() {
    sl
      ..registerLazySingleton<DeliveryRepository>(() => DeliveryRepositoryImpl(sl<Dio>()))
      ..registerLazySingleton(() => ListCities(sl<DeliveryRepository>()));
  }

  /// «طلباتي», and placing one.
  ///
  /// **One `registerFactoryParam`, and the parameter is the reason for it**: an
  /// `OrderDetailCubit` is built *for* an order and needs a value at construction that `sl<T>()`
  /// cannot supply. The alternative — a nullable field set after construction — is a Cubit that
  /// can exist in a state where it does not know what it is showing.
  static void _registerOrders() {
    sl
      ..registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(sl<Dio>()))
      ..registerLazySingleton(() => BrowseOrders(sl<OrderRepository>()))
      ..registerLazySingleton(() => GetOrder(sl<OrderRepository>()))
      ..registerLazySingleton(() => PlaceOrder(sl<OrderRepository>()))
      // **The one Cubit in this app that is a singleton, and the reason is that it outlives
      // every screen that touches it.** A basket held by the product screen empties the moment
      // that screen is popped, and «أضف إلى الطلبية» has to survive going back to the catalogue
      // and opening a second product — which is the whole point of having a basket. Not
      // persisted across launches: see the note on `CartCubit`.
      ..registerLazySingleton(CartCubit.new)
      // **A singleton beside the cart, and for a related reason.** The counts belong to the
      // session rather than to a screen: the home tile and anything badged later must read the
      // same number, and a factory would refetch on every rebuild and disagree with itself.
      ..registerLazySingleton<BadgeRepository>(() => BadgeRepositoryImpl(sl<Dio>()))
      ..registerLazySingleton(() => GetBadges(sl<BadgeRepository>()))
      ..registerLazySingleton(() => BadgesCubit(getBadges: sl<GetBadges>()))
      ..registerFactory(() => OrdersCubit(browse: sl<BrowseOrders>()))
      ..registerFactoryParam<OrderDetailCubit, int, void>(
        (orderId, _) => OrderDetailCubit(orderId: orderId, get: sl<GetOrder>()),
      )
      // **No parameter any more.** It used to be built *for* a set of lines, because the only
      // way to this screen was one product pushing one of them. The lines are the basket's now,
      // and the basket is a singleton — so there is nothing left to pass, and one less way for
      // the screen and the basket to disagree about what is in the order.
      ..registerFactory(
        () => PlaceOrderCubit(
          cities: sl<ListCities>(),
          designs: sl<ListDesigns>(),
          place: sl<PlaceOrder>(),
          cart: sl<CartCubit>(),
        ),
      );
  }

  /// «الأدوات».
  ///
  /// **The bag mockups are a lazy singleton with a cache inside it**, and both halves matter:
  /// five images decoded once for the life of the process, because switching bags is what a
  /// customer does three times a minute while trying a logo on sizes — and re-decoding on every
  /// tap is felt immediately. See `LoadBagMockup` for why nothing disposes them.
  static void _registerBagPreview() {
    sl
      ..registerLazySingleton<LoadDesignImage>(LoadDesignImage.new)
      ..registerLazySingleton<LoadBagMockup>(LoadBagMockup.new)
      ..registerLazySingleton<SaveBagPreviewImage>(SaveBagPreviewImage.new)
      ..registerFactory<BagPreviewCubit>(
        () => BagPreviewCubit(
          loadImage: sl<LoadDesignImage>(),
          loadMockup: sl<LoadBagMockup>(),
        ),
      );
  }

  /// The carousel on the home screen.
  static void _registerBillboards() {
    sl
      ..registerLazySingleton<BillboardRepository>(() => BillboardRepositoryImpl(sl<Dio>()))
      ..registerLazySingleton(() => GetBillboards(sl<BillboardRepository>()))
      ..registerFactory(() => BillboardCubit(get: sl<GetBillboards>()));
  }

  /// Reaching a person.
  static void _registerSupport() {
    sl
      ..registerLazySingleton<SupportRepository>(() => SupportRepositoryImpl(sl<Dio>()))
      ..registerLazySingleton(() => BrowseTickets(sl<SupportRepository>()))
      ..registerLazySingleton(() => GetTicket(sl<SupportRepository>()))
      ..registerLazySingleton(() => OpenTicket(sl<SupportRepository>()))
      ..registerLazySingleton(() => ReplyToTicket(sl<SupportRepository>()))
      ..registerFactory(
        () => SupportCubit(browse: sl<BrowseTickets>(), open: sl<OpenTicket>()),
      )
      ..registerFactoryParam<TicketThreadCubit, int, void>(
        (ticketId, _) => TicketThreadCubit(
          ticketId: ticketId,
          get: sl<GetTicket>(),
          reply: sl<ReplyToTicket>(),
        ),
      );
  }

  /// The QR tool.
  ///
  /// **Nothing here touches the network**, which is why there is no repository: encoding is a
  /// synchronous calculation and saving is a file write. It is the one feature in this app whose
  /// whole graph is two use cases.
  static void _registerTools() {
    sl
      ..registerLazySingleton(() => const GenerateQrCode())
      ..registerLazySingleton(() => const SaveQrCodeImage())
      ..registerFactory(() => QrToolCubit(generate: sl<GenerateQrCode>()));
  }

  /// Tests only. Never called by the running app.
  @visibleForTesting
  static Future<void> reset() async {
    await sl.reset();
    _isInitialized = false;
  }
}
