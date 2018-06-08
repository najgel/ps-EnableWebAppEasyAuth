## Heavily inspired by https://blogs.msdn.microsoft.com/azuregov/2017/12/06/web-app-easy-auth-configuration-using-powershell/ Thanks!!!


param(
 
    # Parameter help description
    [Parameter(Mandatory=$true,Position=1)]
    [string]$ResourceGroupName,
 
    [Parameter(Mandatory=$true,Position=2)]
    [string]$WebAppName,
 
    #Issuer is the aad
    [Parameter(Mandatory=$false,Position=4)]
    [string]$IssuerUrl = ""
 
)

$AppID = (Get-AzureRmADApplication -DisplayName $WebAppName).ApplicationId.Guid

if([string]::IsNullOrEmpty($AppID)){
    New-AzureRmADApplication -DisplayName $WebAppName -IdentifierUris "https://$WebAppName.azurewebsites.net"
    $global:AppID = (Get-AzureRmADApplication -DisplayName $WebAppName).ApplicationId.Guid
}

if([string]::IsNullOrEmpty($IssuerUrl)){
    $stsId=(Get-AzureRmTenant)[0].Id
    $global:IssuerUrl = "https://sts.windows.net/$stsId/"
}



$authResourceName = $WebAppName + "/authsettings"

$auth = Invoke-AzureRmResourceAction -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/config -ResourceName $authResourceName -Action list -ApiVersion 2016-08-01 -Force
 
$auth.properties.enabled = "True"
$auth.properties.unauthenticatedClientAction = "RedirectToLoginPage"
$auth.properties.tokenStoreEnabled = "True"
$auth.properties.defaultProvider = "AzureActiveDirectory"
$auth.properties.isAadAutoProvisioned = "False"
$auth.properties.clientId = $ClientId
$auth.properties.issuer = $IssuerUrl

New-AzureRmResource -PropertyObject $auth.properties -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/config -ResourceName $authResourceName -ApiVersion 2016-08-01 -Force
