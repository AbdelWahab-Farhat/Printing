import 'package:dayaa/features/cities/models/city.dart';
import 'package:dayaa/features/orders/models/transition_field.dart';
import 'package:dayaa/features/orders/presentation/widgets/transition_field_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «مدينة التوصيل» on «استلام مكتب» → «إعادة إرسال»: a city button, then a region button once a
/// city is chosen.
///
/// Arrange - Act - Assert throughout.
void main() {
  const field = TransitionField(
    key: 'destination',
    type: TransitionFieldType.destination,
    label: 'مدينة التوصيل',
    isRequired: true,
  );

  Widget host(Object? value) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      home: Scaffold(
        body: TransitionFieldInput(
          field: field,
          value: value,
          customerId: 1,
          onChanged: (_) {},
        ),
      ),
    ),
  );

  testWidgets('with nothing chosen it asks for the city only', (tester) async {
    // Act
    await tester.pumpWidget(host(null));

    // Assert
    expect(find.text('اختيار المدينة'), findsOneWidget);
    expect(find.textContaining('اختيار المنطقة'), findsNothing);
  });

  testWidgets('a chosen city names itself and asks for its region', (tester) async {
    // Arrange
    const city = City(id: 21, name: 'جنزور', isRegionRequired: true);

    // Act
    await tester.pumpWidget(host(const DeliveryDestination(city: city)));

    // Assert
    expect(find.text('جنزور'), findsOneWidget);
    expect(find.text('اختيار المنطقة'), findsOneWidget);
  });

  testWidgets('a region the city does not need is marked optional', (tester) async {
    // Arrange
    const city = City(id: 22, name: 'الزاوية', isRegionRequired: false);

    // Act
    await tester.pumpWidget(host(const DeliveryDestination(city: city)));

    // Assert
    expect(find.text('اختيار المنطقة (اختياري)'), findsOneWidget);
  });
}
