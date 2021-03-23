param
(
    [Parameter(Mandatory = $True)]
    [string[]]$resourceGroups,

    [Parameter(Mandatory = $True)]
    [string]$location,

    [Parameter(Mandatory =$True)]
    [string]$lmCompanyName,

    [Parameter(Mandatory =$True)]
    [string]$subscriptionId,

    [Parameter(Mandatory=$false)]
    [ValidateSet("AzureChinaCloud","AzureCloud","AzureGermanCloud","AzureUSGovernment")]
    [string]$Environment = "AzureCloud"

)

$location = $location.replace(' ','').toLower()
$locationValidity=$True
$targetResourceGroup = 'lm-logs-' + $lmCompanyName + '-' + $location + '-group'
$eventhubNameSpace = $targetResourceGroup.replace('-group','')
$eventhubName = 'log-hub'
$eventhubAuthorizationId = 'RootManageSharedAccessKey'
$subsId = $subscriptionId
foreach ($resourceGroup in $resourceGroups){
	$resourceGroupDetails = Get-AzResourceGroup -Name $resourceGroup
	if($location -ne $resourceGroupDetails.Location.replace(' ','').toLower()){
		Write-Host "The source resource groups are not in the same region...."
		$locationValidity=$False
		break
	}
}


Get-AzResourceGroup -Name $targetResourceGroup -ErrorVariable notPresent -ErrorAction SilentlyContinue

if ($notPresent)
{
    Write-Host "The target resource group is not present in the specified location or the lm_company_name is incorrect"
}
else
{
if($locationValidity){
New-AzDeployment -Name "Initiative-LM-$location" -TemplateUri "https://raw.githubusercontent.com/choudharypooja/Azure-Deployment/main/ARMTemplateExportTest.json" -Location $location -Verbose

foreach ($resourceGroup in $resourceGroups){
	#$policyAssignments = ./policyAssignment.ps1 -resourceGroup $resourceGroup -location $location -eventhubName $eventhubName -eventhubNameSpace $eventhubNameSpace -eventhubAuthorizationId $eventhubAuthorizationId -targetResourceGroup $targetResourceGroup
	Write-Host "Running compliance result for $($policyAssignments.PolicyAssignmentId)" -ForegroundColor Cyan
	$job = Start-AzPolicyComplianceScan -ResourceGroupName lm-logs-lmpoojachoudhary-westindia-group
	$job | Wait-Job
	Start-Sleep -s 30
	#$Null = New-AzRoleAssignment -ObjectId $policyAssignments.Identity.principalId  -RoleDefinitionName Contributor
	Start-Sleep -s 30
	#./Trigger-PolicyInitiativeRemediation.ps1 -force -SubscriptionId $subsId -PolicyAssignmentId $policyAssignments.PolicyAssignmentId -ResourceGroupName $policyAssignments.ResourceGroupName

}
}else{
		Write-Host "Exiting the script...."
	}
}