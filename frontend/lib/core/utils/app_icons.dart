import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// One name per idea, two glyphs behind it: Material on Android, Cupertino on iOS.
///
/// An Android user reading a rounded iOS chevron, or an iPhone user reading Material's boxy
/// person icon, both spend a moment deciding what they are looking at. Each platform's own set
/// is the one its owner already knows, so the icon stops being something to read.
///
/// **Screens never name a glyph.** They ask for [AppIcons.customers], and which family answers
/// is settled here — one place to change, and no screen that quietly stayed Material because
/// somebody typed `Icons.` out of habit.
///
/// The decision reads [defaultTargetPlatform] rather than `Platform.isIOS` for two reasons: it
/// compiles on the web, and a test can flip it with `debugDefaultTargetPlatformOverride` to
/// check both families without two devices.
abstract final class AppIcons {
  /// Cupertino for the platforms Apple ships; Material everywhere else.
  static bool get isCupertino =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static IconData _pick(IconData material, IconData cupertino) =>
      isCupertino ? cupertino : material;

  // ── navigation ─────────────────────────────────────────────────────────────
  static IconData get home => _pick(Icons.home_rounded, CupertinoIcons.house_fill);

  static IconData get customers =>
      _pick(Icons.people_alt_rounded, CupertinoIcons.person_2_fill);

  static IconData get warehouse =>
      _pick(Icons.inventory_2_rounded, CupertinoIcons.cube_box_fill);

  /// Who we buy *from*. A storefront rather than a person: a supplier is a business we deal
  /// with, and the same glyph as [customers] would make the two lists look like one.
  static IconData get vendors =>
      _pick(Icons.storefront_rounded, CupertinoIcons.building_2_fill);

  static IconData get addVendor =>
      _pick(Icons.add_business_rounded, CupertinoIcons.building_2_fill);

  /// The paperwork raised against a supplier — a document with a list on it.
  static IconData get purchaseOrders =>
      _pick(Icons.assignment_rounded, CupertinoIcons.doc_text_fill);

  /// Booking a shipment in against that paperwork.
  static IconData get receiveShipment =>
      _pick(Icons.move_to_inbox_rounded, CupertinoIcons.tray_arrow_down_fill);

  static IconData get products =>
      _pick(Icons.shopping_bag_rounded, CupertinoIcons.bag_fill);

  /// A bag carrying the customer's design — مطبوعة.
  ///
  /// The press, not the artwork: [designs] is already a palette, and these two appear on the
  /// same catalogue row. What the badge says is *how this bag was made*.
  static IconData get printedProduct =>
      _pick(Icons.print_rounded, CupertinoIcons.printer_fill);

  /// A bag with nothing on it — سادة. A blank square, so the pair reads as printed-or-not at
  /// badge size, where a second bag glyph would be two of the same shape.
  static IconData get plainProduct =>
      _pick(Icons.crop_din_rounded, CupertinoIcons.square);

  static IconData get menu =>
      _pick(Icons.menu_rounded, CupertinoIcons.line_horizontal_3);

  static IconData get back =>
      _pick(Icons.arrow_back_rounded, CupertinoIcons.back);

  /// Points the way *forward* in reading order, which in an Arabic layout is to the left.
  static IconData get forward =>
      _pick(Icons.chevron_left_rounded, CupertinoIcons.chevron_left);

  /// يفتح ما هو مطويّ تحته، ويطويه. سهمٌ لأسفل ثم لأعلى — والاتجاه هنا لا يقلبه الاتجاه العربي:
  /// المطويّ *تحت* الزر في الحالتين.
  static IconData get expand =>
      _pick(Icons.keyboard_arrow_down_rounded, CupertinoIcons.chevron_down);

  static IconData get collapse =>
      _pick(Icons.keyboard_arrow_up_rounded, CupertinoIcons.chevron_up);

  // ── actions ────────────────────────────────────────────────────────────────
  static IconData get addCustomer =>
      _pick(Icons.person_add_alt_1_rounded, CupertinoIcons.person_add_solid);

  /// A pin on a map. The crosshair on the location picker, and the marker beside a shop.
  static IconData get mapPin =>
      _pick(Icons.location_on_rounded, CupertinoIcons.location_solid);

  static IconData get addProduct =>
      _pick(Icons.add_box_outlined, CupertinoIcons.plus_app);

  /// Taking an order. The bag of [orders] with a plus on it, so the action reads as «one more
  /// of those» rather than as a new thing of its own kind.
  static IconData get addOrder =>
      _pick(Icons.add_shopping_cart_rounded, CupertinoIcons.bag_badge_plus);

