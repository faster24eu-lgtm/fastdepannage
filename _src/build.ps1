# Builds the static site in two languages: French at the root (_src/pages/*.html)
# and Dutch under /nl/ (_src/pages/nl/*.html). A Dutch page is the translation of
# the French page with the same file name; the pair gets hreflang links and a
# language switch. Writes <path>/index.html, sitemap.xml and robots.txt.
# Run from PowerShell:  & .\_src\build.ps1   (keep this file UTF-8 with BOM)

$ErrorActionPreference = 'Stop'
$src  = if ($PSScriptRoot) { $PSScriptRoot } else { 'C:\Users\Karim\Documents\fastdepannage\_src' }
$root = Split-Path $src -Parent
$site = 'https://fastdepannage.com'
$utf8 = New-Object System.Text.UTF8Encoding $false

# WhatsApp number (digits only, with country code): change it here only.
# Placeholder until the site's own number arrives.
$wa = '3233756737'

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

# ---------- per-language strings and templates ----------
$L = @{}
$L.fr = @{
  html = 'fr-BE'; og = 'fr_BE'; home = '/fr/'; homeName = 'Accueil'; skip = 'Aller au contenu'
  waText = "Bonjour, j'ai besoin d'un dépannage. Ma position :"
  zones = '<span>24h/24 &middot; 7j/7</span><span>Bruxelles</span><span>Zaventem</span><span>Vilvorde</span><span>Dilbeek</span><span>Ring R0</span><span>Anvers</span><span>Malines</span><span>Louvain</span><span>Gand</span><span>Bruges</span><span>Ostende</span><span>Knokke</span>'
  nav = @'
<div class="strip" aria-hidden="true"><div class="strip-in">{{zones}}{{zones}}</div></div>
<header class="site-header">
  <div class="wrap">
    <a class="brand" href="/fr/" aria-label="Fast Dépannage - accueil"><span class="brand-mark">F</span><span class="brand-txt">Fast<b>Dépannage</b></span></a>
    <nav class="nav" aria-label="Menu principal">
      <div class="dd">
        <button type="button" aria-expanded="false">Services</button>
        <div class="dd-menu">
          <a href="/fr/remorquage/">Remorquage de voiture</a>
          <a href="/fr/depannage-sur-place/">Dépannage sur place</a>
          <a href="/fr/panne-autoroute/">Panne sur le Ring ou l'autoroute</a>
          <a href="/fr/utilitaires-transport/">Camionnettes &amp; transport</a>
        </div>
      </div>
      <div class="dd">
        <button type="button" aria-expanded="false">Zones</button>
        <div class="dd-menu">
          <a href="/fr/bruxelles/">Bruxelles (19 communes)</a>
          <a href="/fr/peripherie-flamande/">Périphérie flamande</a>
          <a href="/fr/anvers/">Anvers</a>
          <a href="/fr/gand/">Gand</a>
          <a href="/fr/bruges-cote/">Bruges &amp; la Côte</a>
          <a href="/fr/louvain-malines/">Louvain &amp; Malines</a>
        </div>
      </div>
      <a href="/fr/tarifs/">Tarifs</a>
      <a href="/fr/guides/">Guides</a>
      <a href="/fr/contact/">Contact</a>
    </nav>
    <a class="lang" href="{{alt}}" hreflang="nl" lang="nl" title="Nederlands">NL</a>
    <a class="head-call" href="{{wa}}">{{icon:brand-whatsapp}}<span><small>24h/24 &middot; 7j/7</small>WhatsApp</span></a>
    <button class="menu-btn" type="button" aria-label="Ouvrir le menu" aria-expanded="false">{{icon:menu-2}}</button>
  </div>
</header>
'@
  cta = @'
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
  footer = @'
<footer class="site-footer">
  <div class="wrap">
    <div class="foot">
      <div>
        <a class="brand brand-foot" href="/fr/"><span class="brand-mark">F</span><span class="brand-txt">Fast<b>Dépannage</b></span></a>
        <p>Dépannage et remorquage 24h/24 à Bruxelles et en Flandre.</p>
        <p class="foot-tel"><a href="{{wa}}">{{icon:brand-whatsapp}}WhatsApp</a></p>
      </div>
      <div>
        <h3>Services</h3>
        <ul>
          <li><a href="/fr/remorquage/">Remorquage de voiture</a></li>
          <li><a href="/fr/depannage-sur-place/">Dépannage sur place</a></li>
          <li><a href="/fr/panne-autoroute/">Panne sur l'autoroute</a></li>
          <li><a href="/fr/utilitaires-transport/">Camionnettes &amp; transport</a></li>
          <li><a href="/fr/tarifs/">Tarifs</a></li>
          <li><a href="/fr/guides/">Guides pratiques</a></li>
        </ul>
      </div>
      <div>
        <h3>Zones</h3>
        <ul>
          <li><a href="/fr/bruxelles/">Dépannage Bruxelles</a></li>
          <li><a href="/fr/peripherie-flamande/">Périphérie flamande</a></li>
          <li><a href="/fr/anvers/">Dépannage Anvers</a></li>
          <li><a href="/fr/gand/">Dépannage Gand</a></li>
          <li><a href="/fr/bruges-cote/">Bruges &amp; la Côte</a></li>
          <li><a href="/fr/louvain-malines/">Louvain &amp; Malines</a></li>
        </ul>
      </div>
      <div>
        <h3>Horaires</h3>
        <p>24h/24, 7 jours sur 7, week-end et jours fériés compris.</p>
        <p>On vous répond en français, en néerlandais et en anglais.</p>
        <p><a href="/" hreflang="nl" lang="nl">Nederlandstalige versie</a></p>
      </div>
    </div>
    <div class="foot-bottom">
      <span>&copy; <span id="annee">2026</span> Fast Dépannage</span>
      <span><a href="/fr/contact/">Contact</a> &middot; <a href="/fr/mentions-legales/">Mentions légales &amp; vie privée</a></span>
    </div>
  </div>
</footer>
<a class="mcall" href="{{wa}}">{{icon:brand-whatsapp}}Dépanneur sur WhatsApp</a>
'@
}
$L.nl = @{
  html = 'nl-BE'; og = 'nl_BE'; home = '/'; homeName = 'Home'; skip = 'Naar de inhoud'
  waText = 'Hallo, ik heb pech en zoek een takeldienst. Mijn locatie:'
  zones = '<span>24/7</span><span>Brussel</span><span>Zaventem</span><span>Vilvoorde</span><span>Dilbeek</span><span>Ring R0</span><span>Antwerpen</span><span>Mechelen</span><span>Leuven</span><span>Gent</span><span>Brugge</span><span>Oostende</span><span>Knokke</span>'
  nav = @'
<div class="strip" aria-hidden="true"><div class="strip-in">{{zones}}{{zones}}</div></div>
<header class="site-header">
  <div class="wrap">
    <a class="brand" href="/" aria-label="Fast Dépannage - home"><span class="brand-mark">F</span><span class="brand-txt">Fast<b>Dépannage</b></span></a>
    <nav class="nav" aria-label="Hoofdmenu">
      <div class="dd">
        <button type="button" aria-expanded="false">Diensten</button>
        <div class="dd-menu">
          <a href="/takelen/">Wagen takelen</a>
          <a href="/pechverhelping/">Pechverhelping ter plaatse</a>
          <a href="/pech-snelweg/">Pech op de Ring of snelweg</a>
          <a href="/bestelwagens-transport/">Bestelwagens &amp; transport</a>
        </div>
      </div>
      <div class="dd">
        <button type="button" aria-expanded="false">Regio</button>
        <div class="dd-menu">
          <a href="/brussel/">Brussel (19 gemeenten)</a>
          <a href="/vlaamse-rand/">Vlaamse Rand</a>
          <a href="/antwerpen/">Antwerpen</a>
          <a href="/gent/">Gent</a>
          <a href="/brugge-kust/">Brugge &amp; de Kust</a>
          <a href="/leuven-mechelen/">Leuven &amp; Mechelen</a>
        </div>
      </div>
      <a href="/tarieven/">Tarieven</a>
      <a href="/gidsen/">Tips</a>
      <a href="/contact/">Contact</a>
    </nav>
    <a class="lang" href="{{alt}}" hreflang="fr" lang="fr" title="Français">FR</a>
    <a class="head-call" href="{{wa}}">{{icon:brand-whatsapp}}<span><small>24/7 bereikbaar</small>WhatsApp</span></a>
    <button class="menu-btn" type="button" aria-label="Menu openen" aria-expanded="false">{{icon:menu-2}}</button>
  </div>
</header>
'@
  cta = @'
<section class="cta-band">
  <div class="wrap">
    <div>
      <h2>Nu pech&nbsp;?</h2>
      <p>Stuur een WhatsApp met uw locatie. De takeldienst antwoordt zelf, in het Nederlands, met de prijs vóór vertrek.</p>
    </div>
    <a class="btn btn-wa btn-lg" href="{{wa}}">{{icon:brand-whatsapp}}Stuur een WhatsApp</a>
  </div>
</section>
'@
  footer = @'
<footer class="site-footer">
  <div class="wrap">
    <div class="foot">
      <div>
        <a class="brand brand-foot" href="/"><span class="brand-mark">F</span><span class="brand-txt">Fast<b>Dépannage</b></span></a>
        <p>Takeldienst en pechverhelping 24/7 in Brussel en Vlaanderen.</p>
        <p class="foot-tel"><a href="{{wa}}">{{icon:brand-whatsapp}}WhatsApp</a></p>
      </div>
      <div>
        <h3>Diensten</h3>
        <ul>
          <li><a href="/takelen/">Wagen takelen</a></li>
          <li><a href="/pechverhelping/">Pechverhelping ter plaatse</a></li>
          <li><a href="/pech-snelweg/">Pech op de snelweg</a></li>
          <li><a href="/bestelwagens-transport/">Bestelwagens &amp; transport</a></li>
          <li><a href="/tarieven/">Tarieven</a></li>
          <li><a href="/gidsen/">Praktische tips</a></li>
        </ul>
      </div>
      <div>
        <h3>Regio</h3>
        <ul>
          <li><a href="/brussel/">Takeldienst Brussel</a></li>
          <li><a href="/vlaamse-rand/">Vlaamse Rand</a></li>
          <li><a href="/antwerpen/">Takeldienst Antwerpen</a></li>
          <li><a href="/gent/">Takeldienst Gent</a></li>
          <li><a href="/brugge-kust/">Brugge &amp; de Kust</a></li>
          <li><a href="/leuven-mechelen/">Leuven &amp; Mechelen</a></li>
        </ul>
      </div>
      <div>
        <h3>Bereikbaarheid</h3>
        <p>24 uur op 24, 7 dagen op 7, ook in het weekend en op feestdagen.</p>
        <p>We antwoorden in het Nederlands, het Frans en het Engels.</p>
        <p><a href="/fr/" hreflang="fr" lang="fr">Version française</a></p>
      </div>
    </div>
    <div class="foot-bottom">
      <span>&copy; <span id="annee">2026</span> Fast Dépannage</span>
      <span><a href="/contact/">Contact</a> &middot; <a href="/juridisch/">Juridische info &amp; privacy</a></span>
    </div>
  </div>
</footer>
<a class="mcall" href="{{wa}}">{{icon:brand-whatsapp}}Takeldienst via WhatsApp</a>
'@
}

