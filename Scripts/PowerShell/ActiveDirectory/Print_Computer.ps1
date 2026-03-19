<#
.SYNOPSIS
    Lists computer names from Active Directory.

.DESCRIPTION
    Queries Active Directory for computer objects within a specified search base.

.PARAMETER Server
    Domain controller or domain name (e.g. dc01.example.com)

.PARAMETER SearchBase
    Distinguished Name of the OU to search in (e.g. OU=Computers,DC=example,DC=com)
#>

param (
    [string]$Server = "your.domain.local",
    [string]$SearchBase = "OU=Computers,DC=example,DC=com"
)

Import-Module ActiveDirectory

Get-ADComputer `
    -Server $Server `
    -SearchBase $SearchBase `
    -Filter * `
| Select-Object -ExpandProperty Name `
| Sort-Object
