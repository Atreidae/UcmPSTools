#Thanks to Adam the Automater for these wicked pipeline tools
#Check out https://adamtheautomator.com/powershell-devops/ for more info!
#Also check out his book "The Pester Book. It helped me write all these tests!

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

describe 'Write-UcmLog tests' {

	$Script:LogFileLocation = 'TestDrive:\Testlog.log'

	Write-UcmLog -Message "Creating Pester Test File" -Severity 1 -Component "Pester"

	it 'Creates a log file' {(Get-Content -path TestDrive:\Testlog.log) | should not throw}

	it 'Writes to the log file' {}

	it 'Displays a verbose message' { $(Write-UcmLog -Message "Pester Test Verbose Message" -Severity 1 -Component "Pester")4>&1 | Should -contain 'Pester Test Verbose Message' }

	it 'Displays an info message' { $(Write-UcmLog -Message "Pester Test Info Message" -Severity 3 -Component "Pester") | Should -contain 'Pester Test Info Message' }

	it 'Displays a warning message' { $(Write-UcmLog -Message "Pester Test Warning Message" -Severity 3 -Component "Pester")3>&1 | Should -contain 'Pester Test Warning Message' }

	it 'Displays an error message' { $(Write-UcmLog -Message "Pester Test Error Message" -Severity 4 -Component "Pester")2>&1 | Should -contain 'Pester Test Error Message' }

	it 'Injects the function name' { $(Write-UcmLog -Message "Testing Function Test" -Severity 2 -Component "Pester") | Should -contain 'Pester' }

	#it 'Rotates the log file' {}

}