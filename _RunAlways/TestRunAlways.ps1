# ---------------------------------------------------------------------------------- 
# Sitecore Home
# ---------------------------------------------------------------------------------- 
# Items: 
#   /sitecore/content/Home - {110D559F-DEA5-42EA-9C1C-8A5DF7E70EF9}

$dateTime = Get-Date -Format "dddd MM/dd/yyyy HH:mm"

$homeItem = Get-Item "master:/{110D559F-DEA5-42EA-9C1C-8A5DF7E70EF9}"
Update-SitecoreItemContent `
    -ItemId "{110D559F-DEA5-42EA-9C1C-8A5DF7E70EF9}" `
    -FieldUpdates @{
        "Text" = "$($homeItem.Text) `nI always run"
        }