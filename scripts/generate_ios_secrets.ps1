param(
  [Parameter(Mandatory = $true)]
  [string]$CertificatePath,

  [Parameter(Mandatory = $true)]
  [string]$ProvisionProfilePath,

  [Parameter(Mandatory = $false)]
  [string]$ExportOptionsPath = "ios/ExportOptions.plist"
)

$ErrorActionPreference = 'Stop'

function Write-Base64File {
  param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
  )

  if (-not (Test-Path $InputPath)) {
    throw "File not found: $InputPath"
  }

  $fullInputPath = (Resolve-Path $InputPath).Path
  $bytes = [IO.File]::ReadAllBytes($fullInputPath)
  $b64 = [Convert]::ToBase64String($bytes)
  Set-Content -Path $OutputPath -Value $b64 -NoNewline
  Write-Output "Generated: $OutputPath"
}

New-Item -ItemType Directory -Path "ios/secrets" -Force | Out-Null

Write-Base64File -InputPath $CertificatePath -OutputPath "ios/secrets/IOS_CERTIFICATE_BASE64.txt"
Write-Base64File -InputPath $ProvisionProfilePath -OutputPath "ios/secrets/IOS_PROVISION_PROFILE_BASE64.txt"
Write-Base64File -InputPath $ExportOptionsPath -OutputPath "ios/secrets/IOS_EXPORT_OPTIONS_PLIST_BASE64.txt"

Write-Output "Done. Copy file contents into GitHub Secrets:"
Write-Output "- IOS_CERTIFICATE_BASE64 -> ios/secrets/IOS_CERTIFICATE_BASE64.txt"
Write-Output "- IOS_PROVISION_PROFILE_BASE64 -> ios/secrets/IOS_PROVISION_PROFILE_BASE64.txt"
Write-Output "- IOS_EXPORT_OPTIONS_PLIST_BASE64 -> ios/secrets/IOS_EXPORT_OPTIONS_PLIST_BASE64.txt"
