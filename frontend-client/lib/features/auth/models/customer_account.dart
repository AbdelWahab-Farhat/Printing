import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_account.freezed.dart';
part 'customer_account.g.dart';

/// The signed-in customer.
///
/// **Six fields where the staff app's `AuthUser` has fourteen, and the absences are the whole
/// point.** No roles, no permissions, no `is_admin`, no salary: a customer holds nothing the
/// server could grant. What he reaches is his own rows, decided from his token — see
/// Docs/customer-app/CUSTOMER-APP-DESIGN.md §٢ — so there is no capability list for this app to
/// keep, and no `Session` to answer `can()` from. That is why `core/session/` was never ported.
///
/// One class rather than an entity plus a model: `@JsonKey` is already the seam a rename on the
/// backend would need, and a second near-identical class bought nothing but a mapping to keep in
/// step.
@freezed
abstract class CustomerAccount with _$CustomerAccount {
  const factory CustomerAccount({
    required int id,
    required String name,
    required String phone,

    /// «A123» — what staff say on the phone, so the customer should be able to read it back to
    /// them. Allocated by the server and never sent by this app.
    String? code,

    /// Whether the shop is still selling to this account.
    ///
    /// Defaulted to `true`: an account nobody stopped is an account in use. A deactivated one
    /// is refused at sign-in with its own message, so this arriving `false` is a state the app
    /// will rarely see.
    @JsonKey(name: 'is_active') @Default(true) bool isActive,

    /// The shop this account was opened with, when it has one.
    ///
    /// **Null is ordinary, not a failure.** An account registered from the app has no shop until
    /// staff add one, and `auth/me` sends `null` rather than omitting the key — so «حسابي» draws
    /// a name with no line under it instead of treating the account as half-loaded.
    ///
    /// Absent altogether from `register` and `login`: neither is a moment when «حسابي» is on
    /// screen, and loading three relations to fill a card nobody is looking at is a query the
    /// sign-in screen would pay for.
    CustomerShop? shop,

    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _CustomerAccount;

  factory CustomerAccount.fromJson(Map<String, dynamic> json) =>
      _$CustomerAccountFromJson(json);
}

/// The customer's shop, as much of it as this app has any use for.
///
/// **Three strings and no id.** The customer app cannot edit a shop — there is no endpoint — so
/// an id here would be a handle on something nothing can be done with. What «حسابي» draws is
/// «متجر النور · بنغازي» and «ملابس وأحذية», and that is the whole of what travels.
@freezed
abstract class CustomerShop with _$CustomerShop {
  const factory CustomerShop({
    String? name,

    /// The city as the shop's record names it, not as an order snapshotted it.
    @JsonKey(name: 'city_name') String? cityName,

    /// «ملابس وأحذية» — the trade, which is a fact about the shop rather than the account.
    @JsonKey(name: 'business_field') String? businessField,
  }) = _CustomerShop;

  factory CustomerShop.fromJson(Map<String, dynamic> json) =>
      _$CustomerShopFromJson(json);
}

/// What `register` and `login` answer with: who came in, and the token to send back.
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({
    required CustomerAccount customer,
    required String token,
  }) = _AuthSession;

  factory AuthSession.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionFromJson(json);
}
