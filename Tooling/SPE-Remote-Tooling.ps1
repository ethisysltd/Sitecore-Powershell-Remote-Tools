
###
### Create items in sitecore where updates events can be stored and tracked.
###

# 1. Check if this has been installed on the context enviroment. 
#   1.1 Install if missing
#
# 2. Create Function to record SPE event

Function Get-Config {
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "spe-tooling.config.json"
    $toolingConfiguration = (Get-Content $configFile | Out-String | ConvertFrom-Json)
    return $toolingConfiguration
}

Function Invoke-DoesItemExist {
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Item
    )
    return $Item.PSTypeNames -Contains "Deserialized.Sitecore.Data.Items.Item"
}

<#
.DESCRIPTION
Determine if the toolset items have been already installed
#> 
Function Invoke-InstallCheck {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "SitecorePassword")]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SitecoreInstanceUri,
        [Parameter(Mandatory = $true)]
        [string]$SitecoreUsername,
        [Parameter(Mandatory = $true)]
        [string]$SitecorePassword
    )
    $config = Get-Config

    $fistInstalledItemPath = "$($config.SystemInstallPath)/$($config.Templates[0].Name)"

    $session = New-ScriptSession `
        -Username $SitecoreUsername `
        -Password $SitecorePassword `
        -ConnectionUri $SitecoreInstanceUri

    $getRootItemScript = [System.Management.Automation.ScriptBlock]::Create("Get-Item -Path $fistInstalledItemPath")

    $result = Invoke-RemoteScript -Session $session -ScriptBlock $getRootItemScript
    Stop-ScriptSession -Session $session

    return Invoke-DoesItemExist -Item $result
}

Function Get-SetupSitecoreItemsScript {   
    $toolingConfiguration = Get-Config
    $toolingConfigurationJson = $toolingConfiguration | ConvertTo-Json -Depth 100
    $configScriptBlock = [Scriptblock]::Create("`$configString = `'$toolingConfigurationJson`'" )

    # Setup Items
    $setupScript = [System.Management.Automation.ScriptBlock]{

        $config = [ToolingConfiguration]($configString | ConvertFrom-Json)

        $config.Templates | ForEach-Object {
            try {
                $item = [ToolingItem]$_
                Invoke-CreateToolingItem -ParentPath $config.TemplateInstallPath -Item $item
            } catch {
                Write-Output "ERROR at SetupSitecoreItemsScript`n$($_.Exception.Message)"
            }
        }

        $config.Items | ForEach-Object {
            try {
                $item = [ToolingItem]$_
                Invoke-CreateToolingItem -ParentPath $config.SystemInstallPath -Item $item
            } catch {
                Write-Output "ERROR at SetupSitecoreItemsScript`n$($_.Exception.Message)"
            }
           
        }
    }
    $configWithSetupScript = [System.Management.Automation.ScriptBlock]::Create("$configScriptBlock`n$setupScript`n")
    Write-Output $configWithSetupScript
}

Function Invoke-Setup {
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "SitecorePassword")]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SitecoreInstanceUri,
        [Parameter(Mandatory = $true)]
        [string]$SitecoreUsername,
        [Parameter(Mandatory = $true)]
        [string]$SitecorePassword,
        [Parameter(Mandatory = $true)]
        [switch]$Force
    )

    $isInstalled = Invoke-InstallCheck `
        -SitecoreInstanceUri $SitecoreInstanceUri `
        -SitecoreUsername $SitecoreUsername `
        -SitecorePassword $SitecorePassword

    
    # If already installed then drop out
    if($isInstalled -And $Force -eq $false) {
        return
    }

    Write-Host "Installing SPE Toolset....." -ForegroundColor Green

    # Import Classes
    $classesFile = (Join-Path -Path $PSScriptRoot -ChildPath "Classes.ps1") 
    Import-Module $classesFile
    $classesScriptBlock = Get-Command $classesFile | Select-Object -ExpandProperty ScriptBlock 

    # Add Classes to the top of SPE functions
    $speFunctions = $classesScriptBlock;
    $functionsFolder = "$PSScriptRoot\Functions"
    Get-ChildItem $functionsFolder -Filter *.ps1 | Foreach-Object {
        $function = Get-Command (Join-Path -Path $functionsFolder -ChildPath $_) | Select-Object -ExpandProperty ScriptBlock 
        $speFunctions = [System.Management.Automation.ScriptBlock]::Create("$speFunctions`n$function`n")
    }

    $setupItemsScript = Get-SetupSitecoreItemsScript
    # Combine all imports with setup script
    $scriptblockWithFunctions = [System.Management.Automation.ScriptBlock]::Create("$speFunctions`n$setupItemsScript")

    $session = New-ScriptSession `
        -Username $SitecoreUsername `
        -Password $SitecorePassword `
        -ConnectionUri $SitecoreInstanceUri

    $jobId = Invoke-RemoteScript `
        -Session $session `
        -ScriptBlock $scriptblockWithFunctions `
        -AsJob 

    if (!$jobId) { 
        Write-Warning "No jobId was created. Please check if your Powershell Remoting is activated on the target instance '$SitecoreInstanceUri'`nRemember to have the Execution Policy set to: Set-ExecutionPolicy RemoteSigned -Scope Process"
        
    } else {

        Wait-RemoteScriptSession `
            -Session $session `
            -Id $jobId `
            -Delay 5 

        # Invoke-RemoteScript -Session $session -ScriptBlock {
        #     $ss = Get-ScriptSession -Id $using:JobId
        #     $ss | Receive-ScriptSession

        #     Write-Host $ss
        #     if($ss.LastErrors) {
        #         $ss.LastErrors
        #     }
        # }

        Stop-ScriptSession -Session $session
    }

}

