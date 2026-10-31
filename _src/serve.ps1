# Local preview server for the built site (http://localhost:8138/)
$root = Split-Path $PSScriptRoot -Parent
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add('http://localhost:8138/')
$l.Start()
$types = @{ '.html' = 'text/html; charset=utf-8'; '.css' = 'text/css'; '.js' = 'application/javascript'; '.png' = 'image/png'; '.jpg' = 'image/jpeg'; '.webp' = 'image/webp'; '.svg' = 'image/svg+xml'; '.xml' = 'application/xml'; '.txt' = 'text/plain' }
Write-Host 'Serving on http://localhost:8138/'
while ($l.IsListening) {
  $c = $l.GetContext()
  $p = [Uri]::UnescapeDataString($c.Request.Url.AbsolutePath)
  if ($p.EndsWith('/')) { $p += 'index.html' }
  $f = Join-Path $root ($p.TrimStart('/'))
  $code = 200
  if (-not (Test-Path $f -PathType Leaf)) { $f = Join-Path $root '404.html'; $code = 404 }
  $bytes = [IO.File]::ReadAllBytes($f)
  $ext = [IO.Path]::GetExtension($f)
  $c.Response.StatusCode = $code
  $c.Response.ContentType = if ($types[$ext]) { $types[$ext] } else { 'application/octet-stream' }
  $c.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  $c.Response.Close()
  Write-Host "$code $p"
}
