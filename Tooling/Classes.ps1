class ToolingConfiguration
{
    [ValidateNotNullOrEmpty()][string]$InstallPath
    [ValidateNotNullOrEmpty()][Object[]]$Items
}

class ToolingItem {
    [ValidateNotNullOrEmpty()][string]$Name
    [string]$DisplayName
    [ValidateNotNullOrEmpty()][string]$Icon
    [ValidateNotNullOrEmpty()][string]$Id
    [ValidateNotNullOrEmpty()][string]$Template
    [Object[]]$Children
}