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
$scriptFolderName = "Current"
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
    # Create ScriptBlock
    $scriptblock = Get-Command $_.FullName | Select-Object -ExpandProperty ScriptBlock 
    # Get script event status 
    $hasAlreadyRun = [boolean](Get-ScriptEventStatus -ScriptFilePath $_.FullName -Session $session)

    # If the script hasn't previously run
    if($hasAlreadyRun -eq $false) {
        Write-Host "Executing $_" -ForegroundColor Green
        # Add Script Logging
        New-ScriptEventLog -ScriptFilePath $_.FullName -Session $session

        #Combine scriptblock with SPE reusable Functions
        $scriptblockWithFunctions = [System.Management.Automation.ScriptBlock]::Create("$speFunctions`n$scriptblock")
        
        # Create new job referencing $script from imported Powershell Script
        $jobId = Invoke-RemoteScript `
            -Session $session `
            -ScriptBlock $scriptblockWithFunctions `
            -AsJob 

        # Check if a job was created. If we don't have an id, something is wrong
        if (!$jobId) { 
            Write-Warning "No jobId was created. Please check if your Powershell Remoting is activated on the target instance '$SitecoreInstanceUri'`nRemember to have the Execution Policy set to: Set-ExecutionPolicy RemoteSigned -Scope Process"
            
        } else {
            Wait-RemoteScriptSession `
            -Session $session `
            -Id $jobId `
            -Delay 2
        }

    }
 
}

Stop-ScriptSession -Session $session