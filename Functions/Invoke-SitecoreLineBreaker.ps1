Function Invoke-SitecoreLineBreaker {
    param(
        [Parameter(Mandatory = $false)]
        [boolean]$NewLineFirst = $false
    )
    if($NewLineFirst) {
        Write-Output "`n-------------------------------------------------------------------------------"
    } else {
        Write-Output "`-------------------------------------------------------------------------------`n"
    }
}