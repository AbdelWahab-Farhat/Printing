# Docs

Every design document in this repository, **one folder per feature**. A folder holds everything
written about that feature — the specification, the backend changes, and the Flutter integration —
so a feature is read in one place rather than hunted for by filename.

Two files sit outside the feature folders because they belong to no single feature:

| File | What it is |
|---|---|
| [BACKLOG.md](BACKLOG.md) | Everything deliberately deferred, each item with **why** and where to resume. |
| `openapi.json` | The generated OpenAPI 3.1 spec. Not hand-written — see [../README.md](../README.md). |

Naming: folders are lowercase kebab-case; documents keep their `UPPER-KEBAB.md` names.
A document that plans the app side of an already-built API ends in `-FRONTEND-INTEGRATION.md`.

---

## [accounting/](accounting/)

| Document | |
|---|---|
| [ACCOUNTING-DESIGN.md](accounting/ACCOUNTING-DESIGN.md) | المحاسبة — دفتر الأستاذ المزدوج. **مقترح** ينتظر أجوبة §١١؛ الفرع `Accounting`. |

## [audit/](audit/)

| Document | |
|---|---|
| [AUDIT-VALUE-LABELS.md](audit/AUDIT-VALUE-LABELS.md) | تعريب القيم في سجلّ التغييرات — الأسماء عُرِّبت، والقيم لم تُعرَّب بعد. |

## [business-fields/](business-fields/)

| Document | |
|---|---|
| [BUSINESS-FIELDS-DESIGN.md](business-fields/BUSINESS-FIELDS-DESIGN.md) | مجالات العمل — الجداول والـ API والصلاحيات والشاشة. **مُنفَّذ.** |

## [comments/](comments/)

| Document | |
|---|---|
| [GENERAL-COMMENTS.md](comments/GENERAL-COMMENTS.md) | الملاحظات مُعمَّمة — `commentable_type`/`commentable_id` وصلاحية واحدة. |
| [CUSTOMER-COMMENTS.md](comments/CUSTOMER-COMMENTS.md) | القرار الأصلي: ملاحظات الموظفين على العميل. |

## [costing/](costing/)

| Document | |
|---|---|
| [COST-TRACKING-UNIT-CONVERSION.md](costing/COST-TRACKING-UNIT-CONVERSION.md) | Cost tracking, units of measurement, order fulfilment. **Implemented.** |
| [PROFIT-AND-LOSS-COST-TRACKING.md](costing/PROFIT-AND-LOSS-COST-TRACKING.md) | P&L, batch inventory costing, manufacturing job costing. **Implemented.** |

## [customers/](customers/)

| Document | |
|---|---|
| [CUSTOMER-SHOP-LOCATION-DESIGN.md](customers/CUSTOMER-SHOP-LOCATION-DESIGN.md) | موقع المحل: مدينة ومنطقة بدل الإحداثيات. **مُنفَّذ.** |
| [CUSTOMER-ORDERS-SECTION.md](customers/CUSTOMER-ORDERS-SECTION.md) | طلبيات العميل على شاشة العميل. |
| [CUSTOMERS-ACTIVITY-FILTER.md](customers/CUSTOMERS-ACTIVITY-FILTER.md) | تصفية شاشة العملاء حسب الطلبيات — «بمن نتّصل؟». |

## [employees/](employees/)

| Document | |
|---|---|
| [EMPLOYEE-DETAIL-DESIGN.md](employees/EMPLOYEE-DETAIL-DESIGN.md) | شاشة تفاصيل الموظف — التعديل وإعادة التعيين والإيقاف. |

## [inventory/](inventory/)

