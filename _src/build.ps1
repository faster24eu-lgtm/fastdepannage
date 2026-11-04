# Builds the static site in two languages: Dutch at the root (_src/pages/*.html)
# and French under /fr/ (_src/pages/fr/*.html). A French page is the translation of
# the Dutch page with the same file name; the pair gets hreflang links and a
# language switch. Writes <path>/index.html, sitemap.xml and robots.txt.
# Run from PowerShell:  & .\_src\build.ps1   (keep this file UTF-8 with BOM)

$ErrorActionPreference = 'Stop'
$src  = if ($PSScriptRoot) { $PSScriptRoot } else { 'C:\Users\Karim\Documents\fastdepannage\_src' }
$root = Split-Path $src -Parent
# Public origin for canonical, hreflang, sitemap and schema URLs. Set FD_SITE (with the
# subfolder) when the site is served somewhere else, e.g. on github.io before the domain is live
$site = if ($env:FD_SITE) { $env:FD_SITE.TrimEnd('/') } else { 'https://fastdepannage.com' }
$utf8 = New-Object System.Text.UTF8Encoding $false
# Path prefix for hosting in a subfolder (e.g. '/fastdepannage' on github.io); empty on the real domain
$base = if ($env:FD_BASE) { $env:FD_BASE.TrimEnd('/') } else { '' }

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
  zones = '<span>24h/24 &middot; 7j/7</span><span>Envoyez votre position par WhatsApp</span><span>Réponse immédiate</span><span>Prix fixe annoncé d&rsquo;avance</span><span>Heure d&rsquo;arrivée réaliste</span><span>Aussi la nuit et le week-end</span><span>Vous décidez, sans surprise</span>'
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
          <a href="/fr/depannage/louvain/">Louvain</a>
          <a href="/fr/depannage/malines/">Malines</a>
          <a href="/fr/zones-rurales/">Zones rurales</a>
        </div>
      </div>
      <a href="/fr/tarifs/">Tarifs</a>
      <a href="/fr/guides/">Guides</a>
      <a href="/fr/contact/">Contact</a>
    </nav>
    <a class="lang" href="{{alt}}" hreflang="nl" lang="nl" title="Nederlands">NL</a>
    <a class="head-tel" href="{{tel}}">{{icon:phone}}<span><small>Appelez-nous</small>03 375 67 37</span></a><a class="head-call" href="{{wa}}">{{icon:brand-whatsapp}}<span><small>24h/24 &middot; 7j/7</small>WhatsApp</span></a>
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
    <div class="btns"><a class="btn btn-wa btn-lg" href="{{wa}}">{{icon:brand-whatsapp}}Écrire sur WhatsApp</a></div>
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
        <p class="foot-tel"><a href="{{wa}}">{{icon:brand-whatsapp}}WhatsApp</a><a href="{{tel}}">{{icon:phone}}03 375 67 37</a></p>
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
          <li><a href="/fr/depannage/louvain/">Dépannage Louvain</a></li>
          <li><a href="/fr/depannage/malines/">Dépannage Malines</a></li>
          <li><a href="/fr/zones-rurales/">Zones rurales</a></li>
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
<a class="mtel" href="{{tel}}">{{icon:phone}}Appeler</a><a class="mcall" href="{{wa}}">{{icon:brand-whatsapp}}WhatsApp</a>
'@
}
$L.nl = @{
  html = 'nl-BE'; og = 'nl_BE'; home = '/'; homeName = 'Home'; skip = 'Naar de inhoud'
  waText = 'Hallo, ik heb pech en zoek een takeldienst. Mijn locatie:'
  zones = '<span>24/7 bereikbaar</span><span>Stuur uw locatie via WhatsApp</span><span>Meteen antwoord</span><span>Vaste prijs vooraf</span><span>Realistisch aankomstuur</span><span>Ook &rsquo;s nachts en in het weekend</span><span>U beslist, geen verrassingen</span>'
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
          <a href="/takeldienst/leuven/">Leuven</a>
          <a href="/takeldienst/mechelen/">Mechelen</a>
          <a href="/platteland/">Platteland</a>
        </div>
      </div>
      <a href="/tarieven/">Tarieven</a>
      <a href="/gidsen/">Tips</a>
      <a href="/contact/">Contact</a>
    </nav>
    <a class="lang" href="{{alt}}" hreflang="fr" lang="fr" title="Français">FR</a>
    <a class="head-tel" href="{{tel}}">{{icon:phone}}<span><small>Bel ons</small>03 375 67 37</span></a><a class="head-call" href="{{wa}}">{{icon:brand-whatsapp}}<span><small>24/7 bereikbaar</small>WhatsApp</span></a>
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
    <div class="btns"><a class="btn btn-wa btn-lg" href="{{wa}}">{{icon:brand-whatsapp}}Stuur een WhatsApp</a></div>
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
        <p class="foot-tel"><a href="{{wa}}">{{icon:brand-whatsapp}}WhatsApp</a><a href="{{tel}}">{{icon:phone}}03 375 67 37</a></p>
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
          <li><a href="/takeldienst/leuven/">Takeldienst Leuven</a></li>
          <li><a href="/takeldienst/mechelen/">Takeldienst Mechelen</a></li>
          <li><a href="/platteland/">Platteland</a></li>
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
<a class="mtel" href="{{tel}}">{{icon:phone}}Bel ons</a><a class="mcall" href="{{wa}}">{{icon:brand-whatsapp}}WhatsApp</a>
'@
}

