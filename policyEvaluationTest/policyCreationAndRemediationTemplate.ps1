param
(
    [Parameter(Mandatory = $True)]
    [string[]]$resourceGroups,

    [Parameter(Mandatory = $True)]
    [string]$location,

    [Parameter(Mandatory =$True)]
    [string]$lmCompanyName,

    [Parameter(Mandatory =$True)]
    [string]$subscriptionId

)

$location = $location.replace(' ','').toLower()
$locationValidity=$True
$targetResourceGroup = 'lm-logs-' + $lmCompanyName + '-' + $location + '-group'
$eventhubNameSpace = $targetResourceGroup.replace('-group','')
$eventhubName = 'log-hub'
$eventhubAuthorizationId = 'RootManageSharedAccessKey'
for($resourceGroup in $resourceGroups){
	$resourceGroupDetails = Get-AzResourceGroup -Name $resourceGroup
	if($location -ne $resourceGroupDetails.Location.replace(' ','').toLower()){
		Write-Host "The ource resource groups are not in the same region...."
		$locationValidity=$False
		break
	}
}
Get-AzResourceGroup -Name $targetResourceGroup -ErrorVariable notPresent -ErrorAction SilentlyContinue

if ($notPresent)
{
    Write-Host "The target resource group is not present in the specified location or the lm_company_name is incorrect"
}
else
{
if($locationValidity){
If($ADO){write-host "ADO switch deprecated and no longer necessary" -ForegroundColor Yellow}
Write-Host "Authenticating to Azure..." -ForegroundColor Cyan
try
{
    $AzureLogin = Get-AzSubscription
    $currentContext = Get-AzContext

    # Establish REST Token
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($currentContext.Subscription.TenantId)
}
catch
{
    $null = Login-AzAccount -Environment $Environment
    $AzureLogin = Get-AzSubscription
    $currentContext = Get-AzContext

    # Establish REST Token
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($currentContext.Subscription.TenantId)
}

Try
{
    $Subscription = Get-AzSubscription -SubscriptionId $subscriptionId
}
catch
{
    Write-Host "Subscription not found"
    break
}

If($AzureLogin -and !($SubscriptionID))
{
    [array]$SubscriptionArray = Add-IndexNumberToArray (Get-AzSubscription)
    [int]$SelectedSub = 0

    # use the current subscription if there is only one subscription available
    if ($SubscriptionArray.Count -eq 1)
    {
        $SelectedSub = 1
    }
    # Get SubscriptionID if one isn't provided
    while($SelectedSub -gt $SubscriptionArray.Count -or $SelectedSub -lt 1)
    {
        Write-host "Please select a subscription from the list below"
        $SubscriptionArray | Select-Object "#", Id, Name | Format-Table
        try
        {
            $SelectedSub = Read-Host "Please enter a selection from 1 to $($SubscriptionArray.count)"
        }
        catch
        {
            Write-Warning -Message 'Invalid option, please try again.'
        }
    }
    if($($SubscriptionArray[$SelectedSub - 1].Name))
    {
        $SubscriptionName = $($SubscriptionArray[$SelectedSub - 1].Name)
    }
    elseif($($SubscriptionArray[$SelectedSub - 1].SubscriptionName))
    {
        $SubscriptionName = $($SubscriptionArray[$SelectedSub - 1].SubscriptionName)
    }
    write-verbose "You Selected Azure Subscription: $SubscriptionName"

    if($($SubscriptionArray[$SelectedSub - 1].SubscriptionID))
    {
        [guid]$SubscriptionID = $($SubscriptionArray[$SelectedSub - 1].SubscriptionID)
    }
    if($($SubscriptionArray[$SelectedSub - 1].ID))
    {
        [guid]$SubscriptionID = $($SubscriptionArray[$SelectedSub - 1].ID)
    }
}
Write-Host "Selecting Azure Subscription: $($SubscriptionID.Guid) ..." -ForegroundColor Cyan
$Null = Select-AzSubscription -SubscriptionId $SubscriptionID.Guid

New-AzDeployment -Name "Initiative-LM-$location" -TemplateUri "https://raw.githubusercontent.com/choudharypooja/Azure-Deployment/main/ARMTemplateExportTest.json" -Location $location -Verbose

foreach ($resourceGroup in $resourceGroups){
	$policyAssignments = ./policyAssignment.ps1 -resourceGroup $resourceGroup -location $location -eventhubName $eventhubName -eventhubNameSpace $eventhubNameSpace -eventhubAuthorizationId $eventhubAuthorizationId -targetResourceGroup $targetResourceGroup -subscriptionId $subscriptionId
	Write-Host "Runnning compliance result for $($policyAssignments.PolicyAssignmentId)" -ForegroundColor Cyan
    ./Trigger-PolicyEvaluation.ps1 -SubscriptionId $subscriptionId -ResourceGroup $policyAssignments.ResourceGroupName interval 25
	Start-Sleep -s 30
	$Null = New-AzRoleAssignment -ObjectId $policyAssignments.Identity.principalId  -RoleDefinitionName Contributor
	Start-Sleep -s 20
	./Trigger-PolicyInitiativeRemediation.ps1 -force -SubscriptionId $subscriptionId -PolicyAssignmentId $policyAssignments.PolicyAssignmentId -ResourceGroupName $policyAssignments.ResourceGroupName

}
}else{
		Write-Host "Exiting the script...."
	}