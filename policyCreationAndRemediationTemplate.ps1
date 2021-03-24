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
$targetResourceGroup = 'lm-logs-' + $lmCompanyName + '-' + $location + '-group'
$eventhubNameSpace = $targetResourceGroup.replace('-group','')
$eventhubName = 'log-hub'
$eventhubAuthorizationId = 'RootManageSharedAccessKey'

New-AzDeployment -Name "Initiative-LM-$location" -TemplateUri "https://raw.githubusercontent.com/choudharypooja/Azure-Deployment/main/ARMTemplateExportTest.json" -Location $location -Verbose
foreach ($resourceGroup in $resourceGroups){
	$policyAssignments = ./policyAssignment.ps1 -resourceGroup $resourceGroup -location $location -eventhubName $eventhubName -eventhubNameSpace $eventhubNameSpace -eventhubAuthorizationId $eventhubAuthorizationId -targetResourceGroup $targetResourceGroup
	Write-Host "Runnning compliance result for $($policyAssignments.PolicyAssignmentId)" -ForegroundColor Cyan
	Start-AzPolicyComplianceScan -ResourceGroupName $policyAssignments.ResourceGroupName
	Start-Sleep -s 30
	$Null = New-AzRoleAssignment -ObjectId $policyAssignments.Identity.principalId  -RoleDefinitionName Contributor
	Start-Sleep -s 20
	./Trigger-PolicyInitiativeRemediation.ps1 -force -SubscriptionId $subscriptionId -PolicyAssignmentId $policyAssignments.PolicyAssignmentId -ResourceGroupName $policyAssignments.ResourceGroupName

}
