#Thanks to Adam the Automater for these wicked pipeline tools
#Check out https://adamtheautomator.com/powershell-devops/ for more info!

Install-Module -Name PSScriptAnalyzer -Force

describe 'Module-level tests' {

	it 'the module imports successfully' {
		{ Import-Module -Name "$PSScriptRoot\UcmPSTools.psm1" -ErrorAction Stop } | should not throw
	}

	it 'the module has an associated manifest' {
		Test-Path "$PSScriptRoot\UcmPSTools.psd1" | should -Be $true
	}

	it 'passes all default PSScriptAnalyzer rules' {
		Invoke-ScriptAnalyzer -Path "$PSScriptRoot\UcmPSTools.psm1" | should -BeNullOrEmpty
	}

}