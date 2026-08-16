"""Turn `storage/ارقام الزباين.xlsx` into database/seeders/data/customers.php.

Run once, by hand, and commit the result — the same arrangement
`data/libya_delivery_locations.php` uses. The seeder must not read a spreadsheet at runtime:
production has no copy of it, and a seeder that depends on a file nobody deployed is a seeder
that works on one laptop.
"""
import openpyxl, re, unicodedata, collections, pathlib, sys

SRC = 'backend/storage/ارقام الزباين.xlsx'
OUT = pathlib.Path('backend/database/seeders/data/customers.php')


def clean(v):
    if v is None:
        return None
    s = unicodedata.normalize('NFKC', str(v)).strip()
    # Excel stores a phone typed as 0912... as the number 912..., so a value can arrive as
    # '926667646.0'. Strip that before anything else looks at it.
    if s.endswith('.0'):
        s = s[:-2]
    return s or None


def phone(v):
    """Libyan mobile, normalised to the 10-digit 09XXXXXXXX form the app writes elsewhere.

    Returns (value, reason_rejected).
    """
    s = clean(v)
    if not s:
        return None, 'missing'
    d = re.sub(r'\D', '', s)
    if d.startswith('00218'):
        d = d[5:]
    elif d.startswith('218'):
        d = d[3:]
    if len(d) == 9 and d[0] == '9':          # 926667646  -> 0926667646
        d = '0' + d
    if not re.fullmatch(r'09\d{8}', d):
        return None, f'unusable ({s!r} -> {d!r})'
    return d, None


rows = [r for r in list(openpyxl.load_workbook(SRC, data_only=True).worksheets[0]
                        .iter_rows(values_only=True))[1:] if any(c is not None for c in r)]

kept, seen, skipped = [], {}, collections.Counter()
examples = collections.defaultdict(list)

for i, (code, name, raw_phone, shop, btype, note, place) in enumerate(rows, start=2):
    n = clean(name)
    p, why = phone(raw_phone)

    if not n:
        skipped['no name'] += 1; examples['no name'].append(i); continue
    if not p:
        skipped[why.split(' ')[0] if why else 'bad phone'] += 1
        examples['bad phone'].append(f'row {i}: {why}')
        continue
    if p in seen:
        skipped['duplicate phone'] += 1
        examples['duplicate phone'].append(f'row {i}: {p} same as row {seen[p]}')
        continue

    seen[p] = i
    kept.append({
        'name': n, 'phone': p,
        'shop': clean(shop), 'field': clean(btype),
        'place': clean(place), 'note': clean(note),
    })


def php(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'") + "'" if s is not None else 'null'


lines = [
    '<?php',
    '',
    'declare(strict_types=1);',
    '',
    '/*',
    ' * The customer book, transcribed from storage/ارقام الزباين.xlsx.',
    ' *',
    ' * Generated once and committed, exactly as database/seeders/data/libya_delivery_locations.php',
    ' * is: a seeder that reads a spreadsheet at runtime is a seeder that only runs where somebody',
    ' * happened to leave the spreadsheet.',
    ' *',
    f' * {len(rows)} rows in, {len(kept)} customers out. What was dropped, and why:',
]
for reason, n in skipped.most_common():
    lines.append(f' *   - {n} {reason}')
lines += [
    ' *',
    " * `place` and `field` are the sheet's own words, resolved against cities/regions and",
    ' * business_fields by the seeder rather than here — the ids only exist in a seeded database.',
    ' */',
    '',
    'return [',
]
for c in kept:
    lines.append(
        "    ['name' => {}, 'phone' => {}, 'shop' => {}, 'field' => {}, 'place' => {}, 'note' => {}],".format(
            php(c['name']), php(c['phone']), php(c['shop']), php(c['field']), php(c['place']), php(c['note'])))
lines += ['];', '']

OUT.write_text('\n'.join(lines), encoding='utf-8')

print(f'rows in           : {len(rows)}')
print(f'customers written : {len(kept)}')
print('dropped           :', dict(skipped))
for k, v in examples.items():
    print(f'  {k}: {v[:3]}{" ..." if len(v) > 3 else ""}')
print(f'\nwrote {OUT} ({OUT.stat().st_size // 1024} KB)')
