Function Get-SitecoreItemUpdateStatus {
    param(
        [Parameter(Mandatory = $true)]
        [boolean]$UpdateResult
    )
    if($UpdateResult) {
        Write-Output "Status: Changes applied"
    } else {
        Write-Output "Status: Nothing to change"
    }
}