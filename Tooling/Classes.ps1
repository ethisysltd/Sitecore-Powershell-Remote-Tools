class ToolingConfiguration
{
    [ValidateNotNullOrEmpty()][string]$SystemInstallPath
    [ValidateNotNullOrEmpty()][string]$TemplateInstallPath
    [ValidateNotNullOrEmpty()][ToolingItem[]]$Items
    [ValidateNotNullOrEmpty()][ToolingItem[]]$Templates
}

class ToolingItem {
    [ValidateNotNullOrEmpty()][string]$Id
    [ValidateNotNullOrEmpty()][string]$Template
    [ValidateNotNullOrEmpty()][string]$Name
    [string]$DisplayName
    [string]$Icon
    [string]$FieldType
    [PSCustomObject[]]$Children
    [bool]$IsBucket
    [bool]$Bucketable
}