$business = @'
{"@context":"https://schema.org","@type":"AutomotiveBusiness","additionalType":"https://en.wikipedia.org/wiki/Tow_truck","@id":"https://fastdepannage.com/#entreprise","name":"Fast Dépannage","url":"https://fastdepannage.com/","image":"https://fastdepannage.com/assets/img/depanneuse-double-chargement.jpg","priceRange":"€€","knowsLanguage":["fr","nl","en"],"openingHoursSpecification":{"@type":"OpeningHoursSpecification","dayOfWeek":["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"],"opens":"00:00","closes":"23:59"},"areaServed":["Bruxelles","Brussel","Vlaams-Brabant","Antwerpen","Gent","Brugge","Oostende","Leuven","Mechelen"]}
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

# ---------- read all pages, then pair translations by file name ----------
function Read-Page($file, $lang) {
  $raw = [IO.File]::ReadAllText($file.FullName, $utf8)
  $m = [regex]::Match($raw, '^\s*<!--meta([\s\S]*?)-->')
  if (-not $m.Success) { throw "No meta block in $lang/$($file.Name)" }
  $meta = @{}
  foreach ($line in ($m.Groups[1].Value -split "`n")) {
    $i = $line.IndexOf(':')
    if ($i -gt 0) { $meta[$line.Substring(0, $i).Trim()] = $line.Substring($i + 1).Trim() }
  }
  foreach ($k in 'path', 'title', 'description') { if (-not $meta[$k]) { throw "$lang/$($file.Name): missing $k" } }
  if ($meta.title.Length -gt 65) { Write-Warning "$lang/$($file.Name): title $($meta.title.Length) chars" }
  if ($meta.description.Length -gt 160) { Write-Warning "$lang/$($file.Name): description $($meta.description.Length) chars" }
  [pscustomobject]@{ lang = $lang; key = $file.BaseName; file = $file.FullName; meta = $meta; body = $raw.Substring($m.Length) }
}
$all = @()
Get-ChildItem "$src\pages\*.html" | ForEach-Object { $all += Read-Page $_ 'nl' }
Get-ChildItem "$src\pages\fr\*.html" | ForEach-Object { $all += Read-Page $_ 'fr' }
$byKey = @{}
foreach ($p in $all) { if (-not $byKey[$p.key]) { $byKey[$p.key] = @{} }; $byKey[$p.key][$p.lang] = $p }

