Function Update-SitecoreItemSecurity {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ItemId,
        [Parameter(Mandatory = $true)]
        [String]$SecurityValues
    )

    $fieldUpdates = @{
        "__Security" = $SecurityValues
    }
    Update-SitecoreItemContent -ItemId $ItemId -FieldUpdates $fieldUpdates
}

Function Update-SitecoreMultipleItemSecurity {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [String[]]$ItemIds,
        [Parameter(Mandatory = $true)]
        [String]$SecurityValues
    )

    $ItemIds | ForEach-Object {
        Update-ItemSecurity -ItemId $_ -SecurityValues $SecurityValues
    }
}