  /// A plain "one more of these" — a size, a price break. Not [addProduct], which names a
  /// specific thing to create.
  static IconData get add => _pick(Icons.add_rounded, CupertinoIcons.add);

  /// Removes a row the user added. Distinct from [clear], which empties a field.
  static IconData get delete =>
      _pick(Icons.delete_outline_rounded, CupertinoIcons.delete);

  /// Lets go of a tie between two records without destroying either.
  ///
  /// **A broken chain, never a bin.** «فكّ الربط» is exactly the act of *not* deleting: the
  /// parcel stays, the order stays, and only our claim that they belong together is dropped.
  static IconData get unlink =>
      _pick(Icons.link_off_rounded, CupertinoIcons.link);

  /// A machine-readable name — a slug, a code.
  static IconData get tag => _pick(Icons.tag_rounded, CupertinoIcons.tag);

  static IconData get edit =>
      _pick(Icons.edit_outlined, CupertinoIcons.pencil);

  /// Stops selling to a customer. Never a bin — nothing here is deleted.
  static IconData get deactivate =>
      _pick(Icons.pause_circle_outline_rounded, CupertinoIcons.pause_circle);

  static IconData get activate =>
      _pick(Icons.check_circle_outline_rounded, CupertinoIcons.check_mark_circled);

  /// Moves an order along its route. Two arrows passing, because a status change is a *move*
  /// from one place to another — not [refresh], which fetches the same thing again.
  static IconData get statusChange =>
      _pick(Icons.sync_alt_rounded, CupertinoIcons.arrow_right_arrow_left);

  /// The money for an order, agreed and closed. A note rather than a coin: what is settled is
  /// the amount on the invoice, not a handful of cash.
  static IconData get settled =>
      _pick(Icons.receipt_long_rounded, CupertinoIcons.doc_checkmark);

  /// A returned parcel going out a second time.
  static IconData get resend =>
      _pick(Icons.send_rounded, CupertinoIcons.paperplane);

  /// Money coming in from the customer. Notes, because that is what crosses the counter —
  /// distinct from [settled], which is the invoice being agreed rather than cash changing
  /// hands.
  static IconData get payment =>
      _pick(Icons.payments_outlined, CupertinoIcons.money_dollar_circle);

  /// Money going back to the customer. An arrow turning back on itself, which is the one shape
  /// that reads as "the other direction" without a minus sign somebody could misread as a
  /// delete.
  static IconData get refund =>
      _pick(Icons.undo_rounded, CupertinoIcons.arrow_uturn_left);

  /// Closing a debt nobody is going to collect — «شطب الفرق».
  ///
  /// Money with a line struck through it: the amount was real and is being crossed out, which is
  /// exactly what the entry says. Deliberately neither of its two neighbours — [refund]'s
  /// turning arrow says money went back to the customer, and [reversePayment]'s no-entry sign
  /// says a row was never true. This one says the row is true and the money is not coming.
  static IconData get writeOff =>
      _pick(Icons.money_off_rounded, CupertinoIcons.minus_circle);

  /// Cancelling a ledger entry that should never have been written.
  ///
  /// **Deliberately not [delete].** Nothing is removed — a second entry is written beside the
  /// wrong one — and a bin would promise the opposite of what the button does.
  static IconData get reversePayment =>
      _pick(Icons.block_flipped, CupertinoIcons.nosign);

  /// A record's change log. Every model has one.
  static IconData get history =>
      _pick(Icons.history_rounded, CupertinoIcons.clock);

  /// A customer's artwork — the images and PDFs printed on their bags, as a collection.
  static IconData get designs =>
      _pick(Icons.palette_outlined, CupertinoIcons.paintbrush);

  /// What was written on the record itself — «ملاحظات الطلبية».
  ///
  /// A page with lines on it, not [comments]' speech bubbles: this is one field filled in by
  /// whoever took the order, not a conversation between colleagues about it.
  static IconData get notes =>
      _pick(Icons.sticky_note_2_outlined, CupertinoIcons.doc_plaintext);

  /// What staff have written to each other about a customer.
  ///
  /// A speech bubble, not a note-page: these are things colleagues *say* to one another about
  /// somebody, and a page glyph would read as the customer's own paperwork — which [orders]
  /// already is, on the same screen.
  static IconData get comments =>
      _pick(Icons.forum_outlined, CupertinoIcons.chat_bubble_2);

