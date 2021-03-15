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
  
New-AzDeployment -Name "Initiative-LM" -TemplateUri "https://raw.githubusercontent.com/choudharypooja/Azure-Deployment/main/ARMTemplateExportTest.json" -Location $location -Verbose 

mkdir lm-$location

cd lm-$location

wget https://raw.githubusercontent.com/choudharypooja/Azure-Deployment/main/policyAssignment.ps1

$assignments = @{}

foreach ($resourceGroup in $resourceGroups){
	$policyAssignments = .\policyAssignment.ps1 -resourceGroup $resourceGroup -location $location -eventhubName $eventhubName -eventhubNameSpace $eventhubNameSpace -eventhubAuthorizationId $eventhubAuthorizationId -targetResourceGroup $targetResourceGroup

	$assignments+=@{$policyAssignments}

}
# .\Trigger-PolicyEvaluation.ps1 -SubscriptionId "318382e3-a165-4f0d-8906-01fb4cd06b74" -ResourceGroup "lm-logs-qauat01-westindia-group" -interval 25

wget https://raw.githubusercontent.com/choudharypooja/Azure-Deployment/main/Trigger-PolicyInitiativeRemediation.ps1

foreach($policyAssignment in $assignments.GetEnumerator()){
	az policy state trigger-scan --resource-group $policyAssignment.Value
	
	.\Trigger-PolicyInitiativeRemediation.ps1 -SubscriptionId $subscriptionId -PolicyAssignmentId $policyAssignment.Key -ResourceGroupName $policyAssignment.Value

}

