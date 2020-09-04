#################################################################
## Title: 
##  Sitecore Powershell Extensions
##  Remoting Tools
## 
## Description:
##  All SPE scripts within the 
##  folder $scriptFolderName will be executed
## 
## Remember Set Execution Policy: 
##   Set-ExecutionPolicy RemoteSigned -Scope Process
##
#################################################################

[CmdletBinding(SupportsShouldProcess = $true)]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "SitecorePassword")]

param(
    [Parameter(Mandatory = $true)]
    [string]$SitecoreInstanceUri,
    [Parameter(Mandatory = $false)]
    [string]$SitecoreUsername = "admin",
    [Parameter(Mandatory = $false)]
    [string]$SitecorePassword = "b",
    [Parameter(Mandatory = $false)]
    [string]$PathToSPEModule = "C:\Sitecore\Modules\SPE Remoting-5.0\SPE",
    [Parameter(Mandatory = $false)]
    [switch]$RunSetupOnly
)

#-----------------------------------------------------------------
# SETUP
#-----------------------------------------------------------------
#region Setup
$ErrorActionPreference = "STOP"
$ProgressPreference = "SilentlyContinue"

#Import SPE Remoting Module
if(-Not (Test-Path $PathToSPEModule)) {
    Write-Error "Path to SPE Remoting Module can't be found. Path: $PathToSPEModule"
    Exit
}
Import-Module -Name $PathToSPEModule -Force
Import-Module -Name "$PSScriptRoot\Tooling\SPE-Remote-Tooling.ps1" -Force

# Local Functions
$localFunctionsFolder = "$PSScriptRoot\Tooling\LocalFunctions"
Get-ChildItem $localFunctionsFolder -Filter *.ps1 | Foreach-Object {
    Import-Module -Name $_.FullName -Force
}

Invoke-Setup `
    -SitecoreInstanceUri $SitecoreInstanceUri `
    -SitecoreUsername $SitecoreUsername `
    -SitecorePassword $SitecorePassword `
    -Force:$RunSetupOnly

if($RunSetupOnly) {
    Exit
}

# Create a ScriptBlock of reusable ./Functions from the Functions folder
$speFunctions = $null;
Get-ChildItem "$PSScriptRoot\Functions" -Filter *.ps1 | Foreach-Object {
    # . $_.FullName
    $function = Get-Command "$PSScriptRoot\Functions\$_" | Select-Object -ExpandProperty ScriptBlock 
    $speFunctions = [System.Management.Automation.ScriptBlock]::Create("$speFunctions`n$function`n")
}
#endregion Setup

#-----------------------------------------------------------------
# VARIABLES
#-----------------------------------------------------------------
#region Variables
$scriptFolderName = "_Current"
$runAwlasysScriptFolderName = "_RunAlways"

#endregion Variables

#-----------------------------------------------------------------
# RUN
#-----------------------------------------------------------------
# Initiate new session
$session = New-ScriptSession `
            -Username $SitecoreUsername `
            -Password $SitecorePassword `
            -ConnectionUri $SitecoreInstanceUri

# Iterate through each SPE script in Current
Get-ChildItem "$PSScriptRoot\$scriptFolderName" -Filter *.ps1 -Recurse | Foreach-Object {
    Invoke-ExecuteSPEScript -File $_
}

Get-ChildItem "$PSScriptRoot\$runAwlasysScriptFolderName" -Filter *.ps1 -Recurse | Foreach-Object {
    Invoke-ExecuteSPEScript -File $_ -ExcludeRunCheck
}

Stop-ScriptSession -Session $session
