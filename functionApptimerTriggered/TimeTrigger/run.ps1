# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
$subscriptionId = "318382e3-a165-4f0d-8906-01fb4cd06b74"
Connect-AzAccount -Identity

$currentContext = Get-AzContext

Write-Host $currentContext
$nonCompliantPolicies = Get-AzPolicyState | Where-Object { $_.ComplianceState -eq "NonCompliant" -and $_.PolicyDefinitionAction -eq "deployIfNotExists" -and $_.ResourceLocation -eq "uksouth"}
foreach ($policy in $nonCompliantPolicies) {
    $remediationName = "rem." + $policy.PolicyDefinitionName
    Start-AzPolicyRemediation -Name $remediationName -PolicyAssignmentId $policy.PolicyAssignmentId -PolicyDefinitionReferenceId $policy.PolicyDefinitionReferenceId -ResourceGroupName $policy.ResourceGroup
}
