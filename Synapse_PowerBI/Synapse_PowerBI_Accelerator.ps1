#Requires -RunAsAdministrator
#Requires -Version 7.2.6   
<#
 Author      :  Jameel Ahmed 
 Created Date:  2022-11-07 
 Note        : 
 Prerequsites: PBI pro account, Azure Subscription and Azure Synapse Workspace. 
               Sample PBIX file with Azure SQL connection. 

 Purpose:     This script automates the creation a Power BI Workspace, grants accounts permissions to that workspace then uploads a PBIX file into the workspace. 
              Sets the PBI Dataset Parameter values. 
              Then creates a Synapse Linked Service to the PBI workspace.
#> 

#----------------------------------------------------------------------------------
#region TODO: SET VARIABLE VALUES
$SubscriptionName = "Azure Dev Subscription" 
$TenantId =         "001e9f8e-e005-e811-80f6-3863bb2e34f8"
$SynapseWorkspaceName = "synapsedev"
$PBIWorkspaceName = "Demo Dev"
$PBIXFileName = "c:\temp\Adventureworks DW Dataset for Synapse.pbix" #PBIX File to Upload

#Overwrite Default PBIX Parameter Values with following
$ParmMinDate  =  "19990909"  
$SQLServerName  = "SQLJam.database.windows.net"  

#PBI WorkSpace User and Access settings  //https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.workspaces/add-powerbiworkspaceuser
$PowerBIWorkspaceUser ='[{"PrincipalType":"User" ,"Identifier":"admin@microsoft.com"   ,"AccessRight":"Admin"}
        ,{"PrincipalType":"User" ,"Identifier":"contributor@microsoft.com"   ,"AccessRight":"Contributor"}
        ,{"PrincipalType":"User" ,"Identifier":"member@microsoft.com"  ,"AccessRight":"Member"}
        ,{"PrincipalType":"User" ,"Identifier":"viewer@microsoft.com" ,"AccessRight":"Viewer"}
        ]'
#endregion ----------------------------------------------------------------------------------


#region 0. Initialize Variables
    Clear-Host 
    $ErrorActionPreference = "Stop"
    $LSjsonfile = "$($env:TEMP)\PBILinkedService.json"  #temp filename to contain Linked service Json content.  
    $LinkedServiceName = "LS_PBI_$PBIWorkspaceName"
#endregion 

#region 1. Install Powershell Modules
    $execPolicy = Get-ExecutionPolicy  #Get Current Value before changing it.
    #Set-ExecutionPolicy -ExecutionPolicy Unrestricted

    if (!(Get-Module -Name MicrosoftPowerBIMgmt  -ListAvailable)) {
      Write-Host "Installing MicrosoftPowerBIMgmt Module" -ForegroundColor Green
      Install-Module -Name MicrosoftPowerBIMgmt -Repository PSGallery -Force 
    }

    if (!(Get-Module -Name "Az.Synapse"  -ListAvailable)) {
      Write-Host "Installing Az.Synapse Module" -ForegroundColor Green
      Install-Module -Name "Az.Synapse" -Repository PSGallery -Force -AllowClobber 
    }

    if (!(Get-Module -Name "Az.Accounts"  -ListAvailable)) {
      Write-Host "Installing Az.Accounts Module" -ForegroundColor Green
    Install-Module Az.Accounts  -Repository PSGallery -AllowClobber -SkipPublisherCheck -Scope AllUsers -Force
    }

    if (!(Get-Module -Name "Az"  -ListAvailable)) {
      Write-Host "Installing Az Module" -ForegroundColor Green
    Install-Module -Name Az -AllowClobber -SkipPublisherCheck -Scope AllUsers
    }

    #Import-Module "MicrosoftPowerBIMgmt"
    #Import-Module Az
#endregion

#region 2. Log into Azure Service and Power BI Service
    Write-Host "Logging into Azure Service" -ForegroundColor Green  
    if (!($az)) {$az=Connect-AzAccount -Tenant $TenantId  -Subscription $SubscriptionName  #if you have multiple tenants or subscriptions then use these parameters to be specific. 
     #Set-AzContext
    }
    $az

    Write-Host "Logging into Power BI Service" -ForegroundColor Green  
    if (!($pbiconn)) {$pbiconn = Connect-PowerBIServiceAccount }  
    $pbiconn 
#endregion 

#region 3. Create PBI Workspace
    $oPBIWorkspaceName = Get-PowerBIWorkspace -Name $PBIWorkspaceName
    if (!($oPBIWorkspaceName)){
       Write-Host "Creating Power BI Workspace [$PBIWorkspaceName]" -ForegroundColor Green   
       $oPBIWorkspaceName =New-PowerBIWorkspace -Name $PBIWorkspaceName
       $sec=20
       Write-Host "Waiting $sec seconds" -ForegroundColor Yellow   
       Start-Sleep -Seconds $sec  # takes a while for new ws to appear in pbi
     }  
#endregion