  // ── choosing a file ────────────────────────────────────────────────────────
  // The three rows of the attachment sheet. Distinct glyphs on purpose: they sit side by side
  // and the icon is what is read, not the label under it.

  /// The system's document browser — Files on iOS, the storage picker on Android.
  static IconData get document =>
      _pick(Icons.description_outlined, CupertinoIcons.doc_text);

  /// The photo library.
  static IconData get photos =>
      _pick(Icons.photo_library_outlined, CupertinoIcons.photo_on_rectangle);

  static IconData get camera =>
      _pick(Icons.photo_camera_outlined, CupertinoIcons.camera);

  /// Promotes a photograph to be the one every other screen draws — «اجعلها الرئيسية».
  ///
  /// An outlined star, because the button is only ever offered on a picture that is *not* the
  /// primary: a filled one would read as a state the tile already has rather than an action.
  /// The primary itself says so in a word, not with a glyph — see the badge on its tile.
  static IconData get makePrimary =>
      _pick(Icons.star_outline_rounded, CupertinoIcons.star);

  /// One design that this app cannot draw itself, so its tile shows this instead of a
  /// thumbnail. Distinct from [document], which is a place to pick *from*.
  static IconData get pdf =>
      _pick(Icons.picture_as_pdf_outlined, CupertinoIcons.doc_richtext);

  /// Hands the file to whatever the phone already opens it with.
  static IconData get openExternal =>
      _pick(Icons.open_in_new_rounded, CupertinoIcons.arrow_up_right_square);

  /// Puts a copy of the file on the phone — Photos, Files, or another app.
  ///
  /// An arrow *down* on Android and the share glyph on iOS, and that is not inconsistency: on
  /// iOS saving a file genuinely is the share sheet, and an iPhone owner looks for the box with
  /// the arrow coming out of it. Naming it for what it does — [download] — lets each platform
  /// draw the control its owner already knows.
  static IconData get download =>
      _pick(Icons.download_rounded, CupertinoIcons.share);

  /// Sends something out of the app through the phone's own sheet — a message, a file.
  ///
  /// It lands on the same iOS glyph as [download], and that is honest rather than a duplicate:
  /// on an iPhone both genuinely *are* the share sheet. Android draws the two apart, because
  /// there saving to Files and sending to WhatsApp are different controls.
  static IconData get share =>
      _pick(Icons.share_rounded, CupertinoIcons.share);

  /// Opens a speed dial. Not [menu], which opens the app's drawer.
  static IconData get more =>
      _pick(Icons.more_horiz_rounded, CupertinoIcons.ellipsis);

  static IconData get close =>
      _pick(Icons.close_rounded, CupertinoIcons.xmark);

  static IconData get copy => _pick(Icons.copy_rounded, CupertinoIcons.doc_on_doc);

  static IconData get refresh =>
      _pick(Icons.refresh_rounded, CupertinoIcons.refresh);

  static IconData get logout =>
      _pick(Icons.logout_rounded, CupertinoIcons.square_arrow_right);

  // ── the things the numbers count ───────────────────────────────────────────
  static IconData get orders =>
      _pick(Icons.receipt_long_rounded, CupertinoIcons.doc_text_fill);

  /// Orders nobody has finished with — «الطلبات الجارية».
  ///
  /// A clock over a list, not [history]'s clock-with-an-arrow: the two sit on the same customer
  /// screen, one opening work in hand and the other opening a change log, and a reader who has
  /// to tell them apart by the label has been given no icon at all.
  static IconData get ordersInProgress =>
      _pick(Icons.pending_actions_rounded, CupertinoIcons.clock_fill);

  /// Orders that reached the customer — «الطلبات المستلمة».
  ///
  /// A filled tick against [activate]'s outlined circle, which is what says «عميل نشِط» a
  /// finger's width above it on the same screen.
  static IconData get ordersReceived =>
      _pick(Icons.task_alt_rounded, CupertinoIcons.checkmark_seal_fill);

  /// Orders nobody will work on and nobody received — «الطلبات الملغاة».
  ///
  /// A struck-through circle rather than a bin: nothing was deleted. The order is on record,
  /// with everything it cost up to the moment it was called off, and a bin over a row that is
  /// still there and still counted would be the wrong promise entirely.
  static IconData get ordersCancelled =>
      _pick(Icons.cancel_outlined, CupertinoIcons.xmark_circle);

  /// How long since a customer last ordered — «منذ شهرين» on a card in the call sheet.
  ///
  /// A bare clock, and deliberately none of the three above it: [orders] would make an elapsed
  /// time look like a quantity of orders in the slot it stands in, [ordersInProgress] means work
  /// in hand, and [history] means a change log. What this one measures is silence.
  static IconData get elapsed =>
      _pick(Icons.schedule_rounded, CupertinoIcons.clock);

