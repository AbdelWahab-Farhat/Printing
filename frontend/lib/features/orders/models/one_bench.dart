/// One order, one bench — the server's `GuardOneBench`, asked on the form before it is.
///
/// **A وسيط product never shares an order with one we make or stock.** The server refuses the
/// mix on the way in and on every edit, with a 422 on `items`; this exists so the clerk reads the
/// same sentence the moment the lines mix, rather than after filling in every quantity and
/// pressing save. The server's refusal still stands behind it.
///
/// **Checked on the form, not in the product picker.** Greying a product out would stop the one
/// edit that legitimately passes through a mix: swapping an order's only product for one from
/// the other bench — add the new one, then remove the old one. The form allows the mix to exist
/// for that moment and refuses to save it.
library;

/// The server's words, from `OutsourcedLineCannotShareAnOrder`, so the warning shown before the
/// save and the refusal after it are one sentence.
const mixedBenchesMessage =
    'المنتجات التي ينفّذها مورد خارجي تُطلب في طلبية مستقلة — افصلها عن باقي المنتجات';

/// Whether these lines, each answering «هل يُطلب وحده؟», would be refused for mixing benches.
///
/// Several وسيط lines together are fine, and so are «مطبوعة» beside «سادة»; only a mix of the
/// two answers is refused. An empty form mixes nothing.
bool linesMixBenches(Iterable<bool> orderedAlone) => orderedAlone.toSet().length > 1;
