import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_draft.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/cart_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// السلة.
///
/// **القاعدة الوحيدة التي يقرّرها التطبيق بنفسه**، وهي قاعدة الخادم مقروءةً إلى الأمام:
/// `CreateOrder` يرفض طلبيةً لا تتفق سطورها على «على أيّ منضدة تُصنع»، والسلة تقولها عند
/// اللمسة التي سبّبتها بدل نهاية سلّةٍ ممتلئة. وما عدا ذلك — سعرٌ تحرّك، مقاسٌ أُوقف، عميلٌ
/// توقّف المتجر عن البيع له — جوابُ الخادم، يصل حين تُرسل الطلبية.
///
/// Arrange - Act - Assert throughout.
void main() {
  OrderDraftLine line({
    int productId = 1,
    int variantId = 1,
    String quantity = '1000',
    String group = 'shared',
  }) => OrderDraftLine(
    line: NewOrderLine(
      productId: productId,
      productVariantId: variantId,
      quantity: quantity,
    ),
    title: 'منتج $productId',
    orderGroup: group,
  );

  test('a new basket is empty and belongs to no group', () {
    // Arrange - Act
    final cart = CartCubit();

    // Assert — an empty basket takes anything, which is what makes «أرسل سلتك أولاً» a way out
    // of the refusal rather than a dead end.
    expect(cart.state.isEmpty, isTrue);
    expect(cart.state.group, isNull);

    cart.close();
  });

  test('two products of the same group share a basket', () {
    // Arrange — «سادة» beside «مطبوعة»: both ours, and `CreateOrder` takes the order.
    final cart = CartCubit()
      ..add(line(productId: 1))
      ..add(line(productId: 2, variantId: 2));

    // Assert
    expect(cart.state.count, 2);

    cart.close();
  });

  test('a product from another group is refused, and the basket is untouched', () {
    // Arrange
    final cart = CartCubit()..add(line(productId: 1));

    // Act
    final refusal = cart.add(line(productId: 9, variantId: 9, group: 'exclusive'));

    // Assert — refused rather than added and complained about afterwards: a basket that grows a
    // line it is about to be told off for is a basket the customer has to repair.
    expect(refusal, CartRefusal.differentGroup);
    expect(cart.state.count, 1);

    cart.close();
  });

  test('the refusal holds whichever group got in first', () {
    // Arrange
    final cart = CartCubit()..add(line(productId: 9, group: 'exclusive'));

    // Act
    final refusal = cart.add(line(productId: 1, variantId: 2));

    // Assert
    expect(refusal, CartRefusal.differentGroup);

    cart.close();
  });

  test('emptying the basket lets the other group in', () {
    // Arrange — the way out the refusal's message promises: «أرسل سلتك أولاً أو أفرغها».
    final cart = CartCubit()..add(line(productId: 1));

    // Act
    cart.removeAt(0);
    final refusal = cart.add(line(productId: 9, group: 'exclusive'));

    // Assert
    expect(refusal, isNull);
    expect(cart.state.group, 'exclusive');

    cart.close();
  });

  test('the same product and size replaces its quantity rather than doubling it', () {
    // Arrange — the customer came back from the product screen having chosen a number on it.
    // That number is what they want; adding it to the old one is arithmetic nobody asked for.
    final cart = CartCubit()..add(line(quantity: '1000'));

    // Act
    final refusal = cart.add(line(quantity: '2500'));

    // Assert
    expect(refusal, CartRefusal.alreadyIn);
    expect(cart.state.count, 1);
    expect(cart.state.lines.single.line.quantity, '2500');

    cart.close();
  });

  test('another size of the same product is its own line', () {
    // Arrange — «٢٥×٣٥» and «٤٥×٦٠» of one bag are two things to make, not one.
    final cart = CartCubit()..add(line(variantId: 1));

    // Act
    final refusal = cart.add(line(variantId: 2));

    // Assert
    expect(refusal, isNull);
    expect(cart.state.count, 2);

    cart.close();
  });

  test('removing an index that is not there changes nothing', () {
    // Arrange — the screen and the basket can disagree for a frame after a rebuild.
    final cart = CartCubit()..add(line());

    // Act
    cart
      ..removeAt(5)
      ..removeAt(-1);

    // Assert
    expect(cart.state.count, 1);

    cart.close();
  });

  test('clear empties it', () {
    // Arrange
    final cart = CartCubit()
      ..add(line(productId: 1))
      ..add(line(productId: 2, variantId: 2));

    // Act
    cart.clear();

    // Assert
    expect(cart.state.isEmpty, isTrue);
    expect(cart.state.group, isNull);

    cart.close();
  });
}
