#Thanks to Adam the Automater for these wicked pipeline tools
#Check out https://adamtheautomator.com/powershell-devops/ for more info!
#Plus Nicola Suter's guide to signing PowerShell scripts using Aure Pipelines https://tech.nicolonsky.ch/sign-powershell-az-devops/
#and COLIN DEMBOVSKY's guide to Azure Pipeline Variables https://colinsalmcorner.com/azure-pipeline-variables/


#Set-StrictMode -Version Latest
# Get public and private function definition files.

$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)

#$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files.
#foreach ($import in @($Public + $Private)) {
foreach ($import in @($Public)) {
	try {
		Write-Verbose "Importing $($import.FullName)"
		. $import.FullName
	} catch {
		Write-Error "Failed to import function $($import.FullName): $_"
	}
}

## Export all of the public functions making them available to the user
foreach ($file in $Public) {
	Export-ModuleMember -Function $file.BaseName
}