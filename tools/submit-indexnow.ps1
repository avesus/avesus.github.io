[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$hostName = 'greenforest.io'
$indexNowKey = 'e47faa3c787f4bfba21eb3dd56b96d16'
$sitemapPath = Join-Path $RepositoryRoot 'sitemap.xml'
[xml]$sitemap = Get-Content -LiteralPath $sitemapPath -Raw

$urlList = @(
    $sitemap.SelectNodes("//*[local-name()='loc']") |
        ForEach-Object { $_.InnerText.Trim() }
)
$urlList += "https://$hostName/feed.xml"
$urlList = @($urlList | Sort-Object -Unique)

$payload = @{
    host = $hostName
    key = $indexNowKey
    keyLocation = "https://$hostName/$indexNowKey.txt"
    urlList = $urlList
} | ConvertTo-Json -Depth 4

$requestParameters = @{
    Uri = 'https://api.indexnow.org/IndexNow'
    Method = 'Post'
    ContentType = 'application/json; charset=utf-8'
    Body = $payload
    UseBasicParsing = $true
}
$response = Invoke-WebRequest @requestParameters

Write-Output "IndexNow returned HTTP $($response.StatusCode) for $($urlList.Count) Greenforest URLs."
