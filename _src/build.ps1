# Builds the static site: wraps every _src/pages/*.html in the shared layout,
# writes <path>/index.html, sitemap.xml and robots.txt into the repo root.
# Run from PowerShell:  & .\_src\build.ps1

$ErrorActionPreference = 'Stop'
$src  = if ($PSScriptRoot) { $PSScriptRoot } else { 'C:\Users\Karim\Documents\fastdepannage\_src' }
$root = Split-Path $src -Parent
$site = 'https://fastdepannage.com'
$utf8 = New-Object System.Text.UTF8Encoding $false

# WhatsApp number (digits only, with country code): change it here only.
# Placeholder until the site's own number arrives.
$wa = '3233756737'
$waText = "Bonjour, j'ai besoin d'un dépannage. Ma position :"
$waUrl = 'https://wa.me/' + $wa + '?text=' + [uri]::EscapeDataString($waText)

# lastmod per page = last git commit that touched its source (today if uncommitted)
function Get-LastMod([string]$file) {
  $d = try { git -C $root log -1 --format=%cs -- $file 2>$null } catch { $null }
  if ($d) { return $d } else { return (Get-Date).ToString('yyyy-MM-dd') }
}

# icons: {{icon:name}} -> inline svg
$icons = @{}
Get-ChildItem "$src\icons\*.svg" | ForEach-Object {
  $svg = [IO.File]::ReadAllText($_.FullName, $utf8)
  $svg = $svg -replace '<!--[\s\S]*?-->', '' -replace '\s+', ' ' -replace '> <', '><'
  $svg = $svg -replace ' class="[^"]*"', '' -replace '<path stroke="none" d="M0 0h24v24H0z" fill="none"/>', ''
  $svg = $svg -replace '<svg ', '<svg class="i" aria-hidden="true" focusable="false" '
  $svg = $svg -replace ' width="24" height="24"', '' -replace 'stroke-width="2"', 'stroke-width="1.8"'
  $icons[$_.BaseName] = $svg.Trim()
}
function Expand-Tokens([string]$html) {
  $html = $html.Replace('{{zones}}', $zones).Replace('href="{{wa}}"', 'href="' + $waUrl + '" target="_blank" rel="noopener"')
  return [regex]::Replace($html, '\{\{icon:([a-z0-9-]+)\}\}', { param($m) $n = $m.Groups[1].Value; if (-not $icons.ContainsKey($n)) { throw "Unknown icon $n" }; $icons[$n] })
}

$zones = '<span>24h/24 &middot; 7j/7</span><span>Bruxelles</span><span>Zaventem</span><span>Vilvorde</span><span>Dilbeek</span><span>Ring R0</span><span>Anvers</span><span>Malines</span><span>Louvain</span><span>Gand</span><span>Bruges</span><span>Ostende</span><span>Knokke</span>'
$nav = @'
<div class="strip" aria-hidden="true"><div class="strip-in">{{zones}}{{zones}}</div></div>
<header class="site-header">
  <div class="wrap">
    <a class="brand" href="/" aria-label="Fast Dépannage - accueil"><span class="brand-mark">F</span><span class="brand-txt">Fast<b>Dépannage</b></span></a>
    <nav class="nav" aria-label="Menu principal">
      <div class="dd">
        <button type="button" aria-expanded="false">Services</button>
        <div class="dd-menu">
          <a href="/remorquage/">Remorquage de voiture</a>
          <a href="/depannage-sur-place/">Dépannage sur place</a>
          <a href="/panne-autoroute/">Panne sur le Ring ou l'autoroute</a>
          <a href="/utilitaires-transport/">Camionnettes &amp; transport</a>
        </div>
      </div>
      <div class="dd">
        <button type="button" aria-expanded="false">Zones</button>
        <div class="dd-menu">
          <a href="/bruxelles/">Bruxelles (19 communes)</a>
          <a href="/peripherie-flamande/">Périphérie flamande</a>
          <a href="/anvers/">Anvers</a>
          <a href="/gand/">Gand</a>
          <a href="/bruges-cote/">Bruges &amp; la Côte</a>
          <a href="/louvain-malines/">Louvain &amp; Malines</a>
        </div>
      </div>
      <a href="/tarifs/">Tarifs</a>
      <a href="/guides/">Guides</a>
      <a href="/contact/">Contact</a>
    </nav>
    <a class="head-call" href="{{wa}}">{{icon:brand-whatsapp}}<span><small>24h/24 &middot; 7j/7</small>WhatsApp</span></a>
    <button class="menu-btn" type="button" aria-label="Ouvrir le menu" aria-expanded="false">{{icon:menu-2}}</button>
  </div>
