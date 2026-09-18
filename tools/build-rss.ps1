[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),

    [Parameter()]
    [ValidateRange(1, 500)]
    [int]$MaximumItems = 100
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$siteRoot = 'https://greenforest.io'
$sitemapPath = Join-Path $RepositoryRoot 'sitemap.xml'
$outputPath = Join-Path $RepositoryRoot 'feed.xml'
$excludedPaths = @(
    '',
    'about-greenforest.html',
    'contact.html',
    'faq.html',
    'fpga-systems.html',
    'privacy.html',
    'proof-and-artifacts.html',
    'site-map.html',
    'technology-research-and-consulting.html',
    'terms.html'
)

function Get-HtmlValue {
    param(
        [Parameter(Mandatory)]
        [string]$Html,

        [Parameter(Mandatory)]
        [string[]]$Patterns
    )

    foreach ($pattern in $Patterns) {
        $match = [regex]::Match(
            $Html,
            $pattern,
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
        if ($match.Success) {
            return [System.Net.WebUtility]::HtmlDecode($match.Groups[1].Value.Trim())
        }
    }

    return $null
}

[xml]$sitemap = Get-Content -LiteralPath $sitemapPath -Raw
$items = [System.Collections.Generic.List[object]]::new()

foreach ($urlNode in $sitemap.SelectNodes("//*[local-name()='url']")) {
    $locationNode = $urlNode.SelectSingleNode("./*[local-name()='loc']")
    if ($null -eq $locationNode) {
        continue
    }

    $canonicalUrl = $locationNode.InnerText.Trim()
    $uri = [Uri]$canonicalUrl
    $relativeUrlPath = [Uri]::UnescapeDataString($uri.AbsolutePath.TrimStart('/'))
    if ($excludedPaths -contains $relativeUrlPath) {
        continue
    }

    $relativeFilePath = if ([string]::IsNullOrWhiteSpace($relativeUrlPath)) {
        'index.html'
    }
    elseif ($relativeUrlPath.EndsWith('/')) {
        $relativeUrlPath + 'index.html'
    }
    else {
        $relativeUrlPath
    }

    $localPath = Join-Path $RepositoryRoot ($relativeFilePath.Replace('/', [IO.Path]::DirectorySeparatorChar))
    if (-not (Test-Path -LiteralPath $localPath -PathType Leaf)) {
        continue
    }

    $html = Get-Content -LiteralPath $localPath -Raw
    $title = Get-HtmlValue -Html $html -Patterns @(
        '<meta\s+property=["'']og:title["'']\s+content=["'']([^"'']+)["'']',
        '<title>([^<]+)</title>'
    )
    $description = Get-HtmlValue -Html $html -Patterns @(
        '<meta\s+name=["'']description["'']\s+content=["'']([^"'']+)["'']',
        '<meta\s+property=["'']og:description["'']\s+content=["'']([^"'']+)["'']'
    )
    $imageUrl = Get-HtmlValue -Html $html -Patterns @(
        '<meta\s+property=["'']og:image["'']\s+content=["'']([^"'']+)["'']'
    )
    $publishedText = Get-HtmlValue -Html $html -Patterns @(
        '<meta\s+property=["'']article:published_time["'']\s+content=["'']([^"'']+)["'']',
        '"datePublished"\s*:\s*"([^"]+)"'
    )

    if ([string]::IsNullOrWhiteSpace($publishedText)) {
        $lastModifiedNode = $urlNode.SelectSingleNode("./*[local-name()='lastmod']")
        if ($null -ne $lastModifiedNode) {
            $publishedText = $lastModifiedNode.InnerText.Trim()
        }
    }

    if ([string]::IsNullOrWhiteSpace($title) -or
        [string]::IsNullOrWhiteSpace($description) -or
        [string]::IsNullOrWhiteSpace($publishedText)) {
        continue
    }

    $published = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParse(
        $publishedText,
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::AssumeUniversal,
        [ref]$published
    )) {
        continue
    }

    $title = $title -replace '\s*\|\s*Greenforest I/O\s*$', ''
    $items.Add([pscustomobject]@{
        Title = $title
        Description = $description
        Link = $canonicalUrl
        Published = $published
        ImageUrl = $imageUrl
    })
}

$items = @($items | Sort-Object Published -Descending | Select-Object -First $MaximumItems)

$settings = [System.Xml.XmlWriterSettings]::new()
$settings.Indent = $true
$settings.Encoding = [System.Text.UTF8Encoding]::new($false)
$settings.NewLineChars = "`n"
$settings.NewLineHandling = [System.Xml.NewLineHandling]::Replace

$writer = [System.Xml.XmlWriter]::Create($outputPath, $settings)
try {
    $writer.WriteStartDocument()
    $writer.WriteStartElement('rss')
    $writer.WriteAttributeString('version', '2.0')
    $writer.WriteAttributeString('xmlns', 'atom', $null, 'http://www.w3.org/2005/Atom')
    $writer.WriteAttributeString('xmlns', 'media', $null, 'http://search.yahoo.com/mrss/')
    $writer.WriteStartElement('channel')
    $writer.WriteElementString('title', 'Greenforest I/O')
    $writer.WriteElementString('link', "$siteRoot/")
    $writer.WriteElementString('description', 'Clear mechanisms, inspectable engineering, and ideas worth carrying forward by Brian Greenforest.')
    $writer.WriteElementString('language', 'en-us')
    $writer.WriteElementString('lastBuildDate', [DateTimeOffset]::UtcNow.ToString('r', [Globalization.CultureInfo]::InvariantCulture))
    $writer.WriteStartElement('atom', 'link', 'http://www.w3.org/2005/Atom')
    $writer.WriteAttributeString('href', "$siteRoot/feed.xml")
    $writer.WriteAttributeString('rel', 'self')
    $writer.WriteAttributeString('type', 'application/rss+xml')
    $writer.WriteEndElement()

    foreach ($item in $items) {
        $writer.WriteStartElement('item')
        $writer.WriteElementString('title', [string]$item.Title)
        $writer.WriteElementString('link', [string]$item.Link)
        $writer.WriteStartElement('guid')
        $writer.WriteAttributeString('isPermaLink', 'true')
        $writer.WriteString([string]$item.Link)
        $writer.WriteEndElement()
        $writer.WriteElementString('pubDate', $item.Published.ToUniversalTime().ToString('r', [Globalization.CultureInfo]::InvariantCulture))
        $writer.WriteStartElement('description')
        $writer.WriteCData([string]$item.Description)
        $writer.WriteEndElement()

        if (-not [string]::IsNullOrWhiteSpace([string]$item.ImageUrl)) {
            $writer.WriteStartElement('media', 'content', 'http://search.yahoo.com/mrss/')
            $writer.WriteAttributeString('url', [string]$item.ImageUrl)
            $writer.WriteAttributeString('medium', 'image')
            $writer.WriteEndElement()
        }

        $writer.WriteEndElement()
    }

    $writer.WriteEndElement()
    $writer.WriteEndElement()
    $writer.WriteEndDocument()
}
finally {
    $writer.Dispose()
}

Write-Output "Wrote $($items.Count) items to $outputPath"
