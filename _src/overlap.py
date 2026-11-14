# Duplicate-text check for fastdepannage.com. Run after build.ps1, from the repo root:
#   python _src/overlap.py            (summary + every town/region page)
#   python _src/overlap.py --max 20   (exit 1 if a town/region page shares more than 20 %)
# For every indexable page in sitemap.xml it takes the text inside <main>, masks the page's own
# place name, and builds 5-word shingles. "shared" = share of a page's shingles that also occur on
# at least one other indexable page. The call box, nav and footer sit outside <main> and are ignored.
import html, os, re, sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
N = 5
limit = None
if '--max' in sys.argv:
    limit = float(sys.argv[sys.argv.index('--max') + 1])

sm = open(os.path.join(ROOT, 'sitemap.xml'), encoding='utf-8-sig').read()
paths = [re.sub(r'^https?://[^/]+', '', u) for u in re.findall(r'<loc>([^<]+)</loc>', sm)]

def words(text):
    return re.findall(r"[0-9a-zàâäéèêëïîôöûüùç']+", text.lower())

pages = {}
for p in paths:
    f = os.path.join(ROOT, p.strip('/'), 'index.html') if p != '/' else os.path.join(ROOT, 'index.html')
    h = open(f, encoding='utf-8-sig').read()
    m = re.search(r'<main[^>]*>([\s\S]*?)</main>', h)
    body = m.group(1) if m else h
    crumb = re.search(r'<div class="crumbs">([\s\S]*?)</div>', body)
    name = ''
    if crumb:
        name = html.unescape(re.sub(r'<[^>]+>', '', crumb.group(1)).split('/')[-1]).strip()
    body = re.sub(r'<(script|style)[\s\S]*?</\1>', ' ', body)
    text = html.unescape(re.sub(r'<[^>]+>', ' ', body))
    w = words(text)
    nw = words(name)
    if nw:  # mask the page's own place name
        k = len(nw); out = []; i = 0
        while i < len(w):
            if w[i:i + k] == nw: out.append('#place'); i += k
            else: out.append(w[i]); i += 1
        w = out
    sh = set(tuple(w[i:i + N]) for i in range(len(w) - N + 1))
    pages[p] = (len(w), sh)

seen = defaultdict(int)
for p, (_, sh) in pages.items():
    for s in sh: seen[s] += 1

def is_town(p):
    return p.startswith('/takeldienst/') or p.startswith('/fr/depannage/')

rows = []
for p, (n, sh) in pages.items():
    shared = sum(1 for s in sh if seen[s] > 1)
    rows.append((p, n, 100.0 * shared / max(1, len(sh))))
town = sorted([r for r in rows if is_town(r[0])], key=lambda r: -r[2])
other = [r for r in rows if not is_town(r[0])]
avg = lambda rs: sum(r[2] for r in rs) / max(1, len(rs))
print(f'indexable pages: {len(rows)}  town/region pages: {len(town)}')
print(f'town/region pages: average shared {avg(town):.1f} %, max {town[0][2]:.1f} %' if town else '')
print(f'other pages: average shared {avg(other):.1f} %')
print('\n%-48s %6s %8s' % ('page', 'words', 'shared'))
for p, n, s in town:
    print('%-48s %6d %7.1f%%' % (p, n, s))
bad = [r for r in town if limit is not None and r[2] > limit]
if bad:
    print(f'\n{len(bad)} town/region page(s) above {limit} %')
    sys.exit(1)
