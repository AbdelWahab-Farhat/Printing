# A design version is two images or more

> **Status: built and green on `main`, uncommitted** (2026-11-20). Backend: full suite run, only
> the two failures already on `main` remain. Staff app: design ticket and order tests pass,
> `dart analyze` clean of errors and warnings.

## 1. What the owner asked for

When an order enters «قيد التصميم», a design ticket opens between the employee and the designer.
The designer finishes the design and uploads **at least two images** in one version. When the
employee approves the ticket:

- the order moves from «قيد التصميم» to «بانتظار التجهيز», and
- **every image of the approved version** shows on the order card straight away: two images show
  two, three show three, and so on.

A version with a single image cannot be uploaded.

## 2. What already exists, and what does not

| Part | State |
| --- | --- |
| «قيد التصميم» opens a ticket by itself (`OpenAutomaticDesignTicket`) | Built (1e01f01e) |
| Approval moves the order to «بانتظار التجهيز» (`MoveApprovedOrderToPreparing`) | Built (1e01f01e) |
| The approved design lands on the order and on the card | Built, **for one file** |
| A version holds two images or more | **Missing** |

**Why it is not a validation rule:** "one version = one file = one approved design" is built into
three database rules:

1. `design_ticket_files`: one row per version number, at most one approved row per ticket.
2. `design_tickets.approved_customer_design_id`: one design, required by `design_tickets_completion_shape`.
3. `order_designs_one_approved_per_order`: one approved design per order. `ReviewOrderDesign`
   rejects the previous approved row whenever another one is approved.

So attaching two approved images to an order today leaves only the last one approved. The card hides
rejected rows, so it would show one image.

## 3. Decisions (owner, 2026-11-20)

| # | Question | Answer |
| --- | --- | --- |
| 1 | File types | **Images only: JPG, PNG, WEBP.** No PDF counts towards the two. A print PDF can still be sent in the ticket chat. |
| 2 | Print colours | **One set per version**, copied to every image. |
| 3 | Versions uploaded before the change (one file) | **Still approvable.** Only new uploads need two images. |

| 4 | Maximum images per version | **6.** Above that the card wraps to a third row. Read from `config/media.php`. |
| 5 | The same image twice in one version | **Refused** (same checksum): it would show twice on the card for no reason. |

## 4. The model: a version has "faces"

A **face** is one image of a version: the front of the bag, the back, the logo close-up. The version
is still the thing that is reviewed, approved, withdrawn and paid for. Its faces are approved or
turned down together, never one by one.

### Ticket side: a child table, the existing rules untouched

New table `design_ticket_file_faces`:

| Column | Notes |
| --- | --- |
| `design_ticket_file_id` | FK to the version row, cascade on delete |
| `position` | 2, 3, … (face 1 is the version row itself) |
| `disk`, `path`, `original_filename`, `mime_type`, `size_bytes`, `checksum`, `width_px`, `height_px` | Same as the version row's file columns |
| `customer_design_id` | Null until approval, then the library design this face became |

- Unique `(design_ticket_file_id, position)`.
- **Face 1 stays on the version row.** Nothing that reads a version today changes: the three
  indexes, the completion shape, `pendingVersion()`, withdrawal, the designer's pay (once per
  version, key `design-ticket:{id}`).
- An old single-file version is simply a version with no extra faces.

### Approval → customer library

`PromoteApprovedDesign` runs once per face, in position order:

- Face 1's design goes to `design_tickets.approved_customer_design_id`, as today.
- Faces 2…N write their design id onto their face row.
- Each face goes through the existing checksum dedupe, so an image already in the library is reused,
  not copied.
- **Label:** the ticket title, plus « — ٢», « — ٣» … from face 2 on, so the library can tell them
  apart.
- `max_per_customer` (50) is not checked on promotion today and stays unchecked. An approved design
  is never refused for a full library.

### Order side: faces share a version number

`order_designs` gets a `face` column (smallint, default 1). Existing rows are all face 1.

| Index | Today | After |
| --- | --- | --- |
| Unique version | `(order_id, version)` | `(order_id, version, face)` |
| One approved | `(order_id) WHERE approved` | `(order_id, face) WHERE approved` |

