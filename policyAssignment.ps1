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
	[string]$targetResourceGroup
)

$definition = Get-AzPolicySetDefinition | Where-Object { $_.Properties.DisplayName -eq 'Azure Diagnostics Policy Initiative to LM' }

$eventHubNamespaceId = Get-AzEventHubNamespace -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace

$eventHubId = Get-AzEventHub -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace -EventHubName $eventhubName

$eventHubAuthorizationIdParam = Get-AzEventHubAuthorizationRule -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace -Name $eventhubAuthorizationId

$azureRegionParam= @{'azureRegions'=($location)}


$eventHubParam = @{'eventHubName'=($eventHubId.Id);'eventHubRuleId'=($eventhubAuthorizationIdParam.Id);'azureRegions'=(-split $location);'profileName'=($resourceGroup);'metricsEnabled'=('True')}
$resource = Get-AzResourceGroup -Name $resourceGroup

$eachResource = $resource.ResourceId

$eachAssignment = @{}
$assignment = New-AzPolicyAssignment -Name $resourceGroup -DisplayName $resourceGroup -PolicySetDefinition $definition -Location $location -PolicyParameterObject  $eventHubParam -AssignIdentity

# Write-Output $assignment
# $DeploymentScriptOutputs = @{}
# $DeploymentScriptOutputs['principalId'] = $assignment

# # Start-Sleep -s 15
# # New-AzRoleAssignment -ObjectId $assignment.Identity.PrincipalId  -RoleDefinitionName Contributor
# # $eachAssignment.add($assignment.PolicyAssignmentId,$assignment.ResourceGroupName)
# # return $eachAssignment
