/// Every permission the system recognises — the app's whole vocabulary of "may I".
///
/// Open this file and you know, exhaustively, what the app can gate on. That is the point of it
/// existing at all: the alternative is `'products.manage'` typed as a string in ten screens,
/// where a rename is a search and a typo is a silently hidden button.
///
/// **It mirrors the backend's `PermissionName.php`, case for case, using the same case names**
/// so the two files diff by eye. That duplication is real and has no compiler watching it, so
/// `permission_contract_test.dart` reads the PHP file and fails when the two lists drift.
///
/// It lives in `core/`, not in `features/auth/`, so a products screen never imports the auth
/// feature merely to name a string.
///
/// **Adding one is a code change on both sides**, and deliberately so: a permission is only real
/// because something checks for it, so a permission nobody checks is a checkbox that lies.
///
/// The three greps that make this layer knowable:
///
/// ```text
/// lib/core/permissions/app_permission.dart   every permission that exists
/// grep -rn "AppPermission\." lib/            every place the app gates on one
/// grep -rn "Session>().isAdmin" lib/         must match only the two staff-creation gates
/// ```
///
/// The third is the one that matters: anything else matching it is a second permission system
/// starting. It is **not zero**, and that is deliberate — creating a staff account is
/// administrators-only *for now*, and the server enforces it with a gate ability rather than a
/// permission, so that it cannot be ticked onto a role. There is no case here to ask for,
/// because there is no permission. See `Session.isAdmin`; the day it is delegated, a case
/// arrives here and those two call sites become `can(...)`.
enum AppPermission {
  // Access management
  viewUsers('users.view', 'عرض المستخدمين'),
  manageUsers('users.manage', 'إدارة المستخدمين وأدوارهم'),
  manageRoles('roles.manage', 'إدارة الأدوار والصلاحيات'),

  // Customers
  viewCustomers('customers.view', 'عرض العملاء'),
  manageCustomers('customers.manage', 'إضافة وتعديل العملاء'),

  // مجالات العمل — what a customer's shop sells. Reading is granted to every role, because
  // the customer form cannot be filled in without the list; curating the list is the rare job.
  viewBusinessFields('business_fields.view', 'عرض مجالات العمل'),
  manageBusinessFields('business_fields.manage', 'إضافة وتعديل مجالات العمل'),

  // Catalogue
  viewProducts('products.view', 'عرض المنتجات والأسعار'),
  manageProducts('products.manage', 'إضافة وتعديل المنتجات والأسعار'),

  // Delivery map — cities and regions share one pair; a region is never administered by
  // somebody who is not also administering its city.
  viewDeliveryLocations('cities.view', 'عرض مدن ومناطق التوصيل'),
  manageDeliveryLocations('cities.manage', 'إضافة وتعديل مدن ومناطق التوصيل'),

  // Who carries the parcels. Its own pair: agreeing rates with a carrier is not the same job as
  // maintaining the list of neighbourhoods.
  viewShippingCompanies('shipping_companies.view', 'عرض شركات التوصيل'),
  manageShippingCompanies('shipping_companies.manage', 'إضافة وتعديل شركات التوصيل'),

  // Orders. One permission per status the workflow can move *into*, so the business composes
  // a designer, a printer and a delivery coordinator out of this list without any of those
  // jobs being named in code. The two dispatch statuses share one permission on purpose; the
  // three returns stay separate, because a clerk does choose which one happened.
  viewOrders('orders.view', 'عرض الطلبيات'),
  manageOrders('orders.manage', 'إضافة وتعديل الطلبيات'),
  discountOrders('orders.discount', 'منح خصم على الطلبية'),
  manageOrderDesigns('orders.designs.manage', 'إدارة تصاميم الطلبية واعتمادها'),
  moveOrderToDesigning(
    'orders.status.designing',
    'تحويل الطلبية إلى قيد التصميم',
  ),
  moveOrderToPrinting(
    'orders.status.printing',
    'تحويل الطلبية إلى قيد الطباعة',
  ),
  moveOrderToReady('orders.status.ready', 'تحويل الطلبية إلى جاهزة'),
  moveOrderToShortage('orders.status.shortage', 'تحويل الطلبية إلى نواقص'),
  dispatchOrders(
    'orders.status.dispatch',
    'تسليم الطلبية للتوصيل أو للاستلام من المكتب',
  ),
  markOrdersDelivered('orders.status.delivered', 'تأكيد استلام العميل للطلبية'),
  settleOrders('orders.status.settled', 'تسوية مبلغ الطلبية'),
  recordCourierReturn(
    'orders.status.returned_courier',
    'تسجيل راجع لدى المندوب',
  ),
  recordCarrierReturn(
    'orders.status.returned_carrier',
    'تسجيل راجع لدى شركة التوصيل',
  ),
  recordOfficeReturn('orders.status.returned_office', 'تسجيل راجع مكتب'),
  resendOrders('orders.status.resend', 'إعادة إرسال طلبية راجعة'),
  cancelOrders('orders.status.cancelled', 'إلغاء الطلبية'),

  // The audit trail. One permission, not a pair: nothing writes to it by hand.
  viewActivityLogs('logs.view', 'عرض سجل النشاطات');

  const AppPermission(this.wire, this.label);

  /// Exactly the string the API sends and the route's `can:` middleware names.
  final String wire;

  /// Arabic, for a screen that lists permissions to a person. Never compared against anything.
  final String label;
}