$esc = { param($s) $s.Replace('&', '&amp;').Replace('"', '&quot;') }
$sitemap = @()
foreach ($p in $all) {
  $T = $L[$p.lang]
  $meta = $p.meta
  $path = $meta.path
  $url = $site + $path
  $other = if ($p.lang -eq 'fr') { 'nl' } else { 'fr' }
  $twin = $byKey[$p.key][$other]
  $alt = if ($twin -and -not $twin.meta.noindex) { $twin.meta.path } else { $L[$other].home }
  $robots = if ($meta.noindex) { 'noindex' } else { 'index,follow' }
  $img = if ($meta.image) { $meta.image } else { '/assets/img/depanneuse-double-chargement.jpg' }

  $hreflang = ''
  if ($twin -and -not $meta.noindex -and -not $twin.meta.noindex) {
    $fr = $byKey[$p.key]['fr'].meta.path; $nl = $byKey[$p.key]['nl'].meta.path
    $hreflang = "<link rel=""alternate"" hreflang=""fr-BE"" href=""$site$fr"">`n<link rel=""alternate"" hreflang=""nl-BE"" href=""$site$nl"">`n<link rel=""alternate"" hreflang=""x-default"" href=""$site$nl"">"
  }

  $ld = '<script type="application/ld+json">' + $business.Trim() + '</script>'
  if ($meta.crumb) {
    $crumbs = '{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"' + $T.homeName + '","item":"' + $site + $T.home + '"},{"@type":"ListItem","position":2,"name":"' + $meta.crumb + '","item":"' + $url + '"}]}'
    $ld += "`n" + '<script type="application/ld+json">' + $crumbs + '</script>'
  }
  # FAQ schema from <details class="faq"><summary>Q</summary><p>A</p></details>
  $faqs = [regex]::Matches($p.body, '<details class="faq">\s*<summary>([\s\S]*?)</summary>\s*<p>([\s\S]*?)</p>\s*</details>')
  if ($faqs.Count -gt 0) {
    $clean = { param($s) ($s -replace '<[^>]+>', '' -replace '&nbsp;', ' ' -replace '\s+', ' ').Trim().Replace('\', '\\').Replace('"', '\"') }
    $items = ($faqs | ForEach-Object { '{"@type":"Question","name":"' + (& $clean $_.Groups[1].Value) + '","acceptedAnswer":{"@type":"Answer","text":"' + (& $clean $_.Groups[2].Value) + '"}}' }) -join ','
    $ld += "`n" + '<script type="application/ld+json">{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[' + $items + ']}</script>'
  }

  $head = @"
<!doctype html>
<html lang="$($T.html)">
<head>
$ads
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$(& $esc $meta.title)</title>
<meta name="description" content="$(& $esc $meta.description)">
<meta name="robots" content="$robots">
<link rel="canonical" href="$url">
$hreflang
<meta property="og:type" content="website">
<meta property="og:locale" content="$($T.og)">
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
<a class="skip" href="#contenu">$($T.skip)</a>
"@

  $html = $head + "`n" + $T.nav + "`n<main id=""contenu"">" + $p.body.Trim() + "`n</main>`n"
  if (-not $meta.nocta) { $html += $T.cta + "`n" }
  $html += $T.footer + "`n<script src=""/assets/site.js"" defer></script>`n</body>`n</html>`n"

  $waUrl = 'https://wa.me/' + $wa + '?text=' + [uri]::EscapeDataString($T.waText)
  $html = $html.Replace('{{zones}}', $T.zones).Replace('{{alt}}', $alt).Replace('href="{{wa}}"', 'href="' + $waUrl + '" target="_blank" rel="noopener"')
  $html = [regex]::Replace($html, '\{\{icon:([a-z0-9-]+)\}\}', { param($m) $n = $m.Groups[1].Value; if (-not $icons.ContainsKey($n)) { throw "Unknown icon $n" }; $icons[$n] })
  if ($html -match '\{\{') { throw "$($p.lang)/$($p.key): unreplaced token" }

  if ($path -eq '/404.html') { $out = Join-Path $root '404.html' }
  else {
    $dir = Join-Path $root ($path.Trim('/'))
    New-Item -ItemType Directory -Force $dir | Out-Null
    $out = Join-Path $dir 'index.html'
  }
  [IO.File]::WriteAllText($out, $html, $utf8)
  if (-not $meta.noindex) { $sitemap += [pscustomobject]@{ url = $url; mod = (Get-LastMod $p.file); prio = if ($path -eq '/' -or $path -eq '/nl/') { '1.0' } else { '0.8' } } }
  Write-Host "built $path"
}

$sm = '<?xml version="1.0" encoding="UTF-8"?>' + "`n" + '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' + "`n"
foreach ($s in ($sitemap | Sort-Object prio -Descending)) { $sm += "  <url><loc>$($s.url)</loc><lastmod>$($s.mod)</lastmod><priority>$($s.prio)</priority></url>`n" }
$sm += '</urlset>' + "`n"
[IO.File]::WriteAllText((Join-Path $root 'sitemap.xml'), $sm, $utf8)
[IO.File]::WriteAllText((Join-Path $root 'robots.txt'), "User-agent: *`nAllow: /`n`nSitemap: $site/sitemap.xml`n", $utf8)
Write-Host "$($sitemap.Count) pages in sitemap"
# Until the Dutch home page exists, send / to the French site
if (-not ($byKey['index'] -and $byKey['index']['nl'])) {
  [IO.File]::WriteAllText((Join-Path $root 'index.html'), '<!doctype html><meta charset="utf-8"><title>Fast Dépannage</title><meta name="robots" content="noindex"><meta http-equiv="refresh" content="0;url=/fr/"><link rel="canonical" href="' + $site + '/fr/"><a href="/fr/">Fast Dépannage</a>', $utf8)
}

exit 0
