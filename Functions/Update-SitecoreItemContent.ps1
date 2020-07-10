Function Update-SitecoreItemContent {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ItemId,
        [Parameter(Mandatory = $true)]
        [hashtable]$FieldUpdates
    )

    $item = Get-Item "master:/$ItemId"
    Invoke-LineBreaker -NewLineFirst $true
    Write-Output "Updating Fields for: $($item.FullPath)" 

    $item.Editing.BeginEdit()
    #Iterate FieldUpdates
    $FieldUpdates.GetEnumerator() | ForEach-Object {
        $fieldName = $_.Key
        $fieldValue = $_.Value
        # Check fieldName isn't null
        
        if($null -ne $fieldName) {
            Write-Output "`t$($fieldName): $($fieldValue[0..(60)] -join '')"
            $item.Fields[$fieldName].Value = $fieldValue
        } 
    }
    $updated = $item.Editing.EndEdit()
    Invoke-SitecoreItemUpdateStatus -UpdateResult $updated
    Invoke-SitecoreLineBreaker

}