  static IconData get today => _pick(Icons.today_rounded, CupertinoIcons.calendar_today);

  static IconData get month =>
      _pick(Icons.calendar_month_rounded, CupertinoIcons.calendar);

  static IconData get city =>
      _pick(Icons.location_city_rounded, CupertinoIcons.building_2_fill);

  /// مجال العمل — the trade a customer's shop is in. A shopfront, because that is what the
  /// field describes: the kind of place, not the place itself ([mapPin]) and not the customer
  /// who owns it ([customers]).
  ///
  /// It shares iOS's office building with [city] and [officePickup], which is a duplicate on
  /// paper and never on screen: no view draws this one beside either of those.
  static IconData get businessField =>
      _pick(Icons.storefront_outlined, CupertinoIcons.building_2_fill);

  /// التصنيف — a heading in the catalogue: أكياس, علب وكراتين, ستيكرات.
  ///
  /// Folders, because that is what a category *does*: it is where the products are filed. Not
  /// [products]'s bag, which is one of the things inside it, and not [tag], which names the
  /// machine-readable slug on a single product.
  static IconData get productCategory =>
      _pick(Icons.folder_copy_outlined, CupertinoIcons.folder);

  /// The handle a row is dragged by. Stacked lines, which is what every list on both platforms
  /// uses for «امسك هنا واسحب» — not [menu]'s three lines, which open a drawer.
  static IconData get reorder =>
      _pick(Icons.drag_indicator_rounded, CupertinoIcons.line_horizontal_3_decrease);

  /// A branch the customer walks into and collects from.
  ///
  /// On the delivery map this sits in the same list as [mapPin], and the glyph is the only
  /// thing that says *«we bring it to you»* against *«you come to us»* before the price is
  /// read — so what it must contrast with is the pin, not [city].
  ///
  /// Apple ships no storefront, so iOS gets the office building it does ship — the same glyph
  /// [city] uses there, which is a duplicate on paper and never on screen: no view draws both,
  /// and the one that draws this one draws pins beside it.
  static IconData get officePickup =>
      _pick(Icons.storefront_rounded, CupertinoIcons.building_2_fill);

  /// معدلات تكلفة التصنيع — what an hour of labour, a machine and the overhead are charged at.
  ///
  /// A price tag with an arrow rather than [payment]'s notes: this is not money crossing the
  /// counter, it is the standing figure an order is later costed against. The distinction earns
  /// its own glyph because both rows sit in the same drawer, and the first drafts of that drawer
  /// gave this one and الأرباح والخسائر the same money icon — two adjacent rows a reader had to
  /// tell apart by their labels alone.
  static IconData get manufacturingCostRates =>
      _pick(Icons.price_change_outlined, CupertinoIcons.money_dollar);

  /// «قيد التصنيع» — the job is on an outside vendor's bench. A workshop tool rather than
  /// [printedProduct]'s press: the press is ours and this is not, and the two statuses sit on
  /// different roads. Deliberately not [vendors]' storefront either — that glyph names *who*,
  /// and a status chip is about *where the work is*.
  static IconData get manufacturing =>
      _pick(Icons.precision_manufacturing_outlined, CupertinoIcons.hammer);

  /// A report read for its figures rather than its records — الأرباح والخسائر today.
  ///
  /// Deliberately not [settled]: Material draws that as the same receipt the الطلبات tab uses,
  /// and a report is not a document the shop issued.
  static IconData get report =>
      _pick(Icons.analytics_outlined, CupertinoIcons.chart_bar);

  // ── حالات الطلبية ──────────────────────────────────────────────────────────
  // One glyph per status, and no two alike. These are read in a list, at a glance, by somebody
  // looking for «الرواجع» among thirty rows — a shape shared by two states is a shape that
  // sends them back to the words, which is the work the icon was put there to save.

  /// «جديدة» — an order taken and not yet touched by anyone.
  static IconData get statusNew =>
      _pick(Icons.fiber_new_rounded, CupertinoIcons.sparkles);

  /// «جاري التوصيل» — out on the road with the driver.
  static IconData get outForDelivery =>
      _pick(Icons.local_shipping_rounded, CupertinoIcons.car_detailed);

  /// «راجع لدى المندوب» — turned back on the road; our own man still has it.
  static IconData get returnedCourier =>
      _pick(Icons.u_turn_left_rounded, CupertinoIcons.arrow_uturn_left);