</header>
'@

$cta = @'
<section class="cta-band">
  <div class="wrap">
    <div>
      <h2>En panne maintenant&nbsp;?</h2>
      <p>Envoyez un WhatsApp avec votre position. Le dépanneur vous répond lui-même, en français, avec le prix avant le départ.</p>
    </div>
    <a class="btn btn-wa btn-lg" href="{{wa}}">{{icon:brand-whatsapp}}Écrire sur WhatsApp</a>
  </div>
</section>
'@

$footer = @'
<footer class="site-footer">
  <div class="wrap">
    <div class="foot">
      <div>
        <a class="brand brand-foot" href="/"><span class="brand-mark">F</span><span class="brand-txt">Fast<b>Dépannage</b></span></a>
        <p>Dépannage et remorquage 24h/24 à Bruxelles et en Flandre.</p>
        <p class="foot-tel"><a href="{{wa}}">{{icon:brand-whatsapp}}WhatsApp</a></p>
      </div>
      <div>
        <h3>Services</h3>
        <ul>
          <li><a href="/remorquage/">Remorquage de voiture</a></li>
          <li><a href="/depannage-sur-place/">Dépannage sur place</a></li>
          <li><a href="/panne-autoroute/">Panne sur l'autoroute</a></li>
          <li><a href="/utilitaires-transport/">Camionnettes &amp; transport</a></li>
          <li><a href="/tarifs/">Tarifs</a></li>
          <li><a href="/guides/">Guides pratiques</a></li>
        </ul>
      </div>
      <div>
        <h3>Zones</h3>
        <ul>
          <li><a href="/bruxelles/">Dépannage Bruxelles</a></li>
          <li><a href="/peripherie-flamande/">Périphérie flamande</a></li>
          <li><a href="/anvers/">Dépannage Anvers</a></li>
          <li><a href="/gand/">Dépannage Gand</a></li>
          <li><a href="/bruges-cote/">Bruges &amp; la Côte</a></li>
          <li><a href="/louvain-malines/">Louvain &amp; Malines</a></li>
        </ul>
      </div>
      <div>
        <h3>Horaires</h3>
        <p>24h/24, 7 jours sur 7, week-end et jours fériés compris.</p>
        <p>On vous répond en français, en néerlandais et en anglais.</p>
      </div>
    </div>
    <div class="foot-bottom">
      <span>&copy; <span id="annee">2026</span> Fast Dépannage</span>
      <span><a href="/contact/">Contact</a> &middot; <a href="/mentions-legales/">Mentions légales &amp; vie privée</a></span>
    </div>
  </div>
</footer>
<a class="mcall" href="{{wa}}">{{icon:brand-whatsapp}}Dépanneur sur WhatsApp</a>
'@

$business = @'
{"@context":"https://schema.org","@type":"AutomotiveBusiness","additionalType":"https://en.wikipedia.org/wiki/Tow_truck","@id":"https://fastdepannage.com/#entreprise","name":"Fast Dépannage","url":"https://fastdepannage.com/","image":"https://fastdepannage.com/assets/img/depanneuse-double-chargement.jpg","priceRange":"€€","knowsLanguage":["fr","nl","en"],"openingHoursSpecification":{"@type":"OpeningHoursSpecification","dayOfWeek":["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"],"opens":"00:00","closes":"23:59"},"areaServed":["Bruxelles","Brabant flamand","Anvers","Gand","Bruges","Ostende","Louvain","Malines"]}
'@

$ads = @'
<script async src="https://www.googletagmanager.com/gtag/js?id=AW-10963026341"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'AW-10963026341');
</script>
'@