| Document | |
|---|---|
| [STOCK-ITEMS.md](inventory/STOCK-ITEMS.md) | Stock items and materials — what changed, and what the app has to do. |
| [INVENTORY-STOCK-SCREEN.md](inventory/INVENTORY-STOCK-SCREEN.md) | شاشة الأرصدة — عرض الأرقام والإحصائيات. |
| [INVENTORY-STOCK-GROUPED-BY-PRODUCT.md](inventory/INVENTORY-STOCK-GROUPED-BY-PRODUCT.md) | شاشة الأرصدة — تجميع المقاسات تحت منتجها. |
| [STOCK-ITEM-LEDGER-SCREEN.md](inventory/STOCK-ITEM-LEDGER-SCREEN.md) | شاشة المادة — سجل الحركات كدفتر أستاذ. |
| [STOCK-COST-FROM-INVENTORY.md](inventory/STOCK-COST-FROM-INVENTORY.md) | Setting stock cost from inventory. Backend built; **app not wired up.** |
| [STOCK-COST-FROM-INVENTORY-FRONTEND-INTEGRATION.md](inventory/STOCK-COST-FROM-INVENTORY-FRONTEND-INTEGRATION.md) | The plan for the app side of the above. **Not started.** |
| [STOCK-UNIT-COST-ON-ENTRY.md](inventory/STOCK-UNIT-COST-ON-ENTRY.md) | تكلفة الوحدة عند إدخال كمية إلى المخزون. **مُنفَّذ.** |
| [STOCK-UNIT-AND-READY-DEDUCTION-BACKEND-CHANGES.md](inventory/STOCK-UNIT-AND-READY-DEDUCTION-BACKEND-CHANGES.md) | Settable stock unit, fulfilment moved to «جاهزة» — backend. |
| [STOCK-UNIT-AND-READY-DEDUCTION-FRONTEND-INTEGRATION.md](inventory/STOCK-UNIT-AND-READY-DEDUCTION-FRONTEND-INTEGRATION.md) | The same change in the Flutter app. |

## [nawris/](nawris/)

| Document | |
|---|---|
| [NAWRIS-INTEGRATION.md](nawris/NAWRIS-INTEGRATION.md) | Nawris carrier integration — the design. |
| [NAWRIS-CHANGES.md](nawris/NAWRIS-CHANGES.md) | What actually changed: parcels, webhooks, carrier settlement. |
| [NAWRIS-FRONTEND-INTEGRATION.md](nawris/NAWRIS-FRONTEND-INTEGRATION.md) | Connecting the Flutter app to it. |

## [orders/](orders/)

| Document | |
|---|---|
| [ORDERS-DESIGN.md](orders/ORDERS-DESIGN.md) | الطلبيات — تصميم آلة الحالات. **كل القرارات محسومة.** |
| [ORDERS-STATUS-FLOW.md](orders/ORDERS-STATUS-FLOW.md) | شاشة تغيير الحالة — حقول يقرّرها الخادم. **مُنفَّذ.** |
| [ORDERS-SHORTAGE-AND-LINES.md](orders/ORDERS-SHORTAGE-AND-LINES.md) | النواقص تنقص الفاتورة · وبندٌ واحد لكل مقاس. |
| [NEW-ORDER-DESIGN.md](orders/NEW-ORDER-DESIGN.md) | طلبية جديدة — من داخل العميل. **مُنفَّذ.** |
| [ORDER-DETAIL-HEADER-DESIGN.md](orders/ORDER-DETAIL-HEADER-DESIGN.md) | رأس شاشة الطلبية — Sliver واحد ملوّن بدل أربع بطاقات. |
| [ORDER-ITEM-PRODUCT-CARD.md](orders/ORDER-ITEM-PRODUCT-CARD.md) | The product's card on an order line. **Implemented.** |
| [ORDER-INVOICE-MESSAGE.md](orders/ORDER-INVOICE-MESSAGE.md) | نسخ الفاتورة ومشاركتها. |
| [ORDER-UNIT-COST-DISPLAY.md](orders/ORDER-UNIT-COST-DISPLAY.md) | عرض تكلفة الوحدة على بند الطلبية — رقم مشتقّ، بلا هجرة. |
| [ORDER-ADDITIONAL-COST-BACKEND-CHANGES.md](orders/ORDER-ADDITIONAL-COST-BACKEND-CHANGES.md) | Additional cost on an order — backend. |
| [ORDER-ADDITIONAL-COST-FRONTEND-INTEGRATION.md](orders/ORDER-ADDITIONAL-COST-FRONTEND-INTEGRATION.md) | The same charge, read and set in the app. |
| [READY-DEDUCTION-PER-LINE.md](orders/READY-DEDUCTION-PER-LINE.md) | الكمية المخصومة — تُسأل عند «جاهزة» لا عند الإنشاء. |