#region 4. Get Current list of PBI Workspace Accesses and Grant the Access.  
    $oPowerBIWorkspaceUser = $PowerBIWorkspaceUser|convertfrom-json 
    $CurrentUsers = (ConvertFrom-Json(Invoke-PowerBIRestMethod -Method Get -Url "https://api.powerbi.com/v1.0/myorg/groups/$($oPBIWorkspaceName.Id)/users" )).value
    $i = 0
    $oPowerBIWorkspaceUser|foreach { 
        $curUser =$null 
        $curUser = ($CurrentUsers|where {$_.emailAddress -eq $oPowerBIWorkspaceUser[$i].Identifier})
        if ($curUser -ne $null){           
              if ($curUser.groupUserAccessRight -ine $oPowerBIWorkspaceUser[$i].AccessRight)
              { 
                Write-Host  "UPDATE   : [$($_.Identifier)] access to PBI Workspace [$($oPBIWorkspaceName.Name)] being changed from $($curUser.groupUserAccessRight) to $($oPowerBIWorkspaceUser[$i].AccessRight)."  -ForegroundColor Green        
                Remove-PowerBIWorkspaceUser  -Id ($oPBIWorkspaceName.Id) -UserPrincipalName ($_.Identifier)
                Add-PowerBIWorkspaceUser     -Id ($oPBIWorkspaceName.Id) -AccessRight ($_.AccessRight)  -PrincipalType ($_.PrincipalType) -Identifier ($_.Identifier)             
              }else{
                Write-Host "NO CHANGE: [$($_.Identifier)] access to PBI Workspace [$($oPBIWorkspaceName.Name)] with $($oPowerBIWorkspaceUser[$i].AccessRight) access already exists."  -ForegroundColor Green
              }         
            } else {
                Write-Host "INSERT   : [$($_.Identifier)] access to PBI Workspace [$($oPBIWorkspaceName.Name)] being created with $($oPowerBIWorkspaceUser[$i].AccessRight) access."  -ForegroundColor Green
                Add-PowerBIWorkspaceUser  -Id ($oPBIWorkspaceName.Id) -AccessRight ($_.AccessRight)  -PrincipalType ($_.PrincipalType) -Identifier ($_.Identifier)
            }
        $i++
    }
#endregion

#region 5. Upload PBIX to PBI Workspace 
    Write-Host "Uploading ..... $PBIXFileName to Power BI Service." -ForegroundColor Green
    $Timeout = 999   #To Resolve Error from New-PowerBIReport: The request was canceled due to the configured HttpClient.Timeout of 100 seconds elapsing.
    $oRpt = $null
    $oRpt = (New-PowerBIReport -Path $PBIXFileName -Name ([System.IO.Path]::GetFileNameWithoutExtension($PBIXFileName)) -Workspace $oPBIWorkspaceName -ConflictAction CreateOrOverwrite -Timeout  600 )
    if ($oRpt -ne $null){ 
      Write-Host "ReportId of uploaded PBIx file is $($oRpt.Id)"
    }

    #Get reference to uploaded dataset
    $oPBIDataset = Get-PowerBIDataset -Workspace $oPBIWorkspaceName |Where-Object {$_.Name -eq ([System.IO.Path]::GetFileNameWithoutExtension($PBIXFileName))}
#endregion

#region 6. Get Parameters from DataSet
    $oParams = (ConvertFrom-Json( Invoke-PowerBIRestMethod -Method Get -Url "https://api.powerbi.com/v1.0/myorg/datasets/$($oPBIDataset.Id)/parameters")).Value

    Write-Host "Current Parameter Values" -ForegroundColor Green
    $oParams 
#endregion 

#region 7. Set New Parameter values for PBI DataSet. 
    $body = ConvertTo-Json -InputObject @{updateDetails = @(
            @{ name     = 'ParmMinDate'
               newValue = $ParmMinDate
             },
            @{ name     = 'SQL Server'
               newValue = $SQLServerName
             }  
    )}

    Write-Host "Setting New Parameter Values" -ForegroundColor Green
    Invoke-PowerBIRestMethod -Method Post -Url "https://api.powerbi.com/v1.0/myorg/datasets/$($oPBIDataset.Id)/Default.UpdateParameters"  -Body $body 
    $body

    #Get DataSources of the Dataset. Verify DataSource was updated with new Parameter values.
    $oDataSource = (ConvertFrom-Json(Invoke-PowerBIRestMethod -Method Get  -Url "https://api.powerbi.com/v1.0/myorg/datasets/$($oPBIDataset.Id)/datasources")).value 
#endregion

#region 8. Create Synapse Linked Service Json file. 
    Write-Host "Creating Synapse Linked Service JSON file at $LSjsonfile" -ForegroundColor Green
    $LinkedServiceName = "LS_PBI_$PBIWorkspaceName"
    $LinkedServiceJson = ConvertTo-Json -InputObject ([ordered]@{
      name   = $LinkedServiceName
      type   = 'Microsoft.Synapse/workspaces/linkedservices'
      properties = [ordered]@{
        "annotations" = @()
        "type" = 'PowerBIWorkspace'
        "typeProperties"= @{
           "workspaceID" = $oPBIWorkspaceName.Id
           "tenantID" = $pbiconn.TenantId 
        }
      }
    })
    Remove-item $LSjsonfile -Force -ErrorAction SilentlyContinue #Delete existing file.
    $LinkedServiceJson |Out-File $LSjsonfile
#endregion

#region 9. Create Synapsed Linked Service to PBI Workspace
    Write-Host "Connecting to Synapse Workspace [$SynapseWorkspaceName]" -ForegroundColor Green 
    $oSynWs = Get-AzSynapseWorkspace -Name $SynapseWorkspaceName
    #TODO: create synapse workspace if not exist. 
    $PBILS=Get-AzSynapseLinkedService -Workspacename $SynapseWorkspaceName -Name $LinkedServiceName -ErrorAction Ignore

    if (!($PBILS)){
        Write-Host "Creating Synapse PBI Linked Service [$LinkedServiceName]" -ForegroundColor Green
        $PBILS = Set-AzSynapseLinkedService -Workspacename $SynapseWorkspaceName -Name $LinkedServiceName  -DefinitionFile $LSjsonfile
       }
    $PBILS
#endregion




#revert ExecutionPolicy
$execPolicy| Set-ExecutionPolicy -Force
