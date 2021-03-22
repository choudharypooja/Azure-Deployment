param
(
    [Parameter(Mandatory = $True)]
    [string]$resourceGroup,

    [Parameter(Mandatory = $True)]
    [string]$location,

	[Parameter(Mandatory = $True)]
	[string]$eventhubName,

	[Parameter(Mandatory = $True)]
	[string]$eventhubNameSpace,

	[Parameter(Mandatory = $True)]
	[string]$eventhubAuthorizationId,

	[Parameter(Mandatory =$True)]
	[string]$targetResourceGroup,

	[Parameter(Mandatory =$True)]
	[string]$subscriptionId,

	[Parameter(Mandatory=$false)]
    [ValidateSet("AzureChinaCloud","AzureCloud","AzureGermanCloud","AzureUSGovernment")]
    [string]$Environment = "AzureCloud"
)

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

$definition = Get-AzPolicySetDefinition | Where-Object { $_.Properties.DisplayName -eq 'Azure Diagnostics Policy Initiative to LM' }

$eventHubNamespaceId = Get-AzEventHubNamespace -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace

$eventHubId = Get-AzEventHub -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace -EventHubName $eventhubName

$eventHubAuthorizationIdParam = Get-AzEventHubAuthorizationRule -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace -Name $eventhubAuthorizationId

$azureRegionParam= @{'azureRegions'=($location)}

$eventHubParam = @{'eventHubName'=($eventHubId.Id);'eventHubRuleId'=($eventhubAuthorizationIdParam.Id);'azureRegions'=(-split $location);'profileName'=($resourceGroup);'metricsEnabled'=('True')}
$resource = Get-AzResourceGroup -Name $resourceGroup

$assignment = New-AzPolicyAssignment -Name $resourceGroup -DisplayName $resourceGroup -Scope $resource.ResourceId  -PolicySetDefinition $definition -Location $location -PolicyParameterObject  $eventHubParam -AssignIdentity

return $assignment