$eventhubNameSpace = "lm-logs-lmpoojachoudhary-westeurope"
$targetResourceGroup= "lm-pooja-we"
$eventHubNamespaceId = Get-AzEventHubNamespace -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace

# $eventHubId = Get-AzEventHub -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace -EventHubName $eventhubName

# $eventHubAuthorizationIdParam = Get-AzEventHubAuthorizationRule -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace -Name $eventhubAuthorizationId

# $azureRegionParam= @{'azureRegions'=($location)}


# $eventHubParam = @{'eventHubName'=($eventHubId.Id);'eventHubRuleId'=($eventhubAuthorizationIdParam.Id);'azureRegions'=(-split $location);'profileName'=($resourceGroup);'metricsEnabled'=('True')}
# $resource = Get-AzResourceGroup -Name $resourceGroup

Write-Output $output
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['text'] = $eventHubNamespaceId

# $eachResource = $resource.ResourceId

# $eachAssignment = @{}
# $assignment = New-AzPolicyAssignment -Name $resourceGroup -DisplayName $resourceGroup  -PolicySetDefinition $definition -Location $location -PolicyParameterObject  $eventHubParam -AssignIdentity


# Start-Sleep -s 15
# New-AzRoleAssignment -Scope $eachResource -ObjectId $assignment.Identity.PrincipalId  -RoleDefinitionName Contributor
# $eachAssignment.add($assignment.PolicyAssignmentId,$assignment.ResourceGroupName)
# return $eachAssignment
