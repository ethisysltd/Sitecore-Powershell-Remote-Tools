
Function Invoke-ExecuteSPEScript {
    param(
        [Parameter(Mandatory = $true)]
        [Object]$File,
        [Parameter(Mandatory = $false)]
        [switch]$ExcludeRunCheck
    )
     # Create ScriptBlock
     $scriptblock = Get-Command $File.FullName | Select-Object -ExpandProperty ScriptBlock 
     # Get script event status 
     $hasAlreadyRun = [boolean](Get-ScriptEventStatus -ScriptFilePath $File.FullName -Session $session)
 
     # If the script hasn't previously run
     if($hasAlreadyRun -eq $false -Or $ExcludeRunCheck) {
         Write-Host "Executing $File" -ForegroundColor Green

         # Only and Logging if ExcludeRunCheck is false
         if($ExcludeRunCheck -eq $false) {
            # Add Script Logging
            New-ScriptEventLog -ScriptFilePath $File.FullName -Session $session
         }
       
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