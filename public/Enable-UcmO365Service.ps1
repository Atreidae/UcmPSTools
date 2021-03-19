Function Enable-UcmO365Service
{
	<#
			.SYNOPSIS
			Enables a Specified Service Plan in Office365

			.DESCRIPTION
			Cmdlet uses an existing Azure AD connection to filter through a users licences and enable the requested service.
			Handy if an administrator has disabled Skype for Business Online for example.

			Skype for Business Online
			PS> Enable-UcmO365Service -UPN 'button.mash@contoso.com' -ServiceName 'MCOSTANDARD'

			Teams
			PS> Enable-UcmO365Service -UPN 'button.mash@contoso.com' -ServiceName 'TEAMS1'

			Telstra Calling (Australian version of Microsoft Calling)
			PS> Enable-UcmO365Service -UPN 'button.mash@contoso.com' -ServiceName 'MCOPSTNEAU'

			.EXAMPLE
			PS> Enable-UcmO365Service -User 'button.mash@Contoso.com' -ServiceName MCOSTANDARD
			Enables Skype for Business Online for the user Button Mash 

			.PARAMETER UPN
			The users username in UPN format

			.PARAMETER ServiceName
			Office365 Service Plan you wish to enable


			.INPUTS
			This function accepts both parameter and pipline input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple Keys to indicate status
			$Return.Status 
			$Return.Message 
			
			Return.Status can return one of three values
			"OK"      : The Service Plan was Enabled
			"Error"   : The Service Plan was wasnt enabled, it may not have been found or there was an error setting the users attributes. 
			"Unknown" : Cmdlet reached the end of the fucntion without returning anything, this shouldnt happen, if it does please log an issue on Github
			
			Return.Message returns descriptive text based on the outcome, mainly for logging or reporting

			.NOTES
			Version:		1.1
			Date:			18/03/2021

			.VERSION HISTORY
			1.1: Updated to "Ucm" naming convention
			Better inline documentation

			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Write-UcmLog: 						https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-UcmLog.ps1
			Write-HTMLReport: 				https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-HTMLReport.ps1 (optional)
			AzureAD 									(Install-Module AzureAD) 
			MSOnline									(Install-Module MSOnline) 

			.REQUIRED PERMISSIONS
			'Office365 User Admin' or better

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Fuctions

			.ACKNOWLEDGEMENTS
			#Stack Overflow, disabling services: https://stackoverflow.com/questions/50492591/how-can-i-disable-and-enable-office-365-apps-for-all-users-at-once-using-powersh
			#Alex Verboon, Powershell script to remove Office 365 Service Plans from a User: https://www.verboon.info/2015/12/powershell-script-to-remove-office-365-service-plans-from-a-user/

	#>

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1,HelpMessage='The UPN of the user you wish to enable the Service Plan on, eg: button.mash@contoso.com')] [string]$UPN, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2,HelpMessage="The name of the Office365 Service Plan you wish enable, eg: 'MCOSTANDARD' for Skype Online")] [string]$ServiceName 
	)


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Enable-UcmO365Service'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = 'Unknown'
	$return.Message = 'Function did not return a status message'

	# Log why we were called
	Write-UcmLog -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-UcmLog -Message 'Parameters' -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message 'Parameters Values' -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message 'Optional Arguments' -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$Args" -Severity 1 -Component $function -LogOnly
	Write-Host -Message '' #Insert a blank line to make reading output easier on loops
	
	#endregion FunctionSetup

	#region FunctionWork

	#Set a flag to track if we found the app or not
	$AppEnabled = $False

	#Get the user Licence details
	$LicenseDetails = (Get-MsolUser -UserPrincipalName $UPN).Licenses

	#Run through all the services on each licence, one licence at a time.
	ForEach ($License in $LicenseDetails) {
		Write-UcmLog -Message "Checking $($License.AccountSkuId) for $Servicename" -Severity 1 -Component $function
		
		#Find all the Disabled services and add them to an array, except for the requsted service. We need them for later
		$DisabledOptions = @()
		ForEach ($Service in $License.ServiceStatus)
		{
			#Check to see if this service is disabled
			Write-UcmLog -Message "Checking $($Service.ServicePlan.ServiceName)" -Severity 1 -Component $function
			If ($Service.ProvisioningStatus -eq 'Disabled') 
			{
				#The Service Is disabled, check to see if its the requested service
				If ($Service.ServicePlan.ServiceName -eq $ServiceName)
				{
					Write-UcmLog -Message "$Servicename Was disabled, Enabling" -Severity 2 -Component $function
					$AppEnabled = $true
				}
				#Not the requested service, add it to the array
				Else
				{
					Write-UcmLog -Message "$($Service.ServicePlan.ServiceName) is disabled, adding to Disabled Options" -Severity 1 -Component $function
					$DisabledOptions += "$($Service.ServicePlan.ServiceName)"
				}
			}
		}

		#Set the Licence options using the new list of disabled licences
		Try {
			Write-UcmLog -Message 'Setting Licence Options with the following Disabled Services' -Severity 1 -Component $function
			Write-UcmLog -Message "$DisabledOptions" -Severity 1 -Component $function

			#If there are zero options in the disabled list, dont use the -DisabledPlans flag.
			If ($DisabledOptions.count -eq 0)
			{
				$LicenseOptions = New-MsolLicenseOptions -AccountSkuId $License.AccountSkuId
			}
			Else
			{ 
				$LicenseOptions = New-MsolLicenseOptions -AccountSkuId $License.AccountSkuId -DisabledPlans $DisabledOptions
			}
			
			#Using the License Options attributes, set the users licence.
			Set-MsolUserLicense -UserPrincipalName $UPN -LicenseOptions $LicenseOptions
			
			#Something went wrong setting user licence
		}
		Catch
		{
			Write-UcmLog -Message 'Something went wrong assinging the licence' -Severity 3 -Component $function 
			$AppEnabled = $false
		}
	} #Repeat for the next Licence

	#Report on success/failure based on the $AppEnabled flag
	If ($AppEnabled){
		$Return.Status = 'OK'
		$Return.Message  = 'Enabled'
		Return $Return
	}
	Else{
		$Return.Status = 'Error'
		$Return.Message  = 'Unknown Error'
		Return $Return
	}
	#endregion FunctionWork

	#region FunctionReturn
 
	#Default Return Variable for my HTML Reporting Fucntion
	Write-UcmLog -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
	$return.Status = 'Unknown'
	$return.Message = 'Function did not encounter return statement'
	Return $Return
	#endregion FunctionReturn

}
# SIG # Begin signature block
# MIINFwYJKoZIhvcNAQcCoIINCDCCDQQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSLdjvjSLR7rZ4Y52NRqq9O1M
# fSagggpZMIIFITCCBAmgAwIBAgIQD274plv3rQv2N1HXnqk5jzANBgkqhkiG9w0B
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
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUXMvj9CGteuRvewEi
# Wlv55RADkvMwDQYJKoZIhvcNAQEBBQAEggEAM1Gyl3GLDHvSHab3aYq5TzTlKTXz
# CLSgAv5sOIWPCZ64sph5JnSfT5AifpBh1QEffuFn1WD6/06PQT9xgOMwVpM6h5yH
# /yAkPecLep16zt+hxh3qn2+VL91cpE9a0cTpdAKnfyBaTCQz0S/1mjCraESrwHJp
# ct55WGwUUJVeomK6gSfIA2nq3zYi3cT2dIsg9UtScPhoSRM+kebTgrVE6migYHI4
# dBb8EYoi6vhDtA+6ua3g89gV9OCCuZpkp3Jqv8c2UHo59osPvsKGth7IGG8UUcmc
# mDKdXIoPUMW0OTETw5zTPASE+BgSSa0PzutnbErMGARkYYh56Ith+dSxeA==
# SIG # End signature block
