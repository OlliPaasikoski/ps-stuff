
$testsite = ""
$credentials = ""

try
{

    # Set credentials for access to site context
    $ctx = New-Object Microsoft.SharePoint.Client.ClientContext($testsite)
    $ctx.Credentials = $credentials

    # Create reference to the root of the site collection
    $siteCollection = $ctx.Web

    # Create reference to sites in root

    $sites = $siteCollection.Webs

    $ctx.Load($siteCollection)
    $ctx.Load($sites)

    $ctx.ExecuteQuery()

    Write-Host "`nIterating sites in site collection:`n" -ForegroundColor red


    ###############################################################
    ################# SITE COLLECTION ROOT SITE ###################

    $rootpagelist = $siteCollection.Lists.GetByTitle("Site Pages")
    $ctx.Load($rootpagelist)
    $ctx.ExecuteQuery() 

    $query = [Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery(100)
    $rootpages = $rootpagelist.GetItems($query)

    $ctx.Load($rootpages)
    $ctx.ExecuteQuery() 

    Write-Host $siteCollection.Title "contains" $rootpages.Count "pages:`n" -ForegroundColor yellow

    $rootpages | foreach {
        $file = $_.File
        $ctx.Load($file)
        $ctx.ExecuteQuery() 
        Write-Host $file.ServerRelativeUrl

        $page = $siteCollection.GetFileByServerRelativeUrl($file.ServerRelativeUrl)

        $wpManager = $page.GetLimitedWebPartManager([Microsoft.Sharepoint.Client.WebParts.PersonalizationScope]::Shared)
        $wps = $wpManager.WebParts

        $ctx.Load($page)
        $ctx.Load($wps)
        $ctx.ExecuteQuery() 

        Write-Host "`nIterating Web Parts on page: " $file.ServerRelativeUrl -ForegroundColor yellow

        foreach($wp in $wps) { 
            
            $wpActual = $wp.WebPart
            $ctx.Load($wps)
            $ctx.Load($wpActual)
            $ctx.ExecuteQuery() 

            Write-Host "`nWeb Part: " $wpActual.Title

            $actualprops = $wpActual.Properties

            $ctx.Load($actualprops)
            $ctx.ExecuteQuery() 

            Write-Host "Looking for property ChromeType..." 
            Write-Host "ChromeType: " $wpActual.Properties.FieldValues.ChromeType -ForegroundColor red
            Write-Host "Changing Chrometype to 1 [Title and Border] ... " 
            $wpActual.Properties["ChromeType"] = 1
            Write-Host "Current Chrometype:" $wpActual.Properties.FieldValues["ChromeType"] -ForegroundColor green

            $wp.SaveWebPartChanges()
        }

        $ctx.ExecuteQuery() 
    }

    ###############################################################
    ################# SITE COLLECTION SUBSITES ####################

    foreach($site in $sites) {
 
        $pagelist = $site.Lists.GetByTitle("Site Pages")

        $ctx.Load($pagelist)
        $ctx.ExecuteQuery()

        $query = [Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery(100)
        $pages = $pagelist.GetItems($query)

        $ctx.Load($pages)
        $ctx.ExecuteQuery() 

        Write-Host
        Write-Host $site.Title "contains" $pages.Count "pages:`n" -ForegroundColor yellow

        $pages | foreach {

            $file = $_.File
            $ctx.Load($file)
            $ctx.ExecuteQuery() 
            Write-Host $file.ServerRelativeUrl

            $page = $siteCollection.GetFileByServerRelativeUrl($file.ServerRelativeUrl)

            $wpManager = $page.GetLimitedWebPartManager([Microsoft.Sharepoint.Client.WebParts.PersonalizationScope]::Shared)
            $wps = $wpManager.WebParts

            $ctx.Load($page)
            $ctx.Load($wps)
            $ctx.ExecuteQuery() 

            Write-Host "`nIterating Web Parts on page: " $file.ServerRelativeUrl -ForegroundColor red

            try {
                foreach($wp in $wps) { 
            
                    $wpActual = $wp.WebPart
                    $ctx.Load($wps)
                    $ctx.Load($wpActual)
                    $ctx.ExecuteQuery() 

                    Write-Host "`nWeb Part: " $wpActual.Title

                    $actualprops = $wpActual.Properties
                    #$fieldvalues = $wpActual.Properties.FieldValues
                    $ctx.Load($actualprops)
                    $ctx.ExecuteQuery() 

                    Write-Host "Looking for property ChromeType..." 
                    Write-Host "ChromeType: " $wpActual.Properties.FieldValues.ChromeType -ForegroundColor red
                    Write-Host "Changing Chrometype to 1 [Title and Border] ... " 
                    $wpActual.Properties["ChromeType"] = 1
                    Write-Host "Current Chrometype:" $wpActual.Properties.FieldValues["ChromeType"] -ForegroundColor green

                    $wp.SaveWebPartChanges()
                }

                
            }
            catch [System.Exception]
            {
                Write-Host "Something went wrong, continuing..."
            }

            $ctx.ExecuteQuery() 

        }
    }

    $ctx.Dispose()
}
catch [System.Exception]
{
    Write-Host -f red $_.Exception.ToString()   
}   