- **One approved version per order, of any number of faces.** `ReviewOrderDesign` approves the whole
  version group and rejects every approved row of any other version, with the existing reason «تم
  اعتماد التصميم رقم N بدلاً منه».
- `AddOrderDesign` gets a list form: N library designs → one version number, faces 1…N, colours copied
  from the version.
- `AttachApprovedTicketDesigns` attaches a ticket's faces as one version and approves it once. "Already
  attached" is decided by face 1's design.
- **Manual attach from the library is unchanged:** each pick is its own version, as today.

### What prints

`Order::designForPress()` returns one row; it becomes `designsForPress()`, every face of the approved
version (else of the newest live version). Its readers:

| Reader | Change |
| --- | --- |
| `ChangeOrderStatus::approveDesignForPreparing` («اعتماد آخر نسخة» tick) | Approves the whole version |
| `ChangeOrderStatus::applyPressColors` | Writes the colours onto every face |
| `GuardPrintColors::forPress` | Checks every face |
| `TransitionFields::designApproval` / `printColors` | Same wording, «التصميم رقم N», about the version |
| `CustomerMessageTexts::vendorItems` | Colours from face 1; they are the same on every face |
| `MoveApprovedOrderToPreparing` | Unchanged: it only asks whether an approved version exists |

## 5. API

**Upload** `POST design-tickets/{ticket}/versions`:

- New field `files[]`: required, **min 2**, max `media.design_tickets.max_version_images` (6), each
  JPG/PNG/WEBP within the existing size limit, all different. Messages:
  - fewer than two: «أدخل صورتين على الأقل للتصميم»
  - wrong type: «صور التصميم يجب أن تكون JPG أو PNG أو WEBP»
  - duplicate: «الصورة نفسها مكرّرة في التصميم»
- The old single `file` field is **refused** with «حدّث التطبيق — التصميم يحتاج صورتين على الأقل»,
  so an older staff app gets a sentence, not a crash.
- `files[0]` becomes the version row (face 1), and the rest become faces 2…N in one transaction. The
  files are stored before the transaction, as today.

**Read:**

- `DesignTicketFileResource` gains `faces`: every face in order, **face 1 included**. Each has
  `position`, `file_url`, `width_px`, `height_px`, `original_filename`, `size_bytes` and `mime_type`.
  The existing top-level file fields stay as face 1, so an old app still draws the version.
- `OrderDesignResource` gains `face`.

## 6. Staff app

- **Upload sheet:** choose several images (JPG/PNG/WEBP). If fewer than two are picked, «أدخل صورتين على
  الأقل للتصميم» and nothing is sent. The «اختر ملفاً واحداً» refusal goes. Then the colours sheet, once
  for the version, and the upload sends `files[]`.
- **Version tile and review sheet:** a strip of the faces instead of one thumbnail. Tapping opens the
  viewer on all of them. «النسخة N» stays the label, and the review approves or rejects the version.
- **Ticket card:** face 1, as today.
- **Order card and order page:** `OrderDesignVersions.current` takes every live row of the newest
  **version number** first, then keeps today's two-minute rule for manual picks. The card already draws
  several covers side by side (44 px each), so two images show two.
- **Order designs section:** faces of one version are shown together under «التصميم رقم N».

**Customer app:** no change. The customer sees each approved image as a separate design in their
library, as they see one today.

## 7. On deploy

- Two migrations: the faces table, and `order_designs.face` plus the index swap. Both reversible. No
  data rewritten: every existing row is face 1.
- A version waiting for review with one file can still be approved or sent back.
- **The staff app must be updated before designers upload again.** An old app can still read and
  review, but its upload is refused with the sentence above.

## 8. Tests

**Backend:**

- Upload: 2 images accepted; 1 refused; the old `file` field refused; PDF refused; duplicate refused;
  more than the maximum refused.
- Approval: every face lands in the library and on the order as one approved version; the order moves to
  «بانتظار التجهيز».
- A second approved version rejects every face of the first.
- An old one-file version is still approved and attached as before.
- Press: the colours guard and the «اعتماد آخر نسخة» tick cover every face.
- Migration: existing order designs are face 1 and keep their approved row.

**Staff app:**

- The upload sheet refuses one image.
- The version tile shows its faces.
- `current` returns every face of the newest version.
- The order card shows N covers.
