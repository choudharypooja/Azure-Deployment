$resource = Get-AzResourceGroup -Name 'lm-pooja-we'

Write-Output $resource
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['resourceId'] = $resource.ResourceId
