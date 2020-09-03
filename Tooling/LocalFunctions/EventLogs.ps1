Function New-ScriptEventLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptFilePath,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Session
    )

    $toolingConfiguration = Get-Config
    $toolingConfigurationJson = $toolingConfiguration | ConvertTo-Json -Depth 100

    $scriptFileItem = Get-Item $scriptFilePath 
    $itemRelativePath = $scriptFileItem | Resolve-Path -Relative
    
    $configScriptBlock = Get-ConfigScriptBlock 
    $variablesScriptBlock = [Scriptblock]::Create("`$itemRelativePath = `'$itemRelativePath`'" )
    $setupcript = [System.Management.Automation.ScriptBlock]::Create("$configScriptBlock`n$variablesScriptBlock`n")

    $createLogItemScript = [System.Management.Automation.ScriptBlock]{

        try {
            $config = [ToolingConfiguration]($configString | ConvertFrom-Json)

            # Sitecore Item Name
            $itemName = $itemRelativePath | Split-Path -Leaf
            # Generate ScriptBlock Hash
            $fileHash = "hash goes here"
    
            # Find Templates in Config
            $eventLogTemplateId = "{BAA3EE07-86AE-4B7F-8C9B-FE83E17DD416}"
            $powerShellToolsetItem = $config.Items | Where-Object {$_.Id -eq "{7F6AA771-B788-4ED4-A6BA-53B9259E6BF0}"} | Select-Object -First 1
            $eventLogItem = $config.Items.Children | Where-Object {$_.Id -eq "{B658A082-320E-44DE-9262-2464557F8C2B}"} | Select-Object -First 1
            $eventLogPath = "$($config.SystemInstallPath)/$($powerShellToolsetItem.Name)/$($eventLogItem.Name)"
           
            # Create new Sitecore Item and set fields
            $newLogItem = New-Item `
                -Path $eventLogPath `
                -Name $itemName `
                -ItemType $eventLogTemplateId
            
            $newLogItem.Editing.BeginEdit()
            $newLogItem["ScriptName"] = $itemRelativePath
            $newLogItem["FileHash"] = $fileHash
            $newLogItem.Editing.EndEdit()

        } catch {
            Write-Output "ERROR at New-ScriptEventLog`n$($_.Exception.Message)"
        }           
    }

    $configWithCreateLogItemScript = [System.Management.Automation.ScriptBlock]::Create("$setupcript`n$createLogItemScript`n")

    Invoke-ExecuteScript -Script $configWithCreateLogItemScript -Session $Session
   
}

Function Invoke-ExecuteScript {
    param(
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$Script,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Session
    )

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
        -Delay 5
    }
}