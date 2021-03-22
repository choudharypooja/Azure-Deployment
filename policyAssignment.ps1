param
(
    # An interval in seconds to check that trigger was successful
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
    	[string]$Environment = "AzureCloud
)
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

$definition = Get-AzPolicySetDefinition | Where-Object { $_.Properties.DisplayName -eq 'Azure Diagnostics Policy Initiative to LM' }

$eventHubNamespaceId = Get-AzEventHubNamespace -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace

$eventHubId = Get-AzEventHub -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace -EventHubName $eventhubName

$eventHubAuthorizationIdParam = Get-AzEventHubAuthorizationRule -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace -Name $eventhubAuthorizationId

$azureRegionParam= @{'azureRegions'=($location)}

$eventHubParam = @{'eventHubName'=($eventHubId.Id);'eventHubRuleId'=($eventhubAuthorizationIdParam.Id);'azureRegions'=(-split $location);'profileName'=($resourceGroup);'metricsEnabled'=('True')}
$resource = Get-AzResourceGroup -Name $resourceGroup

#$eachAssignment = @{}
$assignment = New-AzPolicyAssignment -Name $resourceGroup -DisplayName $resourceGroup -Scope $resource.ResourceId  -PolicySetDefinition $definition -Location $location -PolicyParameterObject  $eventHubParam -AssignIdentity

#Start-Sleep -s 15
#$eachAssignment.add($assignment.PolicyAssignmentId,$assignment.ResourceGroupName)
return $assignment 
