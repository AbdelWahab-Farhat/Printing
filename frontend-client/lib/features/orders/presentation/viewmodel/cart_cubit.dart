import 'package:dayaa_client/features/orders/models/order_draft.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Why a product could not join the basket.
///
/// **One reason, and it is the only one the app decides for itself.** Everything else an order
/// can be refused for — a price that moved, a variant that was retired, a customer the shop
/// stopped selling to — is the server's answer, arriving when the order is sent. This one is
/// decided here because the alternative is letting somebody fill a basket and telling them at
/// the end.
enum CartRefusal {
  /// The product belongs to a different basket from what is already in this one.
  ///
  /// The message says what to *do*, not what the product is: the app holds a token and not a
  /// reason, and «هذا المنتج وسيط» is a sentence it could not write truthfully if it tried.
  differentGroup,

  /// The same product and size is already in the basket.
  ///
  /// Not an error the customer needs shouting at them — the basket simply gains the quantity
  /// rather than a second identical row.
  alreadyIn,
}

/// What is in the basket right now.
@immutable
class CartState {
  const CartState({this.lines = const []});

  final List<OrderDraftLine> lines;

  bool get isEmpty => lines.isEmpty;

  int get count => lines.length;

  /// The basket every line in it belongs to, or null when it is empty.
  ///
  /// The lines are unanimous by construction — [CartCubit.add] is the only way in and it
  /// refuses anything else — so the first line answers for all of them.
  String? get group => lines.isEmpty ? null : lines.first.orderGroup;

  CartState copyWith({List<OrderDraftLine>? lines}) =>
      CartState(lines: lines ?? this.lines);
}

/// The basket.
///
/// **A singleton, and that is the whole design.** A basket held by a screen is a basket that
/// empties when the screen is popped, and «أضف إلى الطلبية» on the product screen has to survive
/// going back to the catalogue and opening a second product — which is the entire point of
/// having one. So it lives in the injector as a lazy singleton and every screen reads the same
/// object; see `injector.dart`.
///
/// **It is not persisted.** A basket that outlives the process would outlive a price change, a
/// retired size and a product that stopped being sold — and the app would be offering to order
/// something the shop no longer lists. Restoring one would mean re-quoting every line against
/// the server before drawing it, which is a feature, not a `SharedPreferences` write. What is
/// kept is what the customer is looking at now.
///
/// **No total.** What the order costs is the server's answer and arrives with the order it
/// creates — this app has never multiplied a price by a quantity and must not start in the one
/// place where the number would read as a promise.
class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  /// Puts a line in the basket, or says why it cannot go in.
  ///
  /// Returns null when the line went in.
  CartRefusal? add(OrderDraftLine line) {
    // **The unanimity rule, and it is the server's rule read forward.** `CreateOrder` refuses an
    // order whose lines do not agree about which basket they belong to; without this the
    // customer would discover that at the end of a filled basket rather than on the tap that
    // caused it.
    if (state.group case final group? when group != line.orderGroup) {
      return CartRefusal.differentGroup;
    }

    final index = state.lines.indexWhere((existing) => _sameItem(existing, line));

    if (index >= 0) {
      // **The quantity is replaced, not added to.** The customer came back from the product
      // screen having chosen a number on it; that number is what they want, and silently
      // doubling it because they visited twice is the app doing arithmetic nobody asked for.
      final lines = [...state.lines];
      lines[index] = line;
      emit(state.copyWith(lines: lines));

      return CartRefusal.alreadyIn;
    }

    emit(state.copyWith(lines: [...state.lines, line]));

    return null;
  }

  /// Takes a line out. An empty basket has no group, so the next product may be anything.
  void removeAt(int index) {
    if (index < 0 || index >= state.lines.length) return;

    emit(state.copyWith(lines: [...state.lines]..removeAt(index)));
  }

  /// After the order is sent, and on sign-out.
  void clear() => emit(const CartState());

  /// Same product and same size. The quantity is deliberately not part of it — that is the
  /// thing a second visit changes.
  bool _sameItem(OrderDraftLine a, OrderDraftLine b) =>
      a.line.productId == b.line.productId &&
      a.line.productVariantId == b.line.productVariantId;
}
