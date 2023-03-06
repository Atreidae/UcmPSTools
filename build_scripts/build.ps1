#Thanks to Adam the Automater for these wicked pipeline tools
#Check out https://adamtheautomator.com/powershell-devops/ for more info!
#Plus Nicola Suter's guide to signing PowerShell scripts using Aure Pipelines https://tech.nicolonsky.ch/sign-powershell-az-devops/ and more recently GitHub https://tech.nicolonsky.ch/github-actions-powershell-signing/
#and COLIN DEMBOVSKY's guide to Azure Pipeline Variables https://colinsalmcorner.com/azure-pipeline-variables/

$buildVersion = {(get-content ./version) + ".$($ENV:build)"}
Write-Debug "Building version $buildversion"
$moduleName = 'UcmPSTools'

$manifestPath = Join-Path -Path $PSScriptRoot -ChildPath "..\$moduleName.psd1"

## Update build version in manifest
$manifestContent = Get-Content -Path $manifestPath -Raw
$manifestContent = $manifestContent -replace '<ModuleVersion>', $buildVersion

## Find all of the public functions
$publicFuncFolderPath = Join-Path -Path $manifestPath -ChildPath 'public'
if ((Test-Path -Path $publicFuncFolderPath) -and ($publicFunctionNames = Get-ChildItem -Path $publicFuncFolderPath -Filter '*.ps1' | Select-Object -ExpandProperty BaseName)) {
	$funcStrings = "'$($publicFunctionNames -join "','")'"
} else {
	$funcStrings = $null
}
## Add all public functions to FunctionsToExport attribute
$manifestContent = $manifestContent -replace "'<FunctionsToExport>'", $funcStrings
$manifestContent | Set-Content -Path $manifestPath