$business = @'
{"@context":"https://schema.org","@type":"AutomotiveBusiness","additionalType":"https://en.wikipedia.org/wiki/Tow_truck","@id":"https://fastdepannage.com/#entreprise","name":"Fast Dépannage","url":"https://fastdepannage.com/","image":"https://fastdepannage.com/assets/img/depanneuse-double-chargement.jpg","priceRange":"€€","knowsLanguage":["fr","nl","en"],"openingHoursSpecification":{"@type":"OpeningHoursSpecification","dayOfWeek":["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"],"opens":"00:00","closes":"23:59"},"areaServed":[{"@type":"AdministrativeArea","name":"Brussels Hoofdstedelijk Gewest"},{"@type":"AdministrativeArea","name":"Vlaams-Brabant"},{"@type":"AdministrativeArea","name":"Antwerpen"},{"@type":"AdministrativeArea","name":"Oost-Vlaanderen"},{"@type":"AdministrativeArea","name":"West-Vlaanderen"},{"@type":"AdministrativeArea","name":"Limburg"}]}
'@
$business = $business.Replace('https://fastdepannage.com', $site)

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
# ---------- city and region pages from _src/cities.json and _src/regions.json ----------
# cities-extra-*.json add per-city situations ("cases"), questions ("faq") and villages ("around").
$cityFile = "$src\cities.json"
$cities = @()
# towns-*.json: individual towns, with hub = the id of their region page
foreach ($jf in @("$src\cities.json") + @(Get-ChildItem "$src\regions*.json", "$src\towns-*.json" | ForEach-Object { $_.FullName })) {
  $list = [IO.File]::ReadAllText($jf, $utf8) | ConvertFrom-Json
  foreach ($c in $list) { $c | Add-Member -NotePropertyName file -NotePropertyValue $jf -Force; $cities += $c }
}
foreach ($xf in Get-ChildItem "$src\cities-extra-*.json") {
  $x = [IO.File]::ReadAllText($xf.FullName, $utf8) | ConvertFrom-Json
  foreach ($c in $cities) {
    $e = $x.($c.id)
    if ($e) { foreach ($lang in 'nl', 'fr') { foreach ($pr in $e.$lang.PSObject.Properties) { $c.$lang | Add-Member -NotePropertyName $pr.Name -NotePropertyValue $pr.Value -Force } } }
  }
}
$hubs = @{
  'brussel' = @{ nl = @('Brussel', '/brussel/');           fr = @('Bruxelles', '/fr/bruxelles/') }
  'rand'    = @{ nl = @('Vlaamse Rand', '/vlaamse-rand/'); fr = @('Périphérie flamande', '/fr/peripherie-flamande/') }
  'streken' = @{ nl = @('Platteland', '/platteland/');     fr = @('Zones rurales', '/fr/zones-rurales/') }
  'antwerpen' = @{ nl = @('Antwerpen', '/antwerpen/');     fr = @('Anvers', '/fr/anvers/') }
  'kust'    = @{ nl = @('Brugge & de Kust', '/brugge-kust/'); fr = @('Bruges & la Côte', '/fr/bruges-cote/') }
}
$cityImgs = @(
  @{ src = '/assets/img/depanneuse-double-chargement.jpg'; w = 1600; h = 1200; nl = 'Takelwagen met een wagen op het plateau en een bestelwagen erachter'; fr = 'Dépanneuse avec une voiture sur le plateau et une camionnette en remorque' },
  @{ src = '/assets/img/chargement-camionnette.jpg'; w = 1288; h = 966; nl = 'Bestelwagen die op een schuin plateau geladen wordt'; fr = 'Camionnette hissée sur un plateau incliné' },
  @{ src = '/assets/img/remorquage-porsche-plateau.jpg'; w = 1600; h = 1200; nl = 'Sportwagen met spanbanden over de wielen op een plateau'; fr = 'Voiture de sport sanglée par les roues sur un plateau' },
  @{ src = '/assets/img/intervention-atelier.jpg'; w = 1288; h = 966; nl = 'Pechverhelping aan een wagen'; fr = 'Intervention de dépannage sur une voiture' }
)
# {0} = name, {1} = name with preposition ("in het Pajottenland", "à Anderlecht"), {2} = preposition
$CT = @{}
$CT.nl = @{
  prefix = '/takeldienst/'; prep = 'in'; tarifs = '/tarieven/'
  title = 'Takeldienst {0} 24/7 | Fast Dépannage'
  descShort = 'Takeldienst {1}, dag en nacht. Ter plaatse of naar uw garage. Stuur uw locatie via WhatsApp, vaste prijs vooraf.'
  desc = 'Takeldienst {1}, dag en nacht. Pechverhelping ter plaatse of takelen naar uw garage. Stuur uw locatie via WhatsApp, vaste prijs vooraf.'
  h1 = 'Takeldienst <em>{0}</em>'; btn = 'Stuur mijn locatie'
  know = 'Pech {1}: wat u moet weten'; area = 'Wijken en deelgemeenten'; areaR = 'Gemeenten'; around = 'Ook in deze dorpen'; roads = 'Wegen en plekken die we kennen'
  casesH = 'Typische pech {1}'; casesP = 'Situaties die we hier vaak tegenkomen, en wat u dan best doet.'
  stepsH = 'Zo werkt het {1}'; stepsP = 'Van uw bericht tot de wagen bij de garage staat.'
  steps = @(
    @('U stuurt uw locatie', 'Deel uw live locatie via WhatsApp, met de wagen en wat er gebeurd is. Een foto helpt veel.'),
    @('U krijgt prijs en uur', 'Een vaste prijs voor de opdracht en een realistisch aankomstuur. Dan beslist u.'),
    @('We komen ter plaatse', 'Herstelling ter plaatse als het kan, anders laden we de wagen op en brengen we hem waar u wilt.')
  )
  svc = 'Wat we doen {1}'
  cards = @(
    @('/takelen/', 'truck', 'Takelen', 'Op het plateau naar de garage van uw keuze.'),
    @('/pechverhelping/', 'battery-automotive', 'Pechverhelping', 'Batterij, band, brandstof: vaak ter plaatse opgelost.'),
    @('/pech-snelweg/', 'road', 'Pech op de snelweg', 'Wat u moet doen, en hoe het FAST-systeem werkt.'),
    @('/bestelwagens-transport/', 'route', 'Bestelwagens', 'Bestelwagens tot 3,5 ton en gepland transport.')
  )
  priceH = 'Wat kost een takeldienst {1}?'
  priceP = 'Elke interventie is anders, dus geven we geen "vanaf"-prijs. U krijgt een vaste prijs via WhatsApp, alles inbegrepen, voor de takelwagen vertrekt. Die prijs hangt af van:'
  priceL = @('de afstand tot bij u en de toegang tot de wagen', 'de bestemming: een garage in de buurt of verder weg', 'wat er mis is: starten met een booster kost minder dan takelen', 'het voertuig: auto, bestelwagen of lage wagen', 'het moment: dag, nacht, weekend of feestdag')
  priceA = 'Meer over onze tarieven'
  warn = '<b>Vraag altijd de totale prijs.</b> "Is dat alles inbegrepen, tot aan de garage?" Bij ons is het antwoord ja. Verandert er ter plaatse iets, dan krijgt u eerst de nieuwe prijs.'
  faqH = 'Veelgestelde vragen'
  qs = 'Hoe snel zijn jullie {1}?'
  as = 'Dat hangt af van waar we op dat moment zijn en van het verkeer. We geven u in ons eerste antwoord een realistisch aankomstuur, en laten het weten als dat verandert.'
  q2 = 'Mijn wagen staat {1}. Kan hij naar een garage elders?'
  a2 = 'Ja. Naar uw vaste garage, de dealer, uw huis of een andere stad in België. We spreken de prijs voor de hele rit af voor vertrek, en we praten met de garagist in het Nederlands of het Frans.'
  townsH = 'Takeldienst per gemeente {1}'; townsP = 'Kies uw gemeente voor wat u daar moet weten.'
  near = 'Ook in de buurt'; more = 'Meer info'
}
$CT.fr = @{
  prefix = '/fr/depannage/'; prep = 'à'; tarifs = '/fr/tarifs/'
  title = 'Dépannage {0} 24h/24 | Fast Dépannage'
  descShort = 'Dépanneuse {1}, 24h/24. Sur place ou vers votre garage. Envoyez votre position sur WhatsApp, prix fixé à l''avance.'
  desc = 'Dépanneuse {1}, jour et nuit. Dépannage sur place ou remorquage vers votre garage. Envoyez votre position sur WhatsApp, prix fixé avant le départ.'
  h1 = 'Dépannage {2} <em>{0}</em>'; btn = 'Envoyer ma position'
  know = 'En panne {1} : ce qu''il faut savoir'; area = 'Quartiers'; areaR = 'Communes'; around = 'Aussi dans ces villages'; roads = 'Routes et lieux qu''on connaît'
  casesH = 'Pannes typiques {1}'; casesP = 'Des situations qu''on rencontre souvent ici, et ce qu''il vaut mieux faire.'
  stepsH = 'Comment ça se passe {1}'; stepsP = 'De votre message jusqu''à la voiture au garage.'
  steps = @(
    @('Vous envoyez votre position', 'Partagez votre position en direct sur WhatsApp, avec la voiture et ce qui s''est passé. Une photo aide beaucoup.'),
    @('Vous recevez prix et heure', 'Un prix ferme pour la mission et une heure d''arrivée réaliste. Vous décidez.'),
    @('On intervient', 'Réparation sur place si c''est possible, sinon on charge la voiture et on la conduit où vous voulez.')
  )
  svc = 'Ce qu''on fait {1}'
  cards = @(
    @('/fr/remorquage/', 'truck', 'Remorquage', 'Sur plateau, jusqu''au garage de votre choix.'),
    @('/fr/depannage-sur-place/', 'battery-automotive', 'Dépannage sur place', 'Batterie, pneu, carburant : souvent réglé sur place.'),
    @('/fr/panne-autoroute/', 'road', 'Panne sur l''autoroute', 'Les bons réflexes et le système FAST en Flandre.'),
    @('/fr/utilitaires-transport/', 'route', 'Camionnettes', 'Utilitaires jusqu''à 3,5 t et transport planifié.')
  )
  priceH = 'Combien coûte un dépannage {1} ?'
  priceP = 'Chaque intervention est différente, alors on ne donne pas de prix « à partir de ». Vous recevez un prix ferme sur WhatsApp, tout compris, avant le départ du camion. Ce prix dépend :'
  priceL = @('de la distance jusqu''à vous et de l''accès à la voiture', 'de la destination : un garage proche ou plus loin', 'de la panne : un démarrage au booster coûte moins qu''un remorquage', 'du véhicule : voiture, camionnette ou voiture basse', 'du moment : jour, nuit, week-end ou jour férié')
  priceA = 'En savoir plus sur nos tarifs'
  warn = '<b>Demandez toujours le prix total.</b> « Est-ce tout compris, jusqu''au garage ? » Chez nous, la réponse est oui. Si quelque chose change sur place, vous recevez d''abord le nouveau prix.'
  faqH = 'Questions fréquentes'
  qs = 'En combien de temps êtes-vous là {1} ?'
  as = 'Cela dépend d''où on se trouve à ce moment et du trafic. On vous donne une heure d''arrivée réaliste dans notre première réponse, et on vous prévient si elle change.'
  q2 = 'Ma voiture est en panne {1}, pouvez-vous l''emmener vers un garage ailleurs ?'
  a2 = 'Oui. Vers votre garage habituel, le concessionnaire, chez vous ou une autre ville de Belgique. Le prix du trajet complet est fixé avant le départ, et on parle au garagiste en français ou en néerlandais.'
  townsH = 'Dépannage par commune {1}'; townsP = 'Choisissez votre commune pour ce qu''il faut savoir sur place.'
  near = 'Aussi dans les environs'; more = 'En savoir plus'
}
$byId = @{}; foreach ($c in $cities) { $byId[$c.id] = $c }
$hx = { param($s) $s.Replace('&', '&amp;') }
$i = 0
foreach ($c in $cities) {
  $img = $cityImgs[$i % $cityImgs.Count]; $i++
  foreach ($lang in 'nl', 'fr') {
    $S = $CT[$lang]; $d = $c.$lang; $hm = $L[$lang].home
    $name = & $hx $d.name
    $prep = if ($d.prep) { $d.prep } else { $S.prep }
    $loc = "$prep $name"
    $fmt = { param($t) $t -f $name, $loc, $prep }
    $crumbs = "<a href=""$hm"">$($L[$lang].homeName)</a> / "
    if ($hubs[$c.hub]) { $hub = $hubs[$c.hub][$lang]; $crumbs += "<a href=""$($hub[1])"">$(& $hx $hub[0])</a> / " }
    elseif ($c.hub) { $r = $byId[$c.hub].$lang; $crumbs += "<a href=""$($S.prefix)$($r.slug)/"">$(& $hx $r.name)</a> / " }
    $local = ($d.local | ForEach-Object { '<p>' + (& $hx $_) + '</p>' }) -join "`n      "
    $roads = ($c.roads | ForEach-Object { '<li>' + (& $hx $_) + '</li>' }) -join ''
    $around = if ($d.around) { "<h3>$($S.around)</h3>`n      <ul class=""chips"">" + (($d.around | ForEach-Object { '<li>' + (& $hx $_) + '</li>' }) -join '') + '</ul>' } else { '' }
    $areaH = if ($c.hub -eq 'streken') { $S.areaR } else { $S.area }
    $cases = ($d.cases | ForEach-Object { "<div class=""card""><span class=""ic"">{{icon:$($_[0])}}</span><h3>$(& $hx $_[1])</h3><p>$(& $hx $_[2])</p></div>" }) -join "`n      "
    $steps = ($S.steps | ForEach-Object { "<div class=""step""><h3>$($_[0])</h3><p>$($_[1])</p></div>" }) -join "`n      "
    $cards = ($S.cards | ForEach-Object { "<a class=""card card-link"" href=""$($_[0])""><span class=""ic"">{{icon:$($_[1])}}</span><h3>$($_[2])</h3><p>$(& $hx $_[3])</p><span class=""more"">$($S.more) {{icon:arrow-right}}</span></a>" }) -join "`n      "
    $price = ($S.priceL | ForEach-Object { "<li>$_</li>" }) -join ''
    $faq = @($d.faq | ForEach-Object { , @((& $hx $_[0]), (& $hx $_[1])) }) + , @((& $fmt $S.qs), $S.as) + , @((& $fmt $S.q2), $S.a2)
    $faqs = ($faq | ForEach-Object { "<details class=""faq"">`n        <summary>$($_[0])</summary>`n        <p>$($_[1])</p>`n      </details>" }) -join "`n      "
    $kids = @($cities | Where-Object { $_.hub -eq $c.id })
    $towns = ''
    if ($kids.Count) {
      $tl = ($kids | ForEach-Object { $n = $_.$lang; "<a href=""$($S.prefix)$($n.slug)/""><strong>$(& $hx $n.name)</strong><span>$(& $hx $n.area)</span></a>" }) -join ''
      $towns = "`n<section class=""section white"">`n  <div class=""wrap"">`n    <div class=""sec-head""><h2>$(& $fmt $S.townsH)</h2><p>$($S.townsP)</p></div>`n    <div class=""city-links"">$tl</div>`n  </div>`n</section>`n"
    }
    $near = ($c.near | ForEach-Object { $n = $byId[$_].$lang; "<a href=""$($S.prefix)$($n.slug)/""><strong>$(& $hx $n.name)</strong><span>$(& $hx $n.area)</span></a>" }) -join ''
    $body = @"

<section class="page-hero">
  <div class="wrap">
    <div class="crumbs">$crumbs$name</div>
    <h1>$(& $fmt $S.h1)</h1>
    <p class="lead">$(& $hx $d.intro)</p>
    <div class="btns"><a class="btn btn-wa btn-lg" href="{{wa}}">{{icon:brand-whatsapp}}$($S.btn)</a></div>
  </div>
</section>
$towns
<section class="section white">
  <div class="wrap split">
    <div class="prose">
      <h2>$(& $fmt $S.know)</h2>
      $local
      <h3>$areaH</h3>
      <p>$(& $hx $d.area)</p>
      $around
      <h3>$($S.roads)</h3>
      <ul class="chips">$roads</ul>
    </div>
    <figure class="photo">
      <img src="$($img.src)" width="$($img.w)" height="$($img.h)" alt="$($img[$lang])" loading="lazy">
    </figure>
  </div>
</section>

<section class="section">
  <div class="wrap">
    <div class="sec-head"><h2>$(& $fmt $S.casesH)</h2><p>$($S.casesP)</p></div>
    <div class="grid g3">
      $cases
    </div>
  </div>
</section>

<section class="section dark">
  <div class="wrap">
    <div class="sec-head"><h2>$(& $fmt $S.stepsH)</h2><p>$($S.stepsP)</p></div>
    <div class="steps">
      $steps
    </div>
  </div>
</section>

<section class="section white">
  <div class="wrap">
    <div class="sec-head"><h2>$(& $fmt $S.svc)</h2></div>
    <div class="grid g4">
      $cards
    </div>
  </div>
</section>

<section class="section">
  <div class="wrap split">
    <div class="prose">
      <h2>$(& $fmt $S.priceH)</h2>
      <p>$($S.priceP)</p>
      <ul class="ticks">$price</ul>
      <p><a href="$($S.tarifs)">$($S.priceA)</a></p>
    </div>
    <div class="note warn"><p>$($S.warn)</p></div>
  </div>
</section>

<section class="section white">
  <div class="wrap">
    <div class="sec-head"><h2>$($S.faqH)</h2></div>
    <div class="faqs">
      $faqs
    </div>
    <h2 class="near-h">$($S.near)</h2>
    <div class="city-links">$near</div>
  </div>
</section>
"@
    $meta = @{ path = "$($S.prefix)$($d.slug)/"; title = (& $fmt $S.title); description = (& $fmt $S.desc).Replace('&amp;', '&'); crumb = $d.name; image = $img.src }
    $meta.title = $meta.title.Replace('&amp;', '&')
    if ($meta.description.Length -gt 160) { $meta.description = (& $fmt $S.descShort).Replace('&amp;', '&') }
    # long names: drop the brand suffix rather than get cut off in the results
    if ($meta.title.Length -gt 60) { $meta.title = $meta.title.Split('|')[0].Trim() }
    $isRegion = $c.hub -eq 'streken'
    $meta.service = @($(if ($lang -eq 'nl') { 'Takeldienst' } else { 'Dépannage et remorquage' }), $(if ($isRegion) { 'AdministrativeArea' } else { 'City' }), $d.name)
    $all += [pscustomobject]@{ lang = $lang; key = "city-$($c.id)"; file = $c.file; meta = $meta; body = $body }
  }
}
# {{cities:hub}} in hub pages -> list of that hub's city pages
$cityList = @{}
foreach ($lang in 'nl', 'fr') {
  foreach ($h in $hubs.Keys) {
    $cityList["$lang|$h"] = '<div class="city-links">' + (($cities | Where-Object { $_.hub -eq $h } | ForEach-Object { $n = $_.$lang; "<a href=""$($CT[$lang].prefix)$($n.slug)/""><strong>$(& $hx $n.name)</strong><span>$(& $hx $n.area)</span></a>" }) -join '') + '</div>'
  }
  # {{cities:towns}} -> every town that sits under a region page, alphabetical, as compact links
  $cityList["$lang|towns"] = '<ul class="chips chip-links">' + (($cities | Where-Object { $_.hub -and $byId[$_.hub] } | Sort-Object { $_.$lang.name } | ForEach-Object { $n = $_.$lang; "<li><a href=""$($CT[$lang].prefix)$($n.slug)/"">$(& $hx $n.name)</a></li>" }) -join '') + '</ul>'
}

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
  # BreadcrumbList from the visible crumbs: <a href="/x/">Name</a> / ... / current page
  $cm = [regex]::Match($p.body, '<div class="crumbs">([\s\S]*?)</div>')
  if ($cm.Success -and $meta.crumb) {
    $jsn = { param($s) [Net.WebUtility]::HtmlDecode($s).Replace('\', '\\').Replace('"', '\"') }
    $li = @(); $pos = 0
    foreach ($a in [regex]::Matches($cm.Groups[1].Value, '<a href="([^"]+)">([^<]+)</a>')) { $pos++; $li += '{"@type":"ListItem","position":' + $pos + ',"name":"' + (& $jsn $a.Groups[2].Value) + '","item":"' + $site + $a.Groups[1].Value + '"}' }
    $pos++; $li += '{"@type":"ListItem","position":' + $pos + ',"name":"' + (& $jsn $meta.crumb) + '","item":"' + $url + '"}'
    $ld += "`n" + '<script type="application/ld+json">{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[' + ($li -join ',') + ']}</script>'
  }
  # Service schema on town and region pages
  if ($meta.service) {
    $ld += "`n" + '<script type="application/ld+json">{"@context":"https://schema.org","@type":"Service","serviceType":"' + $meta.service[0] + '","name":"' + $meta.title.Split('|')[0].Trim() + '","url":"' + $url + '","provider":{"@id":"' + $site + '/#entreprise"},"areaServed":{"@type":"' + $meta.service[1] + '","name":"' + $meta.service[2] + '"},"availableChannel":{"@type":"ServiceChannel","serviceUrl":"https://wa.me/' + $wa + '"}}</script>'
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

  $telTxt = if ($p.lang -eq 'nl') { 'Bel 03 375 67 37' } else { 'Appeler le 03 375 67 37' }
  $html = [regex]::Replace($html, '(<a class="btn btn-wa btn-lg" href="{{wa}}">.*?</a>)', ('$1<a class="btn btn-tel btn-lg" href="{{tel}}">{{icon:phone}}' + $telTxt + '</a>'))
  $html = $html.Replace('{{tel}}', 'tel:+3233756737')
  $waUrl = 'https://wa.me/' + $wa + '?text=' + [uri]::EscapeDataString($T.waText)
  $html = $html.Replace('{{zones}}', $T.zones).Replace('{{alt}}', $alt).Replace('href="{{wa}}"', 'href="' + $waUrl + '" target="_blank" rel="noopener"')
  $html = [regex]::Replace($html, '\{\{icon:([a-z0-9-]+)\}\}', { param($m) $n = $m.Groups[1].Value; if (-not $icons.ContainsKey($n)) { throw "Unknown icon $n" }; $icons[$n] })
  $html = [regex]::Replace($html, '\{\{cities:([a-z-]+)\}\}', { param($m) $cityList["$($p.lang)|$($m.Groups[1].Value)"] })
  if ($html -match '\{\{') { throw "$($p.lang)/$($p.key): unreplaced token" }
  if ($base) { $html = [regex]::Replace($html, '(href|src)="/(?!/)', "`$1=`"$base/") }

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
  [IO.File]::WriteAllText((Join-Path $root 'index.html'), '<!doctype html><meta charset="utf-8"><title>Fast Dépannage</title><meta name="robots" content="noindex"><meta http-equiv="refresh" content="0;url=' + $base + '/fr/"><link rel="canonical" href="' + $site + '/fr/"><a href="' + $base + '/fr/">Fast Dépannage</a>', $utf8)
}

exit 0
