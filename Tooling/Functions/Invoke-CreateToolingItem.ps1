Function Invoke-CreateToolingItem {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ParentPath,
        [Parameter(Mandatory = $true)]
        [ToolingItem]$Item
    )

    $newItem = New-Item `
        -Path $ParentPath `
        -Name $Item.Name `
        -ItemType $Item.Template `
        -ForceId $Item.Id

    $newItem.Editing.BeginEdit()
    $newItem["__Display name"] = $Item.DisplayName 
    $newItem["__Icon"] = $Item.Icon
    $newItem.Editing.EndEdit()

    # Create any children
    if($null -ne $Item.Children) {
        $Item.Children | ForEach-Object {
            Invoke-CreateToolingItem -ParentPath "master:/$($newItem.Paths.FullPath)" -Item $_
        }
    }
}