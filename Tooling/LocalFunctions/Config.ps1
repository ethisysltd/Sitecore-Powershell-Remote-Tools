Function Get-Config {
    $parent = Split-Path -Path $PSScriptRoot -Parent
    $configFile = Join-Path -Path $parent -ChildPath "spe-tooling.config.json"
    $toolingConfiguration = (Get-Content $configFile | Out-String | ConvertFrom-Json)
    return $toolingConfiguration
}

Function Get-ConfigClassesScriptBlock {
    $parent = Split-Path -Path $PSScriptRoot -Parent
    $classesFile = (Join-Path -Path $parent -ChildPath "Classes.ps1") 
    return Get-Command $classesFile | Select-Object -ExpandProperty ScriptBlock 
}

Function Get-ConfigScriptBlock {
    $toolingConfiguration = Get-Config
    $toolingConfigurationJson = $toolingConfiguration | ConvertTo-Json -Depth 100
    $configScriptBlock = [Scriptblock]::Create("`$configString = `'$toolingConfigurationJson`'" )
    $configClassesScriptBlock = Get-ConfigClassesScriptBlock
    return [System.Management.Automation.ScriptBlock]::Create("$configClassesScriptBlock`n$configScriptBlock`n")
}