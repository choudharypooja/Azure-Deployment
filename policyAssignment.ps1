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

function NewAzureRmRoleAssignment($resource, $assignment, $retryCount) {
    $totalRetries = $retryCount
    While ($True) {
        Try {
            $Null = New-AzRoleAssignment -ObjectId $assignment.Identity.PrincipalId  -RoleDefinitionName Contributor
            Return
        }
        Catch {
            # The principal could not be found. Maybe it was just created.
            If ($retryCount -eq 0) {
                Write-Error "An error occurred: $($_.Exception)`n$($_.ScriptStackTrace)"
                throw "The principal '$assignment.Identity.PrincipalId' cannot be granted 'Contributor' role on the resource group '$resource.ResourceId'. Please make sure the principal exists and try again later."
            }
            $retryCount--
            Write-Warning "  The principal '$assignment.Identity.PrincipalId' cannot be granted 'Contributor' role on the resource group '$resource.ResourceId'. Trying again (attempt $($totalRetries - $retryCount)/$totalRetries)"
            Start-Sleep 40
        }
    }
}

$definition = Get-AzPolicySetDefinition | Where-Object { $_.Properties.DisplayName -eq 'Azure Diagnostics Policy Initiative to LM' }

$eventHubNamespaceId = Get-AzEventHubNamespace -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace

$eventHubId = Get-AzEventHub -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace -EventHubName $eventhubName

$eventHubAuthorizationIdParam = Get-AzEventHubAuthorizationRule -ResourceGroupName $targetresourceGroup -NamespaceName $eventhubNameSpace -Name $eventhubAuthorizationId

$azureRegionParam= @{'azureRegions'=($location)}

$eventHubParam = @{'eventHubName'=($eventHubId.Id);'eventHubRuleId'=($eventhubAuthorizationIdParam.Id);'azureRegions'=(-split $location);'profileName'=($resourceGroup);'metricsEnabled'=('True')}
$resource = Get-AzResourceGroup -Name $resourceGroup

$eachAssignment = @{}
$assignment = New-AzPolicyAssignment -Name $resourceGroup -DisplayName $resourceGroup -Scope $resource.ResourceId  -PolicySetDefinition $definition -Location $location -PolicyParameterObject  $eventHubParam -AssignIdentity

#Start-Sleep -s 15
NewAzureRmRoleAssignment $resource $assignment 5
$eachAssignment.add($assignment.PolicyAssignmentId,$assignment.ResourceGroupName)
return $eachAssignment 