  /// «راجع لدى شركة التوصيل» — sitting at the carrier's depot, out of our hands.
  ///
  /// The turn of [returnedCourier] inside a ring: the same event, a step further away.
  static IconData get returnedCarrier =>
      _pick(Icons.assignment_return_rounded, CupertinoIcons.arrow_uturn_left_circle);

  /// «راجع مكتب» — back on our own counter. A tray, because that is where it physically is:
  /// the parcel came home, and somebody has to decide what happens to it.
  static IconData get returnedOffice =>
      _pick(Icons.move_to_inbox_rounded, CupertinoIcons.tray_arrow_down_fill);

  /// A status this build has never heard of. A question mark says exactly that — [more]'s
  /// ellipsis said «there is more here», which is a different, and untrue, claim.
  static IconData get unknownStatus =>
      _pick(Icons.help_outline_rounded, CupertinoIcons.question_circle);

  // ── who works here, and what they may do ───────────────────────────────────

  /// Staff accounts. Deliberately not [customers]: the two are both "a group of people", and
  /// the drawer lists them four rows apart, so they must not be the same glyph.
  static IconData get employees =>
      _pick(Icons.badge_outlined, CupertinoIcons.person_crop_rectangle);

  /// Registering a colleague. Distinct from [addCustomer]: the two forms sit one drawer apart
  /// and both add a person, so the glyph has to say *which* person.
  static IconData get addEmployee =>
      _pick(Icons.person_add_alt_rounded, CupertinoIcons.person_badge_plus_fill);

  /// A named bundle of permissions. A key, because that is what a role is: what it opens.
  static IconData get roles =>
      _pick(Icons.vpn_key_outlined, CupertinoIcons.lock_shield);

  /// The one role whose access is unlimited. A filled shield against [roles]' outline, so the
  /// difference between «كل الصلاحيات» and a bundle somebody assembled is visible at a glance.
  static IconData get adminRole =>
      _pick(Icons.shield_rounded, CupertinoIcons.checkmark_shield_fill);

  /// One person, as a form field's prefix — distinct from [customers], which is the group and
  /// belongs to the tab.
  static IconData get person =>
      _pick(Icons.person_outline_rounded, CupertinoIcons.person);

  static IconData get phone => _pick(Icons.phone_outlined, CupertinoIcons.phone);

  /// The other thing an account signs in with. Beside [phone] on the same form, so it has to
  /// read as an address rather than as a note about one.
  static IconData get email => _pick(Icons.mail_outline_rounded, CupertinoIcons.mail);

  static IconData get password => _pick(Icons.lock_outline_rounded, CupertinoIcons.lock);

  /// What an employee is paid a month. A wallet rather than a coin or a banknote: the two
  /// money glyphs in this set already mean *a payment on an order*, and a wage is not one.
  static IconData get salary =>
      _pick(Icons.account_balance_wallet_outlined, CupertinoIcons.money_dollar_circle);

  static IconData get passwordVisible =>
      _pick(Icons.visibility_outlined, CupertinoIcons.eye);

  static IconData get passwordHidden =>
      _pick(Icons.visibility_off_outlined, CupertinoIcons.eye_slash);

  static IconData get search => _pick(Icons.search_rounded, CupertinoIcons.search);

  /// Opens a sheet of choices that narrow a list — sliders, not a magnifier: this is a
  /// different question from [search], and sits beside it rather than inside it.
  static IconData get filter =>
      _pick(Icons.tune_rounded, CupertinoIcons.slider_horizontal_3);

  /// Empties a field — the small circle inside a search box, not a delete.
  static IconData get clear =>
      _pick(Icons.close_rounded, CupertinoIcons.clear_circled_solid);

  static IconData get notifications =>
      _pick(Icons.notifications_none_rounded, CupertinoIcons.bell);

  static IconData get settings =>
      _pick(Icons.settings_outlined, CupertinoIcons.gear_alt);

  static IconData get about =>
      _pick(Icons.info_outline_rounded, CupertinoIcons.info);

  /// The connection, not the server: a dropped line is a different problem from a refusal, and
  /// the two are fixed by different people.
  static IconData get offline =>
      _pick(Icons.wifi_off_rounded, CupertinoIcons.wifi_slash);

  static IconData get error =>
      _pick(Icons.error_outline_rounded, CupertinoIcons.exclamationmark_circle);

  static IconData get empty =>
      _pick(Icons.inbox_rounded, CupertinoIcons.tray);
}
