Function Invoke-CreateToolingItem {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ParentPath,
        [Parameter(Mandatory = $true)]
        [ToolingItem]$Item
    )

    try {
        $newItem = New-Item `
        -Path $ParentPath `
        -Name $Item.Name `
        -ItemType $Item.Template `
        -ForceId $Item.Id

        $newItem.Editing.BeginEdit()
        if($null -ne $Item.DisplayName) {
            $newItem["__Display name"] = $Item.DisplayName 
        }
        if($null -ne $Item.Icon) {
            $newItem["__Icon"] = $Item.Icon
        }

        # Sitecore Template Field
        if($Item.Template -eq "/sitecore/templates/System/Templates/Template field") {
            $newItem["Type"] = $Item.FieldType 
        }

        $newItem.Editing.EndEdit()
    } catch {
        Write-Output "ERROR at Invoke-CreateToolingItem:`n$($_.Exception.Message)"
    }
   
    

    # Create any children
    if($null -ne $Item.Children) {
        $Item.Children | ForEach-Object {
            try {
                Invoke-CreateToolingItem -ParentPath "master:/$($newItem.Paths.FullPath)" -Item $_
            } catch {
                Write-Output "ERROR at Invoke-CreateToolingItem:Creating children:`n$($_.Exception.Message)"
            }
        }
    }
}