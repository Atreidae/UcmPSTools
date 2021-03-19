Function Find-UcmO365ServicePlan
{
	<#
			.SYNOPSIS
			Enables a Specified Service Plan in Office365

			.DESCRIPTION
			Cmdlet uses an existing Azure AD connection to filter through a users licences and check if the requested Service Plan is enabled.
			Handy for checking if an administrator has disabled Skype for Business Online before attempting to migrate them for example.

			.PARAMETER UPN
			The users username in UPN format

			.PARAMETER ServiceName
			Office365 Service Plan you wish to check

			.EXAMPLE
			PS> Find-UcmO365ServicePlan -UPN 'button.mash@contoso.com' -ServiceName 'MCOSTANDARD'
			Enables a user for Skype for Business Online (Required to migrate to Teams)

			.INPUTS
			User UPN - Users username in UPN format
			ServiceName - Office365 Service Plan you want to check

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple Keys to indicate status
			$Return.Status 
			$Return.Message 
			
			Return.Status can return one of four values
			"OK"      : Service Plan is Enabled
			"Warn"    : Service Plan is Disabled
			"Error"   : Service Plan in an unknown state, like PendingProvisioning 
			"Unknown" : Cmdlet reached the end of the fucntion without returning anything, this shouldnt happen, if it does please log an issue on Github
			
			Return.Message returns descriptive text based on the outcome, mainly for logging or reporting

			.NOTES
			Version:		1.1
			Date:			18/03/2021

			.VERSION HISTORY
			1.1: Updated to "Ucm" naming convention
			Better inline documentation
			Updated PowerShell Verbage from Test to Find
					
			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Write-UcmLog: 						https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-UcmLog.ps1
			Write-UcmHTMLReport: 			https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-UcmHTMLReport.ps1 (optional)

			.REQUIRED PERMISSIONS
			'Office365 User Admin' or better

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Fuctions

			.ACKNOWLEDGEMENTS

	#>

	Param 
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1,HelpMessage='The UPN of the user you wish to check the Service Plan on, eg: button.mash@contoso.com')] [string]$UPN, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2,HelpMessage="The name of the Office365 Service Plan you wish check for, eg: 'MCOSTANDARD' for Skype Online")] [string]$ServiceName 
	)


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Find-UcmO365ServicePlan'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = 'Unknown'
	$return.Message = 'Function did not return a status message'

	# Log why we were called
	Write-Log -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-Log -Message 'Parameters' -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message 'Parameters Values' -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message 'Optional Arguments' -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$Args" -Severity 1 -Component $function -LogOnly
	Write-Host '' #Insert a blank line to make reading output easier on loops
	
	#endregion FunctionSetup

	#region FunctionWork
	#Set a flag to see if the licence is enabled
	$Enabled =$false

	#Get the users licences and enumerate through them looking for the relevant service plan
	$LicenseDetails = (Get-MsolUser -UserPrincipalName $UPN).Licenses

	ForEach ($License in $LicenseDetails)
	{ 
		ForEach ($ServiceStatus in $License.ServiceStatus)
		{
			If ($ServiceStatus.ProvisioningStatus -eq 'Disabled' -and $_.ServicePlan.ServiceName -eq "$serviceName")
			{ 
				Write-Log -Message "$ServiceName Disabled" -Severity 2 -Component $function
			}
			Elseif ($ServiceStatus.ProvisioningStatus -eq 'Success' -and $_.ServicePlan.ServiceName -eq "$serviceName")
			{ 
				Write-Log -Message "$ServiceName Enabled" -Severity 2 -Component $function
				$Enabled = $true
			}
			ElseIf ($ServiceStatus.ServicePlan.ServiceName -like "*$serviceName*")
			{
				Write-Log -Message "$ServiceName is in unknown state" -Severity 2 -Component $function
				$Enabled = 'Error'
			}
		} #End Service Status Loop
	}#End licence loop

	If ($enabled -eq 'Error')
	{ 
		Write-Log -Message "$ServiceName is in unknown state" -Severity 2 -Component $function
		$Return.Status = 'ERROR'
		$Return.Message  = "$ServiceName is in unknown state"
		Return $Return
	}
	Elseif ($enabled -eq $true)
	{ 
		Write-Log -Message "$ServiceName Enabled" -Severity 2 -Component $function
		$Return.Status = 'OK'
		$Return.Message  = "$ServiceName Enabled"
		Return $Return
	}
	ElseIf ($_.ServicePlan.ServiceName -like "*$serviceName*")
	{
		Write-Log -Message "$ServiceName Disabled" -Severity 2 -Component $function
		$Return.Status = 'Warn'
		$Return.Message  = "$ServiceName Disabled"
		Return $Return
	}
	#endregion FunctionWork

	#region FunctionReturn
 
	#Default Return Variable for my HTML Reporting Fucntion
	Write-Log -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
	$return.Status = 'Unknown'
	$return.Message = 'Function did not encounter return statement'
	Return $Return
	#endregion FunctionReturn

}
# SIG # Begin signature block
# MIINFwYJKoZIhvcNAQcCoIINCDCCDQQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzq3i4/emhgJpsRjJCcXR6VGJ
# 6QCgggpZMIIFITCCBAmgAwIBAgIQD274plv3rQv2N1HXnqk5jzANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTIwMDEwNTAwMDAwMFoXDTIyMDky
# ODEyMDAwMFowXjELMAkGA1UEBhMCQVUxETAPBgNVBAgTCFZpY3RvcmlhMRAwDgYD
# VQQHEwdCZXJ3aWNrMRQwEgYDVQQKEwtKYW1lcyBBcmJlcjEUMBIGA1UEAxMLSmFt
# ZXMgQXJiZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCVq3KHhsUn
# G0iP8Xv+EIRGhPEqceUcmXftvbWSXoEL+w8h79PVn9WZawPgyDlmAZvzlAWaPGSu
# tW7z0/XqkewTjFI4em2BxIsLr3enoB/OuBM11ktZVaMYWOHaUexj8CioBeoFTGYg
# H98cmoo6i3xQcBbFJauJcgAI8jDTTDHM1bvDE9ItyeTr63MGJx1rob4KXCr0Oi9R
# MVtk/TDVCNjG3IdK8dnrpKUE7s2grAiPJ2tmNkrk3R2pSRl1qx3d01LWKcV2tv4s
# fbWLCwdz2HVTdevl7PjhwUPhuLZVj/EctCiU+5UDDtAIIIvQ9uvbFngmF0QmE9Yb
# W1bgiyfr5GmFAgMBAAGjggHFMIIBwTAfBgNVHSMEGDAWgBRaxLl7KgqjpepxA8Bg
# +S32ZXUOWDAdBgNVHQ4EFgQUX+77NtBOxF+2arVa8Srnig2A/ocwDgYDVR0PAQH/
# BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGA1UdHwRwMG4wNaAzoDGGL2h0
# dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtY3MtZzEuY3JsMDWg
# M6Axhi9odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcx
# LmNybDBMBgNVHSAERTBDMDcGCWCGSAGG/WwDATAqMCgGCCsGAQUFBwIBFhxodHRw
# czovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAgGBmeBDAEEATCBhAYIKwYBBQUHAQEE
# eDB2MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wTgYIKwYB
# BQUHMAKGQmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFNIQTJB
# c3N1cmVkSURDb2RlU2lnbmluZ0NBLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3
# DQEBCwUAA4IBAQCfGaBR90KcYBczv5tVSBquFD0rP4h7oEE8ik+EOJQituu3m/nv
# X+fG8h8f8+cG+0O55g+P/iGPS1Uo/BUEKjfUvLQjg9gJN7ZZozqP5xU7pn270rFd
# chmu/vkSGh4waYoASiqJXvkQbVZcxV72j3+RBD1jsmgP05WaKMT5l9VZwGedVn40
# FHNarFpJoCsyQn6sQInWdDfi6X2cYi0x4U0ogWYYyR8bhBUlt6RhevYn6EfqHgV3
# oEZ7qwxApjyGpQIwwQUEs60/tO7bkH1futFDdogzsXFJO3cS9OykctpBucaPDrkH
# 1AcqMqpWVRcXGebpOHnW5zPoGFG9JblyuwBZMIIFMDCCBBigAwIBAgIQBAkYG1/V
# u2Z1U0O1b5VQCDANBgkqhkiG9w0BAQsFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYD
# VQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMTMxMDIyMTIwMDAw
# WhcNMjgxMDIyMTIwMDAwWjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNl
# cnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdp
# Q2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEA+NOzHH8OEa9ndwfTCzFJGc/Q+0WZsTrbRPV/
# 5aid2zLXcep2nQUut4/6kkPApfmJ1DcZ17aq8JyGpdglrA55KDp+6dFn08b7KSfH
# 03sjlOSRI5aQd4L5oYQjZhJUM1B0sSgmuyRpwsJS8hRniolF1C2ho+mILCCVrhxK
# hwjfDPXiTWAYvqrEsq5wMWYzcT6scKKrzn/pfMuSoeU7MRzP6vIK5Fe7SrXpdOYr
# /mzLfnQ5Ng2Q7+S1TqSp6moKq4TzrGdOtcT3jNEgJSPrCGQ+UpbB8g8S9MWOD8Gi
# 6CxR93O8vYWxYoNzQYIH5DiLanMg0A9kczyen6Yzqf0Z3yWT0QIDAQABo4IBzTCC
# AckwEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAww
# CgYIKwYBBQUHAwMweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8v
# b2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6
# MHgwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3Vy
# ZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwTwYDVR0gBEgwRjA4BgpghkgBhv1s
# AAIEMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMw
# CgYIYIZIAYb9bAMwHQYDVR0OBBYEFFrEuXsqCqOl6nEDwGD5LfZldQ5YMB8GA1Ud
# IwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBCwUAA4IBAQA+
# 7A1aJLPzItEVyCx8JSl2qB1dHC06GsTvMGHXfgtg/cM9D8Svi/3vKt8gVTew4fbR
# knUPUbRupY5a4l4kgU4QpO4/cY5jDhNLrddfRHnzNhQGivecRk5c/5CxGwcOkRX7
# uq+1UcKNJK4kxscnKqEpKBo6cSgCPC6Ro8AlEeKcFEehemhor5unXCBc2XGxDI+7
# qPjFEmifz0DLQESlE/DmZAwlCEIysjaKJAL+L3J+HNdJRZboWR3p+nRka7LrZkPa
# s7CM1ekN3fYBIM6ZMWM9CBoYs4GbT8aTEAb8B4H6i9r5gkn3Ym6hU/oSlBiFLpKR
# 6mhsRDKyZqHnGKSaZFHvMYICKDCCAiQCAQEwgYYwcjELMAkGA1UEBhMCVVMxFTAT
# BgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEx
# MC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBD
# QQIQD274plv3rQv2N1HXnqk5jzAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEK
# MAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUeV/AtMYWNK1dA/ui
# 3YkRD3UjAbEwDQYJKoZIhvcNAQEBBQAEggEAa9a9AcpueY00ePXCtreI1Njl+Zx9
# WdYJXTVIxZ23DJdWcR9RR9VyQuiXNYLnFRSGMO9PNvXAcn2g5XG8oVSf6lZ10Tq4
# z8LKLPBW/PCQX7+LNZjeIOrOdhG6rNa2yDfhUBqd9LNu8st5/v+Rf0LaO7QT6XlA
# wqC7HdmZc9Cxay665SFeyNA8wqD8jgIQSaVq/sJ6ZFiwjWua+UG9yj6eLJT3HpEC
# TsXaCnsSp8Q1SMcWAOlYFQ0AMgcDgElnh3AWSvlKC1GIf7f8+Glb0Wi9rCkfDuoA
# HsrNtv7E4eITMSLK+QapZ5qEglGMCL3a1jVksxitRKY5r1SVl2vrIUpGpQ==
# SIG # End signature block
