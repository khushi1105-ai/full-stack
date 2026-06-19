param(
  [string]$RepoOwner = "khushi1105-ai",
  [string]$Repo = "full-stack",
  [string]$LocalPath = "F:\\sem7\\fullstack",
  [string]$Branch = "main",
  [string]$Token = $env:GITHUB_TOKEN
)

if (-not $Token) {
  Write-Error "No token provided. Set environment variable GITHUB_TOKEN or pass -Token."
  exit 1
}

function Invoke-GitHub {
  param($Method, $Url, $Body = $null)
  $headers = @{ Authorization = "token $Token"; Accept = "application/vnd.github+json" }
  if ($Body) {
    return Invoke-RestMethod -Method $Method -Uri $Url -Headers $headers -Body ($Body | ConvertTo-Json -Depth 10)
  } else {
    return Invoke-RestMethod -Method $Method -Uri $Url -Headers $headers
  }
}

function Upload-File($fullPath, $repoPath) {
  $content = [Convert]::ToBase64String([IO.File]::ReadAllBytes($fullPath))
  $uri = "https://api.github.com/repos/$RepoOwner/$Repo/contents/$repoPath"
  $existing = $null
  try { $existing = Invoke-GitHub -Method Get -Url $uri } catch {}
  $body = @{
    message = "Add $repoPath"
    content = $content
    branch  = $Branch
  }
  if ($existing -and $existing.sha) { $body.sha = $existing.sha }
  Write-Host "Uploading $repoPath ..."
  Invoke-GitHub -Method Put -Url $uri -Body $body | Out-Null
}

# Verify repo exists
$repoUri = "https://api.github.com/repos/$RepoOwner/$Repo"
try {
  Invoke-GitHub -Method Get -Url $repoUri | Out-Null
} catch {
  Write-Error "Repository $RepoOwner/$Repo not found or inaccessible. Create it first or check token scopes."
  exit 1
}

# Walk files and upload
$base = (Resolve-Path $LocalPath).Path.TrimEnd('\')
Get-ChildItem -Path $base -Recurse -File | ForEach-Object {
  $rel = $_.FullName.Substring($base.Length + 1) -replace '\\','/'
  Upload-File $_.FullName $rel
}

Write-Host "Upload complete."