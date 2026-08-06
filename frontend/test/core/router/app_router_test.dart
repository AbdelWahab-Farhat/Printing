import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/features/audit/models/audit_subject.dart';

/// What each path resolves to, asked of the real router rather than reasoned about.
///
/// The one that needs proving is `/customers/new`: it sits under `/customers`, which is a shell
/// branch, and "does the branch swallow it?" is a question with a silent wrong answer — the
/// button would land on a tab, or on the error page, and only a person tapping it would find
/// out. `findMatch` answers it without building a widget tree.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// Every route a location resolves through, innermost last.
  ///
  /// Flattened, because a shell keeps its branch's matches nested inside its own: reading only
  /// the top level of `RouteMatchList.matches` would see the shell and never the page under it.
  List<RouteBase> matchedRoutes(String location) {
    final flattened = <RouteBase>[];

    void walk(List<RouteMatchBase> matches) {
      for (final match in matches) {
        flattened.add(match.route);
        if (match is ShellRouteMatch) walk(match.matches);
      }
    }

    walk(AppRouter.instance.configuration.findMatch(Uri.parse(location)).matches);

    return flattened;
  }

  test('adding a customer is a route of its own, not the العملاء tab', () {
    // Arrange — `/customers` is a shell branch with no sub-routes, so this path can only be
    // served by the top-level route declared beside it.
    const location = '/customers/new';

    // Act
    final matches = matchedRoutes(location);

    // Assert — it resolves, and to something outside the shell, so the form covers the tabs.
    expect(matches, isNotEmpty);
    expect(
      matches.whereType<GoRoute>().last.path,
      '/customers/new',
      reason: 'the add-customer form must be what /customers/new opens',
    );
    expect(
      matches.whereType<ShellRouteBase>(),
      isEmpty,
      reason: 'a form is a task the user is in, not a tab they are browsing',
    );
  });

  test('a city\'s regions resolve under the city, and outside the shell', () {
    // Arrange — `/cities/:id/regions` is declared as a child of `/cities`, which is itself
    // outside the shell. "Does the parent swallow the child?" is the same silent wrong answer
    // as above: the row would open the map again, and only a person tapping it would find out.
    final location = Routes.cityRegions(3);

    // Act
    final matches = matchedRoutes(location);

    // Assert
    expect(location, '/cities/3/regions');
    expect(matches.whereType<GoRoute>().last.path, Routes.cityRegionsPath);
    expect(
      matches.whereType<ShellRouteBase>(),
      isEmpty,
      reason: 'opening a city is a place the user goes to, not a tab they browse between',
    );
  });

  test('the delivery map itself still resolves, and is not shadowed by its child', () {
    // Arrange
    const location = Routes.cities;

    // Act
    final matches = matchedRoutes(location);

    // Assert
    expect(matches.whereType<GoRoute>().last.path, Routes.cities);
  });

  test('every link this app can build opens something', () {
    // Arrange — this exact bug has already shipped once. `Routes.customerDesigns` existed as a
    // helper, nothing ever registered its path, and the button on the customer's screen opened
    // «الصفحة غير موجودة». A path helper with no route behind it is a broken link the compiler
    // cannot see, so the table below is the thing that sees it. One line per new link.
    final links = <String, String>{
      'العملاء': Routes.customers,
      'عميل واحد': Routes.customer(9),
      'إضافة عميل': Routes.addCustomer,
      'تعديل عميل': Routes.editCustomer(9),
      'تصاميم العميل': Routes.customerDesigns(9),
      'سجل التعديلات': Routes.activityLog(AuditSubject.customer, 9),
      'طلب واحد': Routes.order(4),
      'إضافة منتج': Routes.addProduct,
      'منتج واحد': Routes.product(7),
      'تعديل منتج': Routes.editProduct(7),
      'مناطق مدينة': Routes.cityRegions(3),
      'الطلبيات المفلترة': Routes.ordersFiltered,
      'شركات التوصيل': Routes.shippingCompanies,
      'نموذج شركة التوصيل': Routes.shippingCompanyForm,
      'الموظفون': Routes.employees,
      'موظف جديد': Routes.addEmployee,
      'الأدوار': Routes.roles,
      'دور جديد': Routes.newRole,
      'دور واحد': Routes.role(4),
      'تعديل دور': Routes.editRole(4),
      'سجل الدور': Routes.activityLog(AuditSubject.role, 4),
      'اختيار موقع': Routes.pickLocation,
      'الإعدادات': Routes.settings,
      'المخزن': Routes.warehouse,
    };

    // Act & Assert
    for (final MapEntry(key: name, value: location) in links.entries) {
      final match = AppRouter.instance.configuration.findMatch(Uri.parse(location));

      expect(
        match.isError,
        isFalse,
        reason: '«$name» → $location resolves to nothing; is its GoRoute registered?',
      );
    }
  });

  test("a customer's designs resolve under the customer, and outside the shell", () {
    // Arrange — nested under `/customers/:id`, which is itself declared after `/customers/new`
    // so `:id` cannot swallow the literal word.
    final location = Routes.customerDesigns(9);

    // Act
    final matches = matchedRoutes(location);

    // Assert
    expect(location, '/customers/9/designs');
    expect(matches.whereType<GoRoute>().last.path, 'designs');
    expect(
      matches.whereType<ShellRouteBase>(),
      isEmpty,
      reason: 'a library of files is a place the user goes to, not a tab they browse between',
    );
  });

  test('«/products/new» is the form, not the detail screen reading «new» as an id', () {
    // Arrange — `:id` is declared after `/products/new`, and that ordering is load-bearing:
    // declared first it would capture the literal word and `int.parse('new')` would throw on
    // the way in. The wrong answer here is silent until somebody taps «منتج جديد».
    const location = Routes.addProduct;

    // Act
    final matches = matchedRoutes(location);

    // Assert
    expect(matches.whereType<GoRoute>().last.path, Routes.addProduct);
  });

  test('opening a product resolves to the detail screen, outside the shell', () {
    // Arrange
    final location = Routes.product(7);

    // Act
    final matches = matchedRoutes(location);

    // Assert
    expect(location, '/products/7');
    expect(matches.whereType<GoRoute>().last.path, Routes.productDetailPath);
    expect(
      matches.whereType<ShellRouteBase>(),
      isEmpty,
      reason: 'opening a product is a place the user goes to, not a tab they browse between',
    );
  });

  test('the المنتجات tab still resolves, and still inside the shell', () {
    // Arrange — the sibling paths above must not have shadowed it.
    const location = Routes.products;

    // Act
    final matches = matchedRoutes(location);

    // Assert
    expect(matches.whereType<GoRoute>().last.path, Routes.products);
    expect(matches.whereType<ShellRouteBase>(), isNotEmpty);
  });

  test('registering an employee is its own route, not the list reading a sub-path', () {
    // Arrange — `/employees/new` is declared before `/employees` and carries the stricter
    // guard: reading the list is a permission, creating an account is the administrator's
    // alone. Declared the other way round, the looser guard would be the one that ran.
    const location = Routes.addEmployee;

    // Act
    final matches = matchedRoutes(location);

    // Assert
    expect(location, '/employees/new');
    expect(matches.whereType<GoRoute>().last.path, Routes.addEmployee);
    expect(
      matches.whereType<ShellRouteBase>(),
      isEmpty,
      reason: 'a form is a task the user is in, not a tab they are browsing',
    );
  });

  test('the staff list still resolves, and is not shadowed by the form beside it', () {
    // Arrange
    const location = Routes.employees;

    // Act
    final matches = matchedRoutes(location);

    // Assert
    expect(matches.whereType<GoRoute>().last.path, Routes.employees);
  });

  test('creating a role is a route of its own, not the id route reading «new»', () {
    // Arrange — `/roles/new` sits beside `/roles/:id`, and go_router matches in declaration
    // order. Declared the wrong way round, `:id` captures the literal word and
    // `int.parse('new')` throws on the way into the role screen — a crash only a tester finds.
    const location = Routes.newRole;

    // Act
    final matches = matchedRoutes(location);

    // Assert
    expect(matches.whereType<GoRoute>().last.path, Routes.newRole);
  });

  test('editing a role resolves under the role it edits', () {
    // Arrange
    final location = Routes.editRole(4);

    // Act
    final matches = matchedRoutes(location);

    // Assert
    expect(location, '/roles/4/edit');
    expect(matches.whereType<GoRoute>().last.path, 'edit');
    expect(
      matches.whereType<ShellRouteBase>(),
      isEmpty,
      reason: 'a form is a task the user is in, not a tab they are browsing',
    );
  });

  test('the العملاء tab still resolves, and still inside the shell', () {
    // Arrange — the sibling path must not have been shadowed by the one above.
    const location = '/customers';

    // Act
    final matches = matchedRoutes(location);

    // Assert
    expect(matches.whereType<GoRoute>().last.path, '/customers');
    expect(matches.whereType<ShellRouteBase>(), isNotEmpty);
  });

  test('moving an order resolves under the order, not as a tab or an error', () {
    // Arrange — `/orders` is a shell branch and `/orders/:id` is declared outside it, so
    // `/orders/7/status` has two ways to be swallowed: by the branch, or by `:id` reading
    // «status» as an order number.
    final location = Routes.orderStatus(7);

    // Act
    final matches = matchedRoutes(location);

    // Assert
    expect(matches.whereType<GoRoute>().last.path, Routes.orderStatusPath);
    expect(
      matches.whereType<ShellRouteBase>(),
      isEmpty,
      reason: 'moving an order is a task the user is in, not a tab they are browsing',
    );
  });

  test('editing an order resolves under it too, and is not the move screen', () {
    // Arrange — two children of the same route, and neither may answer for the other.
    final location = Routes.editOrder(7);

    // Act
    final matches = matchedRoutes(location);

    // Assert
    expect(matches.whereType<GoRoute>().last.path, Routes.orderEditPath);
    expect(matches.whereType<ShellRouteBase>(), isEmpty);
  });

  test('«/products/7/edit» is the form, not the detail screen reading «edit» as a size', () {
    // Arrange — declared as a child of `/products/:id`, which is itself declared after
    // `/products/new`. Both orderings are load-bearing, and both fail silently: the wrong one
    // opens the detail screen again, and only somebody tapping «تعديل المنتج» finds out.
    final location = Routes.editProduct(7);

    // Act
    final matches = matchedRoutes(location);

    // Assert
    expect(location, '/products/7/edit');
    expect(matches.whereType<GoRoute>().last.path, Routes.editProductPath);
    expect(
      matches.whereType<ShellRouteBase>(),
      isEmpty,
      reason: 'a form is a task the user is in, not a tab they are browsing',
    );
  });
}
