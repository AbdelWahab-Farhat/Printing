<?php

declare(strict_types=1);

namespace App\Domain\Audit;

use App\Domain\Audit\Enums\AuditSubject;

/**
 * What to call each column in a history screen.
 *
 * A change is stored as the column that moved — `page_url`, `min_order_quantity` — because that
 * is what actually changed, and a log that stored a translated name would be a log that reworded
 * itself the day somebody edited a string. But `page_url` is not a thing anybody in a printing
 * shop in Tripoli has ever heard of, so the screen showing it was a screen of database keys.
 *
 * **The dictionary belongs here, on the side that owns the schema.** The alternative was a map
 * inside the Flutter app, and that one is wrong the first morning somebody adds a column: the
 * server would send it, the phone would have no entry, and there is no build that fails. Sent
 * with the entry, an unlabelled column is unlabelled everywhere at once — and
 * `AuditAttributeLabelsTest` reads the real tables and fails before it can ship.
 *
 * A column with no entry is not an error at read time. The client falls back to the raw name,
 * which is exactly what the screen showed before this file existed.
 */
final class AuditAttributeLabels
{
    /**
     * Columns that mean the same thing wherever they appear.
     *
     * `name` is deliberately **not** here: «اسم العميل» and «اسم المحل» sit in the same list on
     * the customer's screen, and one «الاسم» twice would be the ambiguity this file exists to
     * remove.
     *
     * @var array<string, string>
     */
    private const SHARED = [
        'code' => 'الكود',
        'phone' => 'رقم الهاتف',
        'notes' => 'ملاحظات',
        'is_active' => 'مفعّل',
        'sort_order' => 'الترتيب',
        'status' => 'الحالة',
        'latitude' => 'خط العرض',
        'longitude' => 'خط الطول',
        'darb_branch' => 'فرع درب',
        'fulfilment_type' => 'طريقة الاستلام',
        'pricing_unit' => 'وحدة التسعير',
        'delivery_price' => 'سعر التوصيل',

        // The warehouse and money vocabulary, which reads the same on a purchase order, an
        // arrival, a batch and a movement — the whole point of this list. Naming them per
        // subject would be the same word written nine times, and nine chances to differ.
        'quantity' => 'الكمية',
        'unit' => 'الوحدة',
        'unit_cost' => 'تكلفة الوحدة',
        'total_cost' => 'إجمالي التكلفة',
        'amount' => 'المبلغ',
        'cost_type' => 'نوع التكلفة',
        'warehouse_id' => 'المخزن',
        'vendor_id' => 'المورد',
        'stock_item_id' => 'المادة',
        // On a product it is «what this is made of», on a stock item «which material this is a
        // size of» — near enough the same sentence that one word serves both.
        'stock_item_group_id' => 'التصنيف',
        'product_variant_id' => 'المقاس',
        'order_id' => 'الطلبية',
        'recorded_by' => 'سجّلها',

        // The media layer, which is the same five columns on every model that stores a file.
        //
        // Named here and drawn nowhere: all but `original_filename` are stripped from the entry
        // by {@see AuditHiddenAttributes} before it is sent, because where the bytes are kept is
        // not what anybody opens a history to find out. The names stay because the columns are
        // still logged — the label is what the day somebody goes looking in `activity_log`
        // needs, and `AuditAttributeLabelsTest` asks every loggable column for one.
        'disk' => 'مكان التخزين',
        'path' => 'مسار الملف',
        'original_filename' => 'اسم الملف',
        'mime_type' => 'نوع الملف',
        'size_bytes' => 'حجم الملف',
        'checksum' => 'بصمة الملف',
        'width_px' => 'العرض بالبكسل',
        'height_px' => 'الارتفاع بالبكسل',
    ];

