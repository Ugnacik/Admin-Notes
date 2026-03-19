<#
.SYNOPSIS
    Active Directory user audit script.

.DESCRIPTION
    Retrieves:
    - Users with "Password Never Expires"
    - Users required to change password at next logon

.PARAMETER Server
    Domain controller or domain (e.g. dc01.example.com)

.PARAMETER SearchBase
    Distinguished Name of OU (e.g. OU=Users,DC=example,DC=com)

.PARAMETER ExportPath
    Optional path to export CSV files
#>

param (
    [string]$Server = "your.domain.local",
    [string]$SearchBase = "OU=Users,DC=example,DC=com",
    [string]$ExportPath = $null
)

Import-Module ActiveDirectory

function Get-OUPath {
    param ($DistinguishedName)
    return $DistinguishedName -replace '^CN=[^,]+,'
}

function Get-PasswordNeverExpiresUsers {
    Get-ADUser `
        -Server $Server `
        -SearchBase $SearchBase `
        -Filter {PasswordNeverExpires -eq $true -and Enabled -eq $true} `
        -Properties PasswordNeverExpires, DisplayName, SamAccountName, DistinguishedName |
    Select-Object DisplayName, SamAccountName, PasswordNeverExpires,
        @{Name="OUPath";Expression={ Get-OUPath $_.DistinguishedName }} |
    Sort-Object DisplayName
}

function Get-MustChangePasswordUsers {
    Get-ADUser `
        -Server $Server `
        -SearchBase $SearchBase `
        -Filter {pwdLastSet -eq 0 -and Enabled -eq $true} `
        -Properties pwdLastSet, DisplayName, SamAccountName, DistinguishedName |
    Select-Object DisplayName, SamAccountName,
        @{Name="MustChangeAtNextLogon";Expression={ if ($_.pwdLastSet -eq 0) {"Yes"} else {"No"} }},
        @{Name="OUPath";Expression={ Get-OUPath $_.DistinguishedName }} |
    Sort-Object DisplayName
}

# === EXECUTION ===

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "=== Password Never Expires Users ===" -ForegroundColor Cyan
$pneUsers = Get-PasswordNeverExpiresUsers
$pneUsers | Format-Table -AutoSize

Write-Host "`n=== Must Change Password at Next Logon ===" -ForegroundColor Cyan
$mcpUsers = Get-MustChangePasswordUsers
$mcpUsers | Format-Table -AutoSize

# Optional export
if ($ExportPath) {
    $pneFile = Join-Path $ExportPath "PasswordNeverExpires_$timestamp.csv"
    $mcpFile = Join-Path $ExportPath "MustChangeAtNextLogon_$timestamp.csv"

    $pneUsers | Export-Csv -Path $pneFile -NoTypeInformation -Encoding UTF8
    $mcpUsers | Export-Csv -Path $mcpFile -NoTypeInformation -Encoding UTF8

    Write-Host "`nCSV exported to:" -ForegroundColor Green
    Write-Host $pneFile
    Write-Host $mcpFile
}
