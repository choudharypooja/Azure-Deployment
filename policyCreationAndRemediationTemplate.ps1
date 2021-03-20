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
	[string]$targetResourceGroup,

	[Parameter(Mandatory =$True)]
	[string]$subscriptionId

)
  
New-AzDeployment -Name "Initiative-LM-$location" -TemplateUri "https://raw.githubusercontent.com/choudharypooja/Azure-Deployment/main/ARMTemplateExportTest.json" -Location $location -Verbose 

#wget https://raw.githubusercontent.com/choudharypooja/Azure-Deployment/main/policyAssignment.ps1

$assignments = @{}

foreach ($resourceGroup in $resourceGroups){
	$policyAssignments = ./policyAssignment.ps1 -resourceGroup $resourceGroup -location $location -eventhubName $eventhubName -eventhubNameSpace $eventhubNameSpace -eventhubAuthorizationId $eventhubAuthorizationId -targetResourceGroup $targetResourceGroup
	Write-Host "Runnning compliance result for $($policyAssignments.PolicyAssignmentId)" -ForegroundColor Cyan
	Start-AzPolicyComplianceScan -ResourceGroupName $policyAssignments.ResourceGroupName
	Start-Sleep -s 30
	$Null = New-AzRoleAssignment -ObjectId $policyAssignments.Identity.principalId  -RoleDefinitionName Contributor
	./Trigger-PolicyInitiativeRemediation.ps1 -force -SubscriptionId $subscriptionId -PolicyAssignmentId $policyAssignments.PolicyAssignmentId -ResourceGroupName $policyAssignments.ResourceGroupName
}