    /**
     * Keyed by {@see AuditSubject::value}. Wins over {@see SHARED} where both name a column.
     *
     * @var array<string, array<string, string>>
     */
    private const PER_SUBJECT = [
        'user' => [
            'name' => 'الاسم',
            'email' => 'البريد الإلكتروني',
            'email_verified_at' => 'تاريخ توثيق البريد',
            'employee_code' => 'الرقم الوظيفي',
            'salary' => 'الراتب',
        ],
        'role' => [
            'name' => 'اسم الدور',
            'guard_name' => 'نطاق الصلاحية',
        ],

        'customer' => [
            'name' => 'اسم العميل',
        ],
        'customer_shop' => [
            'customer_id' => 'العميل',
            'name' => 'اسم المحل',
            'city_id' => 'المدينة',
            'region_id' => 'المنطقة',
            'page_url' => 'رابط الصفحة',
            'business_field_id' => 'مجال العمل',
        ],
        'customer_design' => [
            'customer_id' => 'العميل',
            'kind' => 'نوع التصميم',
            'label' => 'اسم التصميم',
            // Set by an approval and by nothing else. Null on a design an employee uploaded by
            // hand, which is what those rows are.
            'design_ticket_id' => 'تذكرة التصميم',
            'designer_user_id' => 'المصمم',
            'approved_at' => 'تاريخ الاعتماد',
        ],
        'comment' => [
            'commentable_type' => 'نوع السجل',
            'commentable_id' => 'السجل',
            'user_id' => 'المستخدم',
            'body' => 'نص الملاحظة',
            'edited_at' => 'تاريخ التعديل',
        ],
        'business_field' => [
            'name' => 'اسم مجال العمل',
        ],

        'product' => [
            'name' => 'اسم المنتج',
            'slug' => 'المعرّف',
            'description' => 'الوصف',
            'features' => 'المزايا',
            'pricing_mode' => 'طريقة التسعير',
            'min_order_quantity' => 'أقل كمية للطلب',
            // «تصنيف المنتج» while a `category` column stood beside it; the word is free now.
            'product_category_id' => 'التصنيف',
        ],
        'product_category' => [
            'name' => 'اسم التصنيف',
            'description' => 'الوصف',
            'parent_id' => 'التصنيف الرئيسي',
            // Worth a history entry more than most: changing it changes the road every order
            // taken under this heading walks from that moment — see `ResolveOrderFlow`.
            'production_mode' => 'طريقة التنفيذ',
            // Three-state on purpose: null inherits from the parent heading, so «فارغ» in a
            // history entry means «كما الأب» rather than «لا».
            'is_investable' => 'قابل للاستثمار',
            // Four columns for one picture, and all four are read the same way by somebody
            // scanning a history: «تغيّرت الصورة». Naming them separately is what stops the
            // screen printing `image_path` at them.
            'image_disk' => 'قرص صورة التصنيف',
            'image_path' => 'مسار صورة التصنيف',
            'image_width_px' => 'عرض الصورة (بكسل)',
            'image_height_px' => 'ارتفاع الصورة (بكسل)',
        ],
        'product_variant' => [
            'product_id' => 'المنتج',
            'label' => 'المقاس',
            'width_cm' => 'العرض (سم)',
            'height_cm' => 'الارتفاع (سم)',
            // «من رفع التكلفة؟» is the question this history will be asked, and the answer moves
            // the margin on every وسيط order taken afterwards — see OUTSOURCED-PRODUCTS.md §6.
            'cost_price' => 'سعر التكلفة',
        ],
        // The material a family of shelves is made of. Renaming it renames every size of it, so
        // «اسم التصنيف» is the entry somebody scanning a history will see most often.
        'stock_item_group' => [
            'name' => 'اسم التصنيف',
            'default_unit' => 'وحدة التخزين الافتراضية',
            'description' => 'الوصف',
        ],
        // The shelf itself. `name` and the two dimensions are its own words rather than the
        // shared ones above, because «الاسم» on a stock item means the material — «كيس شحن» —
        // and the size beside it is what makes the row a shelf rather than a category.
        //
        // **`unit` is deliberately absent**, even though it is the most important column here.
        // The shared list above already names it «الوحدة», and a per-subject override would make
        // the word differ by one row — which is precisely what stops `AuditAttributeLabelsTest`
        // treating it as shared, and it would then be read as a claim that every *other* subject
        // has a `unit` column too. Same word everywhere, or it is not shared vocabulary.
        'stock_item' => [
            'name' => 'اسم المادة',
            'width_cm' => 'العرض (سم)',
            'height_cm' => 'الارتفاع (سم)',
            'description' => 'الوصف',
        ],
        'product_price_tier' => [
            'product_variant_id' => 'المقاس',
            'min_quantity' => 'ابتداءً من كمية',
            'unit_price' => 'سعر القطعة',
        ],
        'product_image' => [
            'product_id' => 'المنتج',
            'alt_text' => 'النص البديل',
            'is_primary' => 'الصورة الرئيسية',
        ],

        'city' => [
            'name' => 'اسم المدينة',
            'is_region_required' => 'المنطقة إلزامية',
            'nawris_government_id' => 'محافظة نورس',
        ],
        'region' => [
            'city_id' => 'المدينة',
            'name' => 'اسم المنطقة',
            'nawris_area_id' => 'منطقة نورس',
        ],
        'shipping_company' => [
            'name' => 'اسم شركة التوصيل',
            // **«المبدئية» rather than «الافتراضية»**: this is the company the dispatch form
            // opens on, and at most one live company may hold it — a partial unique index says
            // so, and `UpdateShippingCompany` *moves* the flag rather than duplicating it. So a
            // history screen shows this column changing on two rows for one decision, and the
            // word has to read as «التي تُقترح أولاً» rather than as a setting on one company.
            'is_default' => 'الشركة المبدئية',
        ],

        // The carrier side. Everything Nawris knows a parcel by, in their words and ours — a
        // history screen here is read by whoever is chasing a parcel, not by a developer.
        'nawris_parcel' => [
            // **`code` is deliberately absent**, and the shared «الكود» serves it. Overriding it
            // here would make the word differ by one row, which is exactly what stops
            // `AuditAttributeLabelsTest` treating `code` as shared vocabulary — and every table
            // without one would then be read as a table missing a label. The `unit` note above
            // records the same trap.
            'reference' => 'مرجعنا لدى نورس',
            'bar_code' => 'الباركود',
            'government' => 'المحافظة',
            'area' => 'المنطقة',
            'amount_to_collect' => 'المبلغ المطلوب تحصيله',
            'delivery_price_deducted' => 'أجرة التوصيل المخصومة',
            'collected_amount' => 'المبلغ المحصّل',
            'remote_status_code' => 'رمز حالة نورس',
            'remote_status_text' => 'حالة نورس',
            'shipping_company_id' => 'شركة التوصيل',
            'conflict_raised_at' => 'تاريخ رفع التعارض',
            'conflict_resolved_at' => 'تاريخ إغلاق التعارض',
            'dispatched_at' => 'تاريخ التسليم للناقل',
            'closed_at' => 'تاريخ إغلاق الطرد',
        ],
        'nawris_parcel_order' => [
            'nawris_parcel_id' => 'الطرد',
            'amount_to_collect' => 'حصة الطلبية من التحصيل',
        ],

        'order' => [
            'customer_id' => 'العميل',
            'customer_shop_id' => 'المحل',
            'customer_shop_name' => 'اسم المحل',
            // «من غيّر المورد؟» on a job already sent out is a question somebody will ask, and
            // the pair is stored the way the branch above is — an id and the name at the time.
            'vendor_id' => 'المورد',
            'vendor_name' => 'اسم المورد',
            'city_id' => 'المدينة',
            'city_name' => 'اسم المدينة',
            'region_id' => 'المنطقة',
            'region_name' => 'اسم المنطقة',
            'design_source' => 'مصدر التصميم',
            'is_urgent' => 'مستعجلة',
            'recipient_name' => 'اسم المستلم',
            'recipient_phone' => 'هاتف المستلم',
            'address_details' => 'تفاصيل العنوان',
            'items_total' => 'إجمالي البنود',
            'design_fee' => 'رسوم التصميم',
            'discount' => 'الخصم',
            'additional_cost' => 'التكلفة الإضافية',
            'additional_cost_reason' => 'سبب التكلفة الإضافية',
            'additional_cost_note' => 'ملاحظة التكلفة الإضافية',
            'grand_total' => 'الإجمالي',
            'shipping_company' => 'شركة الشحن',
            'tracking_number' => 'رقم التتبّع',
            'courier_name' => 'اسم المندوب',
            'placed_at' => 'تاريخ الطلب',
            'ready_to_print_at' => 'تاريخ الجاهزية للطباعة',
            'design_started_at' => 'بدء التصميم',
            'printing_started_at' => 'بدء الطباعة',
            'manufacturing_started_at' => 'بدء التصنيع لدى المورد',
            'ready_at' => 'تاريخ الجاهزية',
            // Not a second «تاريخ الجاهزية»: that one says the bags exist, this one says a person
            // told the customer so — a fact from outside this system, here only because somebody
            // recorded it. See ORDER-READY-MESSAGE.md.
            'ready_message_sent_at' => 'تاريخ إرسال رسالة الجاهزية',
            'ready_message_sent_by' => 'مَن أرسل رسالة الجاهزية',
            'dispatched_at' => 'تاريخ الإرسال',
            'delivered_at' => 'تاريخ التسليم',
            'returned_at' => 'تاريخ الإرجاع',
            'cancelled_at' => 'تاريخ الإلغاء',
            'cancellation_reason' => 'سبب الإلغاء',
            'created_by' => 'أنشأها',
            'paid_amount' => 'المدفوع',
            // ── العربون ──────────────────────────────────────────────────────────────────
            // **«المتوقَّع» في الاسم لا زينةٌ فيه.** هذا ما اتُّفق عليه لا مالٌ تحرّك، وسطرٌ في
            // السجل يقرأ «العربون ٢٥٠» بجوار «المدفوع» كان سيُفهم قبضاً. انظر ORDER-DEPOSIT.md §٢.
            'deposit_expected_amount' => 'قيمة العربون المتوقَّعة',
            'deposit_expected_method' => 'وسيلة دفع العربون المتوقَّعة',
            // متى **قيل** إنه دُفع، ومَن قاله. الاسمان مقصودان: الادّعاء غير التأكيد تحته.
            'deposit_paid_at' => 'تاريخ إعلان دفع العربون',
            'deposit_claimed_by' => 'مَن أعلن دفع العربون',
            'deposit_payment_id' => 'قيد العربون في السجل',
            // والتأكيد: شهادة موظفٍ ثانٍ أنّ المال في الحساب فعلاً — ولا يضعها إلا إنسان.
            'is_deposit_received' => 'تأكيد استلام العربون',
            'deposit_confirmed_at' => 'تاريخ تأكيد استلام العربون',
            'deposit_confirmed_by' => 'مَن أكّد استلام العربون',
            'written_off_amount' => 'المشطوب',
            'carrier_settled_amount' => 'المسدَّد لدى الناقل',
            'carrier_collection_recorded_at' => 'تاريخ تسجيل تحصيل الناقل',
            'collected_amount' => 'المبلغ المحصّل',
            'settled_at' => 'تاريخ التسوية',
            // «شركة التوصيل» beside the older free-text `shipping_company`، وهما لا يجتمعان في
            // صفٍّ واحد: أحدهما اسمٌ مكتوب باليد والآخر الشركة المسجّلة عندنا.
            'shipping_company_id' => 'شركة التوصيل',
            'courier_phone' => 'هاتف المندوب',
            'stock_deducted_at' => 'تاريخ خصم المخزون',
            // **Not a second «تاريخ خصم المخزون», and the difference is the whole of why the
            // column exists.** `stock_deducted_at` remembers that goods left this order once and
            // is never cleared; this one says the *archive* is holding goods it gave back, and
            // the restore clears it on the way out. A reader of the history needs to tell the two
            // apart, so the label names the delete rather than the stock.
            'delete_returned_stock_at' => 'تاريخ إعادة المخزون عند الحذف',
            'fulfillment_warehouse_id' => 'مخزن التنفيذ',
            'total_cogs' => 'إجمالي تكلفة البضاعة',
            // Its *values* need no dictionary: `OrderFlow` names itself, and AuditValueLabels
            // translates any enum-cast column whose enum can — so a history row reads «بلا تصميم
            // وطباعة» rather than `no_production`.
            'production_flow' => 'مسار التنفيذ',
        ],
        'order_item' => [
            'order_id' => 'الطلبية',
            'product_id' => 'المنتج',
            'product_name' => 'اسم المنتج',
            'product_variant_id' => 'المقاس',
            'variant_label' => 'اسم المقاس',
            'quantity' => 'الكمية',
            'unit_price' => 'سعر الوحدة',
            'line_total' => 'إجمالي البند',
            'shortage_quantity' => 'الكمية الناقصة',
            // **The same gap in the unit the warehouse counts**, and the one «النواقص» chases:
            // the column above is what comes off the invoice, this is what gets bought and
            // shelved. Empty wherever the two units agree. The distinction `warehouse_quantity`
            // below already draws, worded to match.
            'shortage_warehouse_quantity' => 'الكمية الناقصة من المخزن',
            'undelivered_quantity' => 'الكمية غير المستلمة',
            'undelivered_disposition' => 'مصير الكمية غير المستلمة',
            // In the shelf's unit, not the line's — it is what actually went back on the shelf.
            'restocked_quantity' => 'الكمية المعادة إلى المخزن',
            'warehouse_quantity' => 'الكمية من المخزن',
            // What a vendor charged us for this line, recognised when the job came back — see
            // OUTSOURCED-PRODUCTS.md §6. The rate behind it is `unit_cost`, which the shared
            // dictionary above already names.
            'outsourcing_cost' => 'تكلفة التنفيذ لدى المورد',
            'material_cost' => 'تكلفة الخامات',
            // The two halves سعر السادة split «تكلفة الخامات» into: what the press paid for the
            // plain bags, and what those bags cost the business. Equal on every line that bought
            // nothing off an investor, which is most of them.
            'material_cost_actual' => 'التكلفة الفعلية للخامات',
            'stock_purchased_at' => 'وقت شراء الخامات من الصفقة',
            'labor_cost' => 'تكلفة العمالة',
            'overhead_cost' => 'التكاليف غير المباشرة',
            'cogs' => 'تكلفة البضاعة',
            'fulfillment_stock_movement_id' => 'حركة الصرف المخزني',
        ],
        'order_payment' => [
            'type' => 'نوع الدفعة',
            'method' => 'طريقة الدفع',
            'reference' => 'المرجع',
            'paid_at' => 'تاريخ الدفع',
            // The reversal, not the reversed: a payment is never edited, it is undone by a
            // second row pointing back at the first. See PAYMENTS-DESIGN.md.
            'reverses_payment_id' => 'تعكس الدفعة',
            'receipt_disk' => 'مكان تخزين الإيصال',
            'receipt_path' => 'مسار الإيصال',
            'receipt_original_filename' => 'اسم ملف الإيصال',
            'receipt_size_bytes' => 'حجم الإيصال',
            'receipt_checksum' => 'بصمة الإيصال',
        ],
        'manufacturing_cost_rate' => [
            'product_id' => 'المنتج',
            'rate_per_unit' => 'التكلفة للوحدة',
        ],
        'production_cost_entry' => [
            'order_item_id' => 'بند الطلبية',
            'rate' => 'المعدّل',
            'incurred_at' => 'تاريخ التكلفة',
            'reverses_entry_id' => 'يعكس القيد',
        ],
        'order_design' => [
            'order_id' => 'الطلبية',
            'customer_design_id' => 'التصميم',
            'version' => 'الإصدار',
            'rejection_reason' => 'سبب الرفض',
            'reviewed_at' => 'تاريخ المراجعة',
            'reviewed_by' => 'راجعها',
        ],
        'order_status_transition' => [
            'order_id' => 'الطلبية',
            'from_status' => 'من حالة',
            'to_status' => 'إلى حالة',
            'reason' => 'السبب',
            'user_id' => 'المستخدم',
        ],

        'warehouse' => [
            'name' => 'اسم المخزن',
            'type' => 'نوع المخزن',
            'location' => 'الموقع',
        ],
        'warehouse_stock' => [
            'low_stock_threshold' => 'حدّ التنبيه',
        ],
        'stock_movement' => [
            'from_warehouse_id' => 'من مخزن',
            'to_warehouse_id' => 'إلى مخزن',
            'movement_type' => 'نوع الحركة',
            'reference_id' => 'المرجع',
            'employee_id' => 'الموظف',
            'reverses_movement_id' => 'تعكس الحركة',
            'adjustment_reason' => 'نوع النقص',
        ],
        'stock_batch' => [
            'source_type' => 'مصدر الدفعة',
            'investor_deal_id' => 'صفقة المستثمر',
            // Copied from the deal when the layer opens, and frozen there: what the press pays
            // for a unit of it.
            'printing_sale_price' => 'سعر البيع للطباعة',
            'stock_arrival_item_id' => 'بند التوريد',
            'stock_movement_id' => 'الحركة المخزنية',
            'split_from_batch_id' => 'مقسومة من دفعة',
            'quantity_received' => 'الكمية المستلمة',
            'quantity_remaining' => 'الكمية المتبقية',
            'received_at' => 'تاريخ الاستلام',
            'revalued_at' => 'تاريخ تعديل التكلفة',
        ],
        'stock_batch_consumption' => [
            'stock_batch_id' => 'دفعة التكلفة',
            'stock_movement_id' => 'الحركة المخزنية',
        ],
        'stock_batch_revaluation' => [
            'stock_batch_id' => 'دفعة التكلفة',
            'user_id' => 'المستخدم',
            'old_unit_cost' => 'التكلفة السابقة',
            'new_unit_cost' => 'التكلفة الجديدة',
            'reason' => 'سبب التعديل',
        ],

        'vendor' => [
            'name' => 'اسم المورد',
            'contact_person' => 'مسؤول التواصل',
            'email' => 'البريد الإلكتروني',
            'address' => 'العنوان',
        ],
        'stock_arrival' => [
            'received_by' => 'استلمها',
            'invoice_number' => 'رقم الفاتورة',
            'purchase_order_id' => 'أمر الشراء',
            'reversed_at' => 'تاريخ التراجع',
            'reversed_by' => 'تراجع عنها',
            'reversal_reason' => 'سبب التراجع',
        ],
        'stock_arrival_item' => [
            'stock_arrival_id' => 'التوريد',
            'stock_movement_id' => 'الحركة المخزنية',
        ],

        'purchase_order' => [
            'order_date' => 'تاريخ الأمر',
            'expected_date' => 'التاريخ المتوقع',
            'total_amount' => 'الإجمالي',
            // Part of `total_amount`, not on top of it: every line's final cost already carries
            // its share. The wording says «منها» for that reason, as the detail screen does.
            'total_additional_cost' => 'منها تكاليف إضافية',
        ],
        'purchase_order_item' => [
            'purchase_order_id' => 'أمر الشراء',
            'quantity_ordered' => 'الكمية المطلوبة',
            'quantity_received' => 'الكمية المستلمة',
            // «الأساسية» is what the vendor invoiced; «النهائية» is what the goods landed at
            // once delivery and customs were spread over the lines. A history screen that
            // called both «التكلفة» would show a cost changing for no visible reason.
            'base_total_cost' => 'التكلفة الأساسية',
            'base_unit_cost' => 'تكلفة الوحدة الأساسية',
            'allocated_additional_cost' => 'حصة التكاليف الإضافية',
            'final_unit_cost' => 'تكلفة الوحدة النهائية',
            'final_total_cost' => 'التكلفة النهائية',
        ],
        'purchase_order_additional_cost' => [
            'purchase_order_id' => 'أمر الشراء',
            // Not the shared «الاسم»: this names what the charge was for — التوصيل، الجمارك —
            // which is what the form asks for and what the invoice calls it.
            'name' => 'البيان',
        ],
        'investor' => [
            'name' => 'اسم المستثمر',
            'user_id' => 'حساب الدخول',
            'created_by' => 'أضافه',
        ],
        'investor_deal' => [
            'product_id' => 'المنتج',
            // The order the deal was born from. Empty on one assembled by hand out of several.
            'purchase_order_id' => 'أمر الشراء',
            // Frozen once the deal opens: it is the arrangement the investors agreed to, and
            // moving it afterwards would rewrite what somebody has already been paid against.
            'investor_profit_share_percent' => 'نسبة المستثمرين من الربح',
            // Both derived at funding and frozen with it: what the company put in beyond the
            // investors, and the share of the goods their money bought.
            'company_stake' => 'حصة الشركة',
            'investor_funded_percent' => 'نسبة المستثمرين من البضاعة',
            // Frozen with them, and the term that decides which road this deal earns on: set, the
            // press buys its plain stock at the shelf; null, its investors ride the sale itself.
            'printing_sale_price' => 'سعر بيع السادة للطباعة',
            'opened_on' => 'تاريخ الصفقة',
            'opened_at' => 'وقت الفتح',
            'closed_at' => 'وقت الإغلاق',
            'cancellation_reason' => 'سبب الإلغاء',
            'created_by' => 'أنشأها',
        ],
        'investor_deal_item' => [
            'investor_deal_id' => 'الصفقة',
            'quantity_expected' => 'الكمية المتوقعة',
            'expected_unit_cost' => 'تكلفة الوحدة المتوقعة',
            'expected_unit_price' => 'سعر البيع المتوقع',
        ],
        'investor_deal_share' => [
            'investor_deal_id' => 'الصفقة',
            'investor_id' => 'المستثمر',
            // The subscription the percentage was agreed against — not what arrived, which is a
            // walk of the wallet ledger and is shown beside it rather than merged with it.
            'committed_amount' => 'رأس المال المتعهَّد به',
            'share_percent' => 'النسبة من حصة المستثمرين',
            'joined_at' => 'تاريخ الانضمام',
        ],
        'investor_deal_supply' => [
            'investor_deal_id' => 'الصفقة',
            'source_type' => 'نوع المستند',
            'source_id' => 'رقم المستند',
            // سعر السادة لهذا الرفّ وحده. على السطر لا على الصفقة، لأن الصندوق صفقةٌ واحدةٌ
            // أبداً — وعمودٌ عليه كان سعراً واحداً لكل مادةٍ يملكها ما دام.
            'printing_sale_price' => 'سعر بيع السادة للطباعة',
            'claimed_by' => 'أقرّها',
        ],
        'investor_deal_expense' => [
            'investor_deal_id' => 'الصفقة',
            'kind' => 'نوع المصروف',
            'name' => 'بيان المصروف',
            // The column somebody must be able to see change: a landed cost is already inside
            // the goods, so it is logged and never subtracted a second time.
            'is_landed' => 'داخل تكلفة البضاعة',
            'incurred_on' => 'تاريخ المصروف',
            'source_type' => 'نوع المستند',
            'source_id' => 'رقم المستند',
            'reverses_expense_id' => 'يعكس المصروف',
        ],
        'investor_wallet_entry' => [
            'investor_id' => 'المستثمر',
            'investor_deal_id' => 'الصفقة',
            'type' => 'نوع الحركة',
            'method' => 'طريقة الدفع',
            'reference' => 'المرجع',
            'source_type' => 'نوع المصدر',
            'source_id' => 'رقم المصدر',
            'source_sequence' => 'رقم المحاولة على المصدر',
            'occurred_at' => 'تاريخ الحركة',
            'reverses_entry_id' => 'تعكس الحركة',
            'investment_period_id' => 'الفترة',
        ],
        // ── الصندوق الاستثماري ──────────────────────────────────────────────────────────
        //
        // الفترةُ تُكتب مرّتين في عمرها: يوم تُفتح بما ورثته، ويوم تُقفَل بأرقامها. وكلُّ عمودٍ
        // هنا رقمٌ وُزّع به مالٌ على ناس، فسؤال «من غيّره ومتى» ليس ترفاً.
        'investment_period' => [
            // **ولا `code` ولا `status` هنا.** المشتركُ يسمّيهما، وتجاوزُه بترجمةٍ أخرى يُخرجهما
            // من المشترك كلَّه — فيصير كلُّ جدولٍ بلا `code` مخالفاً، وهو ما يمسكه
            // `AuditAttributeLabelsTest::isSharedColumn()`.
            'starts_on' => 'تبدأ في',
            'ends_on' => 'تنتهي في',
            'subscription_closes_on' => 'يُغلق الاكتتاب في',
            'period_months' => 'مدة الفترة (شهور)',
            'subscription_window_days' => 'نافذة الاكتتاب (أيام)',
            'settlement_months' => 'مدة التسوية (شهور)',
            'capital_lock_months' => 'حبس رأس المال (شهور)',
            'ends_settlement_cycle' => 'تُغلق دورة تسوية',
            'investor_profit_share_percent' => 'نسبة المستثمرين من الربح',
            'opening_stock_cost' => 'البضاعة عند الفتح',
            'opening_cash' => 'النقد عند الفتح',
            'closing_stock_cost' => 'البضاعة عند الإقفال',
            'closing_cash' => 'النقد عند الإقفال',
            'sales_revenue' => 'المبيعات',
            'cost_of_goods_sold' => 'تكلفة المبيعات',
            'cost_damaged' => 'تكلفة الهالك',
            'cost_short' => 'تكلفة العجز',
            'expenses_amount' => 'المصاريف',
            'net_profit' => 'صافي الربح',
            'investors_pool' => 'نصيب المستثمرين',
            'company_share' => 'نصيب الشركة',
            // العلاماتُ المائية: «حتى أين حُسبت» جوابٌ مكتوب لا استنتاجٌ من تواريخ.
            'through_consumption_id' => 'آخر سحب محسوب',
            'through_movement_id' => 'آخر حركة مخزون محسوبة',
            'through_wallet_entry_id' => 'آخر حركة محفظة محسوبة',
            'through_cash_entry_id' => 'آخر حركة خزينة محسوبة',
            'closed_at' => 'تاريخ الإقفال',
            'closed_by' => 'أقفلها',
            'override_reason' => 'سبب التجاوز',
            'overridden_by' => 'من تجاوز',
            'created_by' => 'فتحها',
        ],
        'investment_cash_entry' => [
            'type' => 'نوع الحركة',
            'source_type' => 'نوع المصدر',
            'source_id' => 'رقم المصدر',
            'source_sequence' => 'رقم المحاولة على المصدر',
            'occurred_at' => 'تاريخ الحركة',
            'reverses_entry_id' => 'تعكس الحركة',
        ],
        'investment_unit' => [
            'investor_id' => 'المستثمر',
            'investment_period_id' => 'الفترة',
            'type' => 'نوع الحركة',
            'units' => 'عدد الوحدات',
            'unit_price' => 'سعر الوحدة',
            // ما يجعل «متى يخرج مالي» جواباً لكل دفعةٍ على حدة.
            'locked_until' => 'محبوسة حتى',
            'source_type' => 'نوع المصدر',
            'source_id' => 'رقم المصدر',
            'occurred_at' => 'تاريخ الحركة',
            'reverses_unit_entry_id' => 'تعكس الحركة',
        ],
        'investment_period_share' => [
            'investment_period_id' => 'الفترة',
            'investor_id' => 'المستثمر',
            'units' => 'عدد الوحدات',
            'share_percent' => 'نسبته من الربح',
        ],
        'shortage' => [
            'source' => 'مصدر النقص',
            // **Beside `source`, not instead of it.** That column says who wrote the row down;
            // this says what the shop is out of. A history screen reading «يدوي ← من طلبية» and
            // one reading «حبر ← ورق طباعة» are different corrections.
            'type' => 'نوع النقص',
            'order_item_id' => 'بند الطلبية',
            'customer_id' => 'العميل',
            'product_id' => 'المنتج',
            // The snapshot, not a join — «كيس شحن — ٢٥*٣٥» as it was when the shortage was
            // written. A product renamed since then does not rewrite this row's history.
            'name' => 'الصنف الناقص',
            'required_quantity' => 'الكمية المطلوبة',
            // Both are caches restated from `shortage_supplies` by one action, so a change here
            // is always the consequence of an entry in that ledger rather than somebody typing.
            'supplied_quantity' => 'الكمية التي تم توفيرها',
            'total_paid' => 'إجمالي المدفوع',
            'assigned_to_user_id' => 'الموظف المسؤول',
            'created_by_user_id' => 'سجّله',
            'description' => 'الوصف',
        ],
        'design_ticket' => [
            'customer_id' => 'العميل',
            // The snapshot, not a join — «متجر إكس» as it was when the request was written. A
            // customer renamed since then does not rewrite this row's history, and it is also
            // what lets a designer read the ticket without a grant on customers.
            'customer_name' => 'اسم العميل',
            'order_id' => 'الطلبية',
            'title' => 'عنوان الطلب',
            'description' => 'وصف الطلب',
            'instructions' => 'الملاحظات والتعليمات',
            'requested_by_user_id' => 'طلبها',
            // **Two columns and two different facts**, which is why they are named apart here as
            // well: whom the ticket was addressed to, and who actually took it. A reassignment
            // moves the first and must never look as though it moved the second.
            'assigned_designer_id' => 'المصمم المطلوب',
            'accepted_by_user_id' => 'المصمم المستلِم',
            'accepted_at' => 'وقت قبول الطلب',
            'approved_by_user_id' => 'اعتمد التصميم',
            'completed_at' => 'وقت إغلاق التذكرة',
            'approved_customer_design_id' => 'التصميم المعتمد في حساب الزبون',
            'cancellation_reason' => 'سبب الإلغاء',
        ],
        'design_ticket_file' => [
            'design_ticket_id' => 'التذكرة',
            'kind' => 'نوع الملف',
            'file_kind' => 'صيغة الملف',
            'version' => 'رقم النسخة',
            // The words that make a revision round a conversation rather than a count.
            'review_note' => 'المطلوب تعديله',
            'reviewed_at' => 'وقت المراجعة',
            'reviewed_by' => 'راجعها',
            'uploaded_by_user_id' => 'رفعها',
            'note' => 'ملاحظة المصمم',
        ],
        'shortage_supply' => [
            'shortage_id' => 'النقص',
            'kind' => 'نوع العملية',
            'method' => 'طريقة الدفع',
            'reference' => 'رقم العملية',
            'receipt_disk' => 'قرص الإيصال',
            'receipt_path' => 'مسار الإيصال',
            'receipt_original_filename' => 'اسم ملف الإيصال',
            'receipt_size_bytes' => 'حجم الإيصال',
            'receipt_checksum' => 'بصمة الإيصال',
            // When the goods were got, not when somebody typed it in — `created_at` beside it
            // answers the second question, and the two differ on an entry made the next morning.
            'occurred_on' => 'تاريخ التوفير',
            // `warehouse_id` beside it needs no entry — the shared list above already names it
            // «المخزن», and it means the same thing here as everywhere else.
            'stock_movement_id' => 'الإدخال المخزني',
            'reverses_supply_id' => 'تعكس عملية',
            'recorded_by_user_id' => 'سجّلها',
        ],
        'company_setting' => [
            'investor_profit_share_percent' => 'نسبة المستثمرين من الربح (الافتراضية)',
            // المددُ الأربع. تُنسَخ على صفّ الفترة يوم تُفتح ولا تُقرأ من هنا بعدها — فتغييرُها
            // لا يمسّ فترةً قائمة، وسجلُّ من غيّرها هو ما يفسّر اختلافَ فترتين متجاورتين.
            'investment_period_months' => 'مدة الفترة (شهور)',
            'investment_subscription_window_days' => 'نافذة الاكتتاب (أيام)',
            'investment_settlement_months' => 'مدة التسوية (شهور)',
            'investment_capital_lock_months' => 'حبس رأس المال (شهور)',
            'updated_by' => 'عدّلها',
        ],
        // Only ever an announcement. Notifications as a class are outside the audit trail — see
        // the model — but «اجتماع الساعة ٤» is a deliberate act performed under somebody's name,
        // and the one row that has to outlive the retention prune.
        'notification' => [
            'type' => 'نوع الإشعار',
            'subject_type' => 'نوع السجل',
            'subject_id' => 'رقم السجل',
            'payload' => 'محتوى الإشعار',
            'dedupe_key' => 'مفتاح منع التكرار',
            'causer_id' => 'أرسله',
        ],
    ];

    /**
     * Every label this kind of record has.
     *
     * @return array<string, string>
     */
    public static function for(AuditSubject $subject): array
    {
        return array_merge(self::SHARED, self::PER_SUBJECT[$subject->value] ?? []);
    }

    /**
     * Just the labels for the columns in one entry.
     *
     * Narrowed rather than sent whole: a history page carries fifteen entries, and shipping the
     * order dictionary's forty entries with each of them would be most of the response.
     *
     * @param  list<string>  $attributes
     * @return array<string, string>
     */
    public static function forAttributes(?AuditSubject $subject, array $attributes): array
    {
        if ($subject === null || $attributes === []) {
            return [];
        }

        return array_intersect_key(self::for($subject), array_flip($attributes));
    }
}
