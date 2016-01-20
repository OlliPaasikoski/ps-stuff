# Fill in target site URL and credentials

$siteURL = ""

$username = ""
$pw = "" 
$password = ConvertTo-SecureString $pw -AsPlainText -Force 
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $password)

$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteURL)
$ctx.Credentials = $credentials

$rootWeb = $ctx.Web
$ctx.Load($rootWeb)

$ctx.ExecuteQuery()

function IterateFoldersInSubsites($spoSite, $folderNameArray) {

    Write-Host "`nScanning Site: $($spoSite.Url)" -ForegroundColor Yellow

    $ctx.Load($spoSite.Webs)
    $ctx.ExecuteQuery()

    $index = 0

    if ($spoSite.Webs.Count -eq 0) {
        Write-Host "`nNo subsites in spoSite: $($spoSite.Url)"
    }
 
    foreach($subWeb in $spoSite.Webs)
    {
        # Recursively iterate subsites
        IterateFoldersInSubsites -spoSite $subWeb -folderNameArray $folderNameArray

        # When returns, do...
        Write-Host "`nScanning Pages in Web: $($subWeb.Url)"
        
        foreach ($folderName in $folderNameArray)
        {
            $result = IteratePages -spoWeb $subWeb -folderName $folderName
            if ($result) {
                # OK
            }
            else {
                # NO FOLDER FOUND
            }
        }
    }
}

function IteratePages($spoWeb, $folderName) {
    
    Write-Host "Looking for folder '$($folderName)'" -NoNewline

    $pageList = $spoWeb.Lists.GetByTitle($folderName)
    $query = [Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery(100)
    $pageItems = $pageList.GetItems($query)

    try 
    {
        $ctx.Load($pageList)
        $ctx.Load($pageItems)
        $ctx.ExecuteQuery() 
    }
    catch
    {
        Write-Host  "... was not found."
        return $false
    }

    # So now we our List and it's items

    if ($pageList.ItemCount -ne 0) 
    {
        Write-Host "Found $($pageList.ItemCount) pages in $($pageList.Title)..."
        
        $index = 1

        foreach($page in $pageItems) 
        {
            $file = $page.File
            $ctx.Load($page)
            $ctx.Load($file)
            $ctx.ExecuteQuery() 
            Write-Host "`n($($index)) Url: $($file.ServerRelativeUrl)"
            
            $wpManager = $file.GetLimitedWebPartManager([Microsoft.Sharepoint.Client.WebParts.PersonalizationScope]::Shared)
            
            $ctx.Load($wpManager)
            $ctx.ExecuteQuery()

            $webParts = $wpManager.WebParts
            $ctx.Load($webParts)
            $ctx.ExecuteQuery()

            Write-Host "Found $($wpManager.WebParts.Count) webparts in $($file.ServerRelativeUrl):`n"
            UpdateWebParts -webParts $webParts -chromeType $chromeType

            $index++
        }
    }
}

function UpdateWebParts($webParts, $chromeType) {

    foreach($wp in $webParts) { 

        $wpActual = $wp.WebPart
        $ctx.Load($wpActual)
        $ctx.ExecuteQuery() 

        Write-Host "Web Part: $($wpActual.Title)"

        $actualprops = $wpActual.Properties

        $ctx.Load($actualprops)
        $ctx.ExecuteQuery() 

        Write-Host "Looking for property ChromeType..." 

        if ($wpActual.Properties.FieldValues.ChromeType -ne $chromeType) 
        {
            Write-Host "ChromeType: $($wpActual.Properties.FieldValues.ChromeType)" -ForegroundColor yellow
            Write-Host "Updating Chrometype... " 
            $wpActual.Properties["ChromeType"] = $chromeType 
            Write-Host "Current Chrometype: $($wpActual.Properties.FieldValues["ChromeType"])" -ForegroundColor green
            $wp.SaveWebPartChanges(); 
        }
        else {
            Write-Host "ChromeType: $($wpActual.Properties.FieldValues.ChromeType) OK "
        }
        
        try {
            $ctx.ExecuteQuery() 
        }    
        catch {
            Write-Host "`nProblem updating ChromeType for $($wpActual.Title)" -ForegroundColor red
            Write-Host $_
        } 
    }      
}

# Edit following parameters to match your intranet's folder structure and the wanted chrometype
[string[]] $folderNameArray = "Site Pages", "Pages"
[int] $chromeType = 0

cls
Write-Host "$($folderNameArray.Count) folder names defined"
IterateFoldersInSubsites -spoSite $rootWeb -folderNameArray $folderNameArray

foreach ($folderName in $folderNameArray)
{
    $result = IteratePages -spoWeb $rootWeb -folderName $folderName
    if ($result) {
        # OK
    }
    else {
        # NO FOLDER FOUND
    }
}
