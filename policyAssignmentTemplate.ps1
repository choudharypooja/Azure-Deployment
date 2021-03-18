$targetResourceGroup= 'lm-pooja-we'
$resource = Get-AzResourceGroup -Name $targetResourceGroup

Write-Output $targetResourceGroup
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['resourceId'] = $targetResourceGroup
