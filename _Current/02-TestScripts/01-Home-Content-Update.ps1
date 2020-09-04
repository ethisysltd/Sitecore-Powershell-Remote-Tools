# ---------------------------------------------------------------------------------- 
# Sitecore Home
# ---------------------------------------------------------------------------------- 
# Items: 
#   /sitecore/content/Home - {110D559F-DEA5-42EA-9C1C-8A5DF7E70EF9}

$dateTime = Get-Date -Format "dddd MM/dd/yyyy HH:mm"
Update-SitecoreItemContent `
    -ItemId "{110D559F-DEA5-42EA-9C1C-8A5DF7E70EF9}" `
    -FieldUpdates @{
        "Title" = "Title field value updated at $dateTime"
        "Text" = "Text field value updated at $dateTime"
        }