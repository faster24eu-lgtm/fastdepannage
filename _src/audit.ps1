# Technical SEO checks on the built site. Run after build.ps1:  & .\_src\audit.ps1
# Reports: titles, descriptions, h1, canonical, hreflang reciprocity, internal links,
# images, JSON-LD validity and sitemap coverage. Exit code 1 if anything is wrong.

$src  = if ($PSScriptRoot) { $PSScriptRoot } else { 'C:\Users\Karim\Documents\fastdepannage\_src' }
$root = Split-Path $src -Parent
$utf8 = New-Object System.Text.UTF8Encoding $false
$problems = New-Object System.Collections.Generic.List[string]
function Flag($page, $msg) { $problems.Add("$page : $msg") }

$files = @(Get-ChildItem $root -Recurse -Filter index.html | Where-Object { $_.FullName -notmatch '\\(_src|\.git|node_modules)\\' })
$pages = @{}
foreach ($f in $files) {
  $rel = '/' + ($f.DirectoryName.Substring($root.Length).Trim('\') -replace '\\', '/')
  if ($rel -ne '/') { $rel += '/' }
  $pages[$rel] = [IO.File]::ReadAllText($f.FullName, $utf8)
}
# subfolder prefix (github.io build) is detected from the stylesheet link
$base = ''
$m0 = [regex]::Match($pages['/'], 'href="([^"]*)/assets/style\.css"'); if ($m0.Success) { $base = $m0.Groups[1].Value }
$canon = @{}; $titles = @{}; $descs = @{}

foreach ($path in $pages.Keys) {
  $h = $pages[$path]
  $noindex = $h -match '<meta name="robots" content="noindex'
  $t = [regex]::Match($h, '<title>([^<]*)</title>').Groups[1].Value
  $d = [regex]::Match($h, '<meta name="description" content="([^"]*)"').Groups[1].Value
  $t = [Net.WebUtility]::HtmlDecode($t); $d = [Net.WebUtility]::HtmlDecode($d)
  if (-not $t) { Flag $path 'no title' } elseif ($t.Length -gt 60) { Flag $path "title $($t.Length) chars" }
  if (-not $d) { Flag $path 'no description' } elseif ($d.Length -gt 160 -or $d.Length -lt 70) { Flag $path "description $($d.Length) chars" }
  if (-not $noindex) {
    if ($titles[$t]) { Flag $path "duplicate title with $($titles[$t])" } else { $titles[$t] = $path }
    if ($descs[$d]) { Flag $path "duplicate description with $($descs[$d])" } else { $descs[$d] = $path }
  }
  $h1 = [regex]::Matches($h, '<h1[\s>]').Count
  if ($h1 -ne 1) { Flag $path "$h1 h1 tags" }
  if ($h -notmatch '<html lang="(nl|fr)-BE">') { Flag $path 'missing html lang' }
  $c = [regex]::Match($h, '<link rel="canonical" href="([^"]+)"').Groups[1].Value
  if (-not $c) { Flag $path 'no canonical' }
  elseif (-not $c.EndsWith($path)) { Flag $path "canonical points elsewhere: $c" }
  $canon[$path] = $c
  # images: alt and size
  foreach ($img in [regex]::Matches($h, '<img [^>]*>')) {
    $tag = $img.Value
    if ($tag -notmatch ' alt="[^"]+"') { Flag $path "img without alt: $tag" }
    if ($tag -notmatch ' width="\d+"' -or $tag -notmatch ' height="\d+"') { Flag $path "img without width/height: $tag" }
  }
  # internal links
  foreach ($a in [regex]::Matches($h, 'href="(/[^"#?]*)')) {
    $u = $a.Groups[1].Value
    if ($base -and $u.StartsWith($base + '/')) { $u = $u.Substring($base.Length) }
    if ($u -match '\.(css|js|svg|png|jpe?g|webp|avif|ico|xml|txt|html)$') { if (-not (Test-Path (Join-Path $root $u.TrimStart('/')))) { Flag $path "missing file $u" }; continue }
    if (-not $u.EndsWith('/')) { Flag $path "link without trailing slash $u"; continue }
    if (-not $pages.ContainsKey($u)) { Flag $path "broken link $u" }
  }
  # JSON-LD must parse
  foreach ($j in [regex]::Matches($h, '<script type="application/ld\+json">([\s\S]*?)</script>')) {
    try { $null = $j.Groups[1].Value | ConvertFrom-Json } catch { Flag $path "invalid JSON-LD: $($_.Exception.Message)" }
  }
}

# hreflang: every alternate must exist and link back
$origin = ($canon['/'] -replace '/$', '')
foreach ($path in $pages.Keys) {
  $alts = [regex]::Matches($pages[$path], '<link rel="alternate" hreflang="([^"]+)" href="([^"]+)"')
  if ($alts.Count -eq 0) { continue }
  $self = $false
  foreach ($a in $alts) {
    $target = $a.Groups[2].Value.Substring($origin.Length)
    if ($target -eq $path) { $self = $true }
    if (-not $pages.ContainsKey($target)) { Flag $path "hreflang to missing page $target"; continue }
    if ($pages[$target] -notmatch [regex]::Escape('hreflang="' + $a.Groups[1].Value + '"') -or $pages[$target] -notmatch [regex]::Escape($origin + $path + '"')) { Flag $path "hreflang not returned by $target" }
  }
  if (-not $self) { Flag $path 'hreflang set has no self reference' }
}

# sitemap = exactly the indexable pages
$sm = [IO.File]::ReadAllText((Join-Path $root 'sitemap.xml'), $utf8)
$locs = @([regex]::Matches($sm, '<loc>([^<]+)</loc>') | ForEach-Object { $_.Groups[1].Value.Substring($origin.Length) })
foreach ($l in $locs) { if (-not $pages.ContainsKey($l)) { Flag 'sitemap' "lists missing page $l" } elseif ($pages[$l] -match 'content="noindex') { Flag 'sitemap' "lists noindex page $l" } }
foreach ($path in $pages.Keys) { if ($pages[$path] -notmatch 'content="noindex' -and $locs -notcontains $path) { Flag 'sitemap' "missing $path" } }
$robots = [IO.File]::ReadAllText((Join-Path $root 'robots.txt'), $utf8)
if ($robots -notmatch [regex]::Escape("Sitemap: $origin/sitemap.xml")) { Flag 'robots.txt' 'sitemap line does not match the canonical origin' }

# orphans: indexable pages no other page links to
$linked = @{}
foreach ($path in $pages.Keys) { foreach ($a in [regex]::Matches($pages[$path], 'href="(/(?:[^"#?]*/)?)"')) { $u = $a.Groups[1].Value; if ($base -and $u.StartsWith($base + '/')) { $u = $u.Substring($base.Length) }; if ($u -ne $path) { $linked[$u] = 1 } } }
foreach ($path in $pages.Keys) { if (-not $linked[$path] -and $pages[$path] -notmatch 'content="noindex') { Flag $path 'orphan: no internal links point here' } }

Write-Host "$($pages.Count) pages checked, origin $origin, base '$base'"
if ($problems.Count) { $problems | Sort-Object | ForEach-Object { Write-Host $_ }; Write-Host "$($problems.Count) problems"; exit 1 }
Write-Host 'No problems found'
exit 0
