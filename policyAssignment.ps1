param
(
    # An interval in seconds to check that trigger was successful
    [Parameter(Mandatory = $True)]
    [string[]]$resourceGroups,

    [Parameter(Mandatory = $True)]
    [string]$location,

	[Parameter(Mandatory = $True)] 
	[string]$eventhubName,

	[Parameter(Mandatory = $True)]
	[string]$eventhubNameSpace,

	[Parameter(Mandatory = $True)] 
	[string]$eventhubAuthorizationId,

	[Parameter(Mandatory =$True)]
	[string]$targetResourceGroup
)

$definition = Get-AzureRmPolicySetDefinition | Where-Object { $_.Properties.DisplayName -eq 'Azure Diagnostics Policy Initiative Test' }

$eventHubNamespaceId = Get-AzEventHubNamespace -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace

$eventHubId = Get-AzureRmEventHub -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace -EventHubName $eventhubName

$eventHubAuthorizationIdParam = Get-AzureRmEventHubAuthorizationRule -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace -Name $eventhubAuthorizationId
echo $eventhubAuthorizationIdParam

$azureRegionParam= @{'azureRegions'=($location)}

foreach ($resourceGroup in $resourceGroups){
    $eventHubParam = @{'eventHubName'=($eventHubId.Id);'eventHubRuleId'=($eventhubAuthorizationIdParam.Id);'azureRegions'=(-split $location);'profileName'=($resourceGroup);'metricsEnabled'=('True')}
	$resource = Get-AzureRmResourceGroup -Name $resourceGroup
	$eachResource = $resource.ResourceId
	$assignment = New-AzureRmPolicyAssignment -Name $resourceGroup -DisplayName $resourceGroup -Scope $eachResource  -PolicySetDefinition $definition -Location $location -PolicyParameterObject  $eventHubParam -AssignIdentity #$azureRegionParam,$eventHubAuthIdParam,$profileNameParam

	New-AzRoleAssignment -Scope $eachResource -ObjectId $assignment.Identity.PrincipalId  -RoleDefinitionName Contributor

}