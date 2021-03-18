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
	$policyAssignments = .\policyAssignment.ps1 -resourceGroup $resourceGroup -location $location -eventhubName $eventhubName -eventhubNameSpace $eventhubNameSpace -eventhubAuthorizationId $eventhubAuthorizationId -targetResourceGroup $targetResourceGroup

	foreach($policyAssignment in $policyAssignments.GetEnumerator()){
		$assignments.add($policyAssignment.Key,$policyAssignment.Value)
	}
}

#wget https://raw.githubusercontent.com/choudharypooja/Azure-Deployment/main/Trigger-PolicyInitiativeRemediation.ps1

foreach($policyAssignment in $assignments.GetEnumerator()){
	Write-Host "Runnning compliance result for $($policyAssignment.Value)" -ForegroundColor Cyan
	az policy state trigger-scan --resource-group $policyAssignment.Value
	Start-Sleep -s 15
	.\Trigger-PolicyInitiativeRemediation.ps1 -force -SubscriptionId $subscriptionId -PolicyAssignmentId $policyAssignment.Key -ResourceGroupName $policyAssignment.Value
}

