import 'package:dayaa/features/access/models/role.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a role screen reads off the model, and — the part that carries the feature — how a flat
/// list of granted permissions becomes the sections somebody can actually read.
///
/// Arrange - Act - Assert throughout.
void main() {
  Map<String, dynamic> roleJson(Map<String, dynamic> overrides) => {
    'id': 4,
    'name': 'accountant',
    'label': 'محاسب',
    'grants_everything': false,
    'is_system': true,
    'can_be_renamed': true,
    'can_be_deleted': false,
    'can_edit_permissions': true,
    'permissions': [
      {'name': 'orders.view', 'label': 'عرض الطلبيات'},
      {'name': 'orders.discount', 'label': 'منح خصم على الطلبية'},
    ],
    'users_count': 2,
    ...overrides,
  };

  const catalogue = [
    PermissionGroup(
      title: 'الطلبيات',
      permissions: [
        PermissionOption(name: 'orders.view', label: 'عرض الطلبيات'),
        PermissionOption(name: 'orders.manage', label: 'إضافة وتعديل الطلبيات'),
        PermissionOption(name: 'orders.discount', label: 'منح خصم على الطلبية'),
      ],
    ),
    PermissionGroup(
      title: 'حالات الطلبيات',
      permissions: [
        PermissionOption(name: 'orders.status.ready', label: 'تحويل الطلبية إلى جاهزة'),
        PermissionOption(name: 'orders.status.cancelled', label: 'إلغاء الطلبية'),
      ],
    ),
    PermissionGroup(
      title: 'العملاء',
      permissions: [PermissionOption(name: 'customers.view', label: 'عرض العملاء')],
    ),
  ];

  group('what the UI may offer', () {
    test('every flag is the server\'s answer, never derived from the name here', () {
      // Arrange — a role whose name says «admin» but whose flags say otherwise. The app must
      // follow the flags: re-deriving policy from the name is how a button ends up enabled and
      // answering 403.
      final json = roleJson({
        'name': 'admin',
        'grants_everything': false,
        'can_be_renamed': true,
        'can_edit_permissions': true,
      });

      // Act
      final role = Role.fromJson(json);

      // Assert
      expect(role.grantsEverything, isFalse);
      expect(role.canBeRenamed, isTrue);
      expect(role.canEditPermissions, isTrue);
    });

    test('the administrator grants everything while holding no permission rows', () {
      // Arrange — its access is a gate rule, so the list really is empty and that is not a bug.
      final json = roleJson({
        'name': 'admin',
        'label': 'مدير',
        'grants_everything': true,
        'can_be_renamed': false,
        'can_edit_permissions': false,
        'permissions': <Map<String, dynamic>>[],
      });

      // Act
      final role = Role.fromJson(json);

      // Assert
      expect(role.grantsEverything, isTrue);
      expect(role.hasPermissions, isFalse);
      expect(role.canEditPermissions, isFalse);
    });
  });

  group('isDeletable', () {
    test('a role nobody holds and the code does not reference can go', () {
      // Arrange
      final role = Role.fromJson(
        roleJson({'is_system': false, 'can_be_deleted': true, 'users_count': 0}),
      );

      // Act
      final deletable = role.isDeletable;

      // Assert
      expect(deletable, isTrue);
    });

    test('a role somebody still holds cannot, even though the code does not reference it', () {
      // Arrange — two separate reasons to refuse, and this is the one that goes away when the
      // role is taken off people.
      final role = Role.fromJson(
        roleJson({'is_system': false, 'can_be_deleted': true, 'users_count': 3}),
      );

      // Act
      final deletable = role.isDeletable;

      // Assert
      expect(deletable, isFalse);
      expect(role.isHeld, isTrue);
    });

    test('a role the code references cannot, whether or not anybody holds it', () {
      // Arrange
      final role = Role.fromJson(
        roleJson({'is_system': true, 'can_be_deleted': false, 'users_count': 0}),
      );

      // Act
      final deletable = role.isDeletable;

      // Assert
      expect(deletable, isFalse);
    });
  });

  group('groupHeldPermissions', () {
    test('a flat granted list becomes the catalogue\'s own sections, in its own order', () {
      // Arrange — the whole point of the role screen: two permissions from «الطلبيات» and one
      // from «العملاء» arrive as one undifferentiated list.
      final held = {'customers.view', 'orders.discount', 'orders.view'};

      // Act
      final groups = groupHeldPermissions(held: held, catalogue: catalogue);

      // Assert — catalogue order, not the order they were granted in.
      expect(groups.map((g) => g.title), ['الطلبيات', 'العملاء']);
      expect(groups.first.names, ['orders.view', 'orders.discount']);
      expect(groups.last.names, ['customers.view']);
    });

    test('a section with nothing granted is left out rather than shown empty', () {
      // Arrange — «حالات الطلبيات» has ten permissions and this role holds none of them.
      final held = {'orders.view'};

      // Act
      final groups = groupHeldPermissions(held: held, catalogue: catalogue);

      // Assert
      expect(groups, hasLength(1));
      expect(groups.single.title, 'الطلبيات');
    });

    test('granting nothing produces no sections at all', () {
      // Arrange
      const held = <String>{};

      // Act
      final groups = groupHeldPermissions(held: held, catalogue: catalogue);

      // Assert — the screen has its own thing to say about this, and an empty list is how it
      // knows to say it.
      expect(groups, isEmpty);
    });

    test('a permission this build has never heard of is shown, not silently dropped', () {
      // Arrange — the server is ahead of the app. Dropping the name would hide exactly the fact
      // worth knowing: that the role grants something this screen cannot describe.
      final held = {'orders.view', 'warehouse.audit'};

      // Act
      final groups = groupHeldPermissions(held: held, catalogue: catalogue);

      // Assert
      expect(groups.map((g) => g.title), ['الطلبيات', 'صلاحيات أخرى']);
      expect(groups.last.names, ['warehouse.audit']);
      // No Arabic to show for it, so the machine name stands in rather than a blank row.
      expect(groups.last.permissions.single.label, 'warehouse.audit');
    });

    test('an unreachable catalogue still lists everything the role grants', () {
      // Arrange — the role loaded and the catalogue did not. The permissions are the answer the
      // user came for; losing them to protect a subheading would be the wrong trade.
      final held = {'orders.view', 'customers.view'};

      // Act
      final groups = groupHeldPermissions(held: held, catalogue: const []);

      // Assert
      expect(groups, hasLength(1));
      expect(groups.single.title, 'صلاحيات أخرى');
      expect(groups.single.names, ['customers.view', 'orders.view']);
    });
  });
}
