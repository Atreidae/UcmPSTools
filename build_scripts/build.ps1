#Thanks to Adam the Automater for these wicked pipeline tools
#Check out https://adamtheautomator.com/powershell-devops/ for more info!

$buildVersion = $env:BUILDVER
$moduleName = 'UcmPSTools'

## Find the module manifest while running on the build agent
$manifestPath = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath "$moduleName.psd1"

## Update version in the manifest to the current build
$manifestContent = Get-Content -Path $manifestPath -Raw
$manifestContent = $manifestContent -replace '<ModuleVersion>', $buildVersion

## Find all of the public functions and create a string for the manifest
$publicFuncFolderPath = Join-Path -Path $PSScriptRoot -ChildPath 'public'
if ((Test-Path -Path $publicFuncFolderPath) -and ($publicFunctionNames = Get-ChildItem -Path $publicFuncFolderPath -Filter '*.ps1' | Select-Object -ExpandProperty BaseName)) {
	$funcStrings = "'$($publicFunctionNames -join "','")'"
} else {
	$funcStrings = $null
}

## Add all public functions to FunctionsToExport attribute
$manifestContent = $manifestContent -replace "'<FunctionsToExport>'", $funcStrings
$manifestContent | Set-Content -Path $manifestPath