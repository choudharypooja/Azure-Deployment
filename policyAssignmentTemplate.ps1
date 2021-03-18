$targetResourceGroup= 'lm-pooja-we'
$resource = Get-AzResourceGroup -Name $targetResourceGroup

Write-Output $resource.ResourceId
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['resourceId'] = $resource.ResourceId