$pages = @()
Get-ChildItem "$src\pages\*.html" | ForEach-Object {
  $raw = [IO.File]::ReadAllText($_.FullName, $utf8)
  $m = [regex]::Match($raw, '^\s*<!--meta([\s\S]*?)-->')
  if (-not $m.Success) { throw "No meta block in $($_.Name)" }
  $meta = @{}
  foreach ($line in ($m.Groups[1].Value -split "`n")) {
    $i = $line.IndexOf(':')
    if ($i -gt 0) { $meta[$line.Substring(0, $i).Trim()] = $line.Substring($i + 1).Trim() }
  }
  $body = $raw.Substring($m.Length)
  foreach ($k in 'path', 'title', 'description') { if (-not $meta[$k]) { throw "$($_.Name): missing $k" } }
  if ($meta.title.Length -gt 65) { Write-Warning "$($_.Name): title $($meta.title.Length) chars" }
  if ($meta.description.Length -gt 160) { Write-Warning "$($_.Name): description $($meta.description.Length) chars" }

  $path = $meta.path
  $url = $site + $path
  $robots = if ($meta.noindex) { 'noindex' } else { 'index,follow' }
  $esc = { param($s) $s.Replace('&', '&amp;').Replace('"', '&quot;') }
  $img = if ($meta.image) { $meta.image } else { '/assets/img/depanneuse-double-chargement.jpg' }

  $ld = '<script type="application/ld+json">' + $business.Trim() + '</script>'
  if ($meta.crumb) {
    $crumbs = '{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Accueil","item":"' + $site + '/"},{"@type":"ListItem","position":2,"name":"' + $meta.crumb + '","item":"' + $url + '"}]}'
    $ld += "`n" + '<script type="application/ld+json">' + $crumbs + '</script>'
  }
  # FAQ schema from <details class="faq"><summary>Q</summary><p>A</p></details>
  $faqs = [regex]::Matches($body, '<details class="faq">\s*<summary>([\s\S]*?)</summary>\s*<p>([\s\S]*?)</p>\s*</details>')
  if ($faqs.Count -gt 0) {
    $clean = { param($s) ($s -replace '<[^>]+>', '' -replace '\s+', ' ').Trim().Replace('\', '\\').Replace('"', '\"') }
    $items = ($faqs | ForEach-Object { '{"@type":"Question","name":"' + (& $clean $_.Groups[1].Value) + '","acceptedAnswer":{"@type":"Answer","text":"' + (& $clean $_.Groups[2].Value) + '"}}' }) -join ','
    $ld += "`n" + '<script type="application/ld+json">{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[' + $items + ']}</script>'
  }

  $head = @"
<!doctype html>
<html lang="fr-BE">
<head>
$ads
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$(& $esc $meta.title)</title>
<meta name="description" content="$(& $esc $meta.description)">
<meta name="robots" content="$robots">
<link rel="canonical" href="$url">
<meta property="og:type" content="website">
<meta property="og:locale" content="fr_BE">
<meta property="og:site_name" content="Fast Dépannage">
<meta property="og:title" content="$(& $esc $meta.title)">
<meta property="og:description" content="$(& $esc $meta.description)">
<meta property="og:url" content="$url">
<meta property="og:image" content="$site$img">
<meta name="theme-color" content="#0b0c0b">
<link rel="icon" type="image/svg+xml" href="/assets/favicon.svg">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:wght@700;800&family=Barlow:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/assets/style.css">
$ld
</head>
<body>
<a class="skip" href="#contenu">Aller au contenu</a>
"@

  $html = $head + "`n" + $nav + "`n<main id=""contenu"">" + $body.Trim() + "`n</main>`n"
  if (-not $meta.nocta) { $html += $cta + "`n" }
  $html += $footer + "`n<script src=""/assets/site.js"" defer></script>`n</body>`n</html>`n"
  $html = Expand-Tokens $html

  if ($path -eq '/404.html') { $out = Join-Path $root '404.html' }
  else {
    $dir = Join-Path $root ($path.Trim('/'))
    New-Item -ItemType Directory -Force $dir | Out-Null
    $out = Join-Path $dir 'index.html'
  }
  [IO.File]::WriteAllText($out, $html, $utf8)
  if (-not $meta.noindex) { $pages += [pscustomobject]@{ url = $url; mod = (Get-LastMod $_.FullName); prio = if ($path -eq '/') { '1.0' } else { '0.8' } } }
  Write-Host "built $path"
}

$sm = '<?xml version="1.0" encoding="UTF-8"?>' + "`n" + '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' + "`n"
foreach ($p in ($pages | Sort-Object prio -Descending)) { $sm += "  <url><loc>$($p.url)</loc><lastmod>$($p.mod)</lastmod><priority>$($p.prio)</priority></url>`n" }
$sm += '</urlset>' + "`n"
[IO.File]::WriteAllText((Join-Path $root 'sitemap.xml'), $sm, $utf8)
[IO.File]::WriteAllText((Join-Path $root 'robots.txt'), "User-agent: *`nAllow: /`n`nSitemap: $site/sitemap.xml`n", $utf8)
Write-Host "$($pages.Count) pages in sitemap"
exit 0