## [outsourced-products/](outsourced-products/)

| Document | |
|---|---|
| [OUTSOURCED-PRODUCTS.md](outsourced-products/OUTSOURCED-PRODUCTS.md) | وسيط — products a vendor makes for us. |
| [OUTSOURCED-PRODUCTS-FRONTEND-INTEGRATION.md](outsourced-products/OUTSOURCED-PRODUCTS-FRONTEND-INTEGRATION.md) | Connecting the Flutter app to it. |

## [payments/](payments/)

| Document | |
|---|---|
| [PAYMENTS-DESIGN.md](payments/PAYMENTS-DESIGN.md) | مدفوعات الطلبية — الجدول والـ API والصلاحيات والشاشة. **مُنفَّذة.** |
| [PAYMENT-AT-STATUS-CHANGE.md](payments/PAYMENT-AT-STATUS-CHANGE.md) | المبلغ المقبوض يُسأل في شاشة تغيير الحالة ويُسجَّل دفعةً. |

## [products/](products/)

| Document | |
|---|---|
| [PRODUCT-CATEGORIES.md](products/PRODUCT-CATEGORIES.md) | تصنيفات المنتجات — أكياس، علب، ستيكرات. |
| [PRODUCT-IMAGE-REQUIRED-DESIGN.md](products/PRODUCT-IMAGE-REQUIRED-DESIGN.md) | صورة المنتج — قاعدة إلزامية. |
| [PRODUCT-IMAGES-SCREEN-DESIGN.md](products/PRODUCT-IMAGES-SCREEN-DESIGN.md) | صور المنتج — شاشة مستقلة لإدارتها. **مُنفَّذ.** |
| [LINK-VARIATIONS-FROM-MATERIAL.md](products/LINK-VARIATIONS-FROM-MATERIAL.md) | ربط المقاسات من المادة — spec, and what it costs. |

## [purchase-orders/](purchase-orders/)

| Document | |
|---|---|
| [PURCHASE-ORDERS-DESIGN.md](purchase-orders/PURCHASE-ORDERS-DESIGN.md) | Purchase Orders — backend. **Implemented.** |
| [PURCHASE-ORDERS-FRONTEND-INTEGRATION.md](purchase-orders/PURCHASE-ORDERS-FRONTEND-INTEGRATION.md) | Connecting the Flutter app to it. |
| [PURCHASE-ORDER-ADDITIONAL-COSTS-BACKEND-CHANGES.md](purchase-orders/PURCHASE-ORDER-ADDITIONAL-COSTS-BACKEND-CHANGES.md) | Additional costs & line proportioning — backend. |
| [PURCHASE-ORDER-ADDITIONAL-COSTS-FRONTEND-INTEGRATION.md](purchase-orders/PURCHASE-ORDER-ADDITIONAL-COSTS-FRONTEND-INTEGRATION.md) | The same, in the app. **Implemented.** |

## [vendors/](vendors/)

| Document | |
|---|---|
| [VENDORS-AND-PURCHASE-ORDERS.md](vendors/VENDORS-AND-PURCHASE-ORDERS.md) | الموردون وأوامر الشراء — الجانب الذي كان ناقصاً (التطبيق). |
| [VENDOR-PURCHASE-ORDERS-SECTION.md](vendors/VENDOR-PURCHASE-ORDERS-SECTION.md) | أوامر الشراء على شاشة المورد. |
