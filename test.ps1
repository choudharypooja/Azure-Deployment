param
(
	# An interval in seconds to check that trigger was successful
    [Parameter(Mandatory = $True)]
    [string[]]$resourceGroups
)

$assignments = @()
foreach ($resourceGroup in $resourceGroups){
  $assignments += $resourceGroup
}

Write-Output $assignments
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['assignments'] = $assignments
