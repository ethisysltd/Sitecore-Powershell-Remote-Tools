# Global Variables
$EventLogTemplateId = "{BAA3EE07-86AE-4B7F-8C9B-FE83E17DD416}"


Function New-ScriptEventLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptFilePath,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Session
    )

    $setupcript = Get-EventLogSetupScript -ScriptFilePath $ScriptFilePath

    $createLogItemScript = [System.Management.Automation.ScriptBlock]{

        try {
            $config = [ToolingConfiguration]($configString | ConvertFrom-Json)

            # Sitecore Item Name
            $itemName = $itemRelativePath | Split-Path -Leaf
            # Generate ScriptBlock Hash
    
            # Find Templates in Config
            $powerShellToolsetItem = $config.Items | Where-Object {$_.Id -eq "{7F6AA771-B788-4ED4-A6BA-53B9259E6BF0}"} | Select-Object -First 1
            $eventLogFolderItem = $config.Items.Children | Where-Object {$_.Id -eq "{B658A082-320E-44DE-9262-2464557F8C2B}"} | Select-Object -First 1
            $eventLogFolderPath = "$($config.SystemInstallPath)/$($powerShellToolsetItem.Name)/$($eventLogFolderItem.Name)"
           
            # Create new Sitecore Item and set fields
            $newLogItem = New-Item `
                -Path $eventLogFolderPath `
                -Name $itemName `
                -ItemType $EventLogTemplateId
            
            $newLogItem.Editing.BeginEdit()
            $newLogItem["ScriptName"] = $itemRelativePath
            $newLogItem["FileHash"] = $fileHash
            $newLogItem.Editing.EndEdit()

        } catch {
            Write-Output "ERROR at New-ScriptEventLog`n$($_.Exception.Message)"
            Write-Output $Error[0].InvocationInfo
        }           
    }

    $configWithCreateLogItemScript = [System.Management.Automation.ScriptBlock]::Create("$setupcript`n$createLogItemScript`n")

    Invoke-ExecuteScript -Script $configWithCreateLogItemScript -Session $Session
   
}

Function Get-ScriptEventStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptFilePath,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Session
    )

    $setupcript = Get-EventLogSetupScript -ScriptFilePath $ScriptFilePath

    # Search for existing PowerShellToolsetEventLog items with the same name
    $findLogItemScript = [System.Management.Automation.ScriptBlock]{

        # Sitecore Item Name
        $itemName = $itemRelativePath | Split-Path -Leaf

        $criteria = @(            
            @{ Filter = "Equals"; Field = "_templatename"; Value = "PowerShellToolsetEventLog"; }, 
            @{ Filter = "DescendantOf"; Value = (Get-Item -Path master: -ID "{B658A082-320E-44DE-9262-2464557F8C2B}"); }
        )

        $props = @{
            Index = "sitecore_master_index"
            Criteria = $criteria
        }

        $allEventLogItems = Find-Item @props | Initialize-Item | Where-Object {$_.Name -eq $itemName -And $_.FileHash -eq $fileHash }
        
        $hasResults = if ($allEventLogItems.Count -gt 0) { $true } else { $false }
      
        Write-Output $hasResults
       
    }

    $configWithFindLogItemScript = [System.Management.Automation.ScriptBlock]::Create("$setupcript`n$findLogItemScript`n")

    Invoke-ExecuteScript -Script $configWithFindLogItemScript -Session $Session

}

Function Get-ScriptFileHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptFilePath
    )

    return (Get-FileHash -Path $ScriptFilePath).Hash
}

Function Invoke-ExecuteScript {
    param(
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$Script,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Session
    )
    #Write-Host $Script -ForegroundColor Yellow

    $jobId = Invoke-RemoteScript `
        -Session $Session `
        -ScriptBlock $Script `
        -AsJob

    if (!$jobId) { 
        Write-Warning "No jobId was created."
        
    } else {
        Wait-RemoteScriptSession `
            -Session $Session `
            -Id $jobId `
            -Delay 1 `
    }
}

Function Get-EventLogSetupScript {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptFilePath
    )
    
    $scriptFileItem = Get-Item $ScriptFilePath 
    $itemRelativePath = $scriptFileItem | Resolve-Path -Relative

    # Generate File Hash
    $fileHash = Get-ScriptFileHash -ScriptFilePath $ScriptFilePath

    $configScriptBlock = Get-ConfigScriptBlock 
    $variablesScriptBlock = [Scriptblock]::Create("
    `$itemRelativePath = `'$itemRelativePath`'`n
    `$fileHash = `'$fileHash`'`n
    `$EventLogTemplateId = `'$EventLogTemplateId`'`n
    ")
    return [System.Management.Automation.ScriptBlock]::Create("$configScriptBlock`n$variablesScriptBlock`n")
}