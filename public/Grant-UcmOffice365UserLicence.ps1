Function Grant-UcmOffice365UserLicence
{
	<#
			.SYNOPSIS
			Assigns a licence to an Office365 user

			.DESCRIPTION
			Function will check for available licences and assign one to the supplied user
			This function will also notify you if you are below 5% of your below licences, a similar warning will be generated if you have less than 5 licences available 

			.EXAMPLE
			PS> Grant-UcmOffice365UserLicence -upn 'button.mash@contoso.com' -LicenceType 'MCOEV' -Country 'AU'
			Grants the Microsoft Phone System Licence to the user Button Mash

			.INPUTS
			This function accepts both parameter and pipline input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple Keys to indicate status
			$Return.Status 
			$Return.Message 
			
			Return.Status can return one of four values
			"OK"      : The licence has been assigned, or is already assigned to the user.
			"Warn"    : The licence was assigned, but there was an issue. For example low availability of licences Check $return.message for more information
			"Error"   : Unable to assign licence, check $return.message for more information
			"Unknown" : Cmdlet reached the end of the fucntion without returning anything, this shouldnt happen, if it does please log an issue on Github

			Return.Message returns descriptive text based on the outcome, mainly for logging or reporting

			.NOTES
			Version:		1.1
			Date:			18/03/2021

			.VERSION HISTORY
			1.1: Updated to "Ucm" naming convention
			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Write-UcmLog: 					https://github.com/Atreidae/PowerShell-Functions/blob/main/Write-UcmLog.ps1
			Test-UcmMSOLConnection:	https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Test-UcmMSOLConnection.ps1
			New-UcmMSOLConnection:	https://github.com/Atreidae/PowerShell-Fuctions/blob/main/New-UcmMSOLConnection.ps1
			Write-UcmHTMLReport:		https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-UcmHTMLReport.ps1
			AzureAD									(Install-Module AzureAD) 
			MSOnline								(Install-Module MSOnline)

			.REQUIRED PERMISSIONS
			'Office365 User Admin' or better

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Write-UcmLogs

			.ACKNOWLEDGEMENTS
			Assign licenses for specific services in Office 365 using PowerShell: 


	#>

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1,HelpMessage='The UPN of the user you wish to enable the Service Plan on, eg: button.mash@contoso.com')] [string]$UPN, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2,HelpMessage='The licence you wish to assign, eg: MCOEV')] [string]$LicenceType,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=3,HelpMessage='the 2 letter country code for the users country, must be in capitals. eg: AU')] [String]$Country #TODO Add country validation.
	)


	#region Write-UcmLogSetup, Set Default Variables for HTML Reporting and Write Log
	$Function = 'Grant-UcmOffice365UserLicence'
	[hashtable]$Return = @{}
	$return.function = $Function
	$return.Status = "Unknown"
	$return.Message = "Function did not return a status message"

	# Log why we were called
	Write-UcmLog -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-UcmLog -Message "Parameters" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$Args" -Severity 1 -Component $function -LogOnly
	Write-Host '' #Insert a blank line to make reading output easier on loops
	
	#endregion functionSetup


	#region FunctionWork

	#Check to see if we are connected to MSOL
	$Test = (Test-UcmMSOLConnection)
	If ($Test.Status -ne "OK")
	{
		Write-UcmLog -Message "Something went wrong granting $UPN's licence" -Severity 3 -Component $function
		Write-UcmLog -Message "Test-UcmMSOLConnection could not locate an MSOL connection" -Severity 2 -Component $function
		$Return.Status = "Error"
		$Return.Message = "No MSOL Connection"
		Return $Return
	}

	#Check Tenant has the licence
	Write-UcmLog -Message "Verifying $LicenceType is available" -Severity 2 -Component $function
	Try
	{
		#Office365 does this thing where it preprends the tenant name on the licence
		#For example PHONESYSTEM_VIRTUALUSER would be "contoso:PHONESYSTEM_VIRTUALUSER"
		#So we need to learn the prefix, we do this by looking for the licence and storing it
		$O365AcctSku = $null
		$O365AcctSku = Get-MsolAccountSku | Where-Object {$_.SkuPartNumber -like $LicenceType}

		#Build the full licence name
		$LicenceToAssign = "$($O365AcctSku.AccountName):$LicenceType"
	}
	Catch
	{
		Write-UcmLog -Message "Error Running Get-MsolAccountSku" -Severity 3 -Component $function
		Write-UcmLog -Message $error[0]  -Severity 3 -Component $function
		$Return.Status = "Error"
		$Return.Message = "Unable to run Get-MsolAccountSku to obtain tenant prefix"
		Return $Return
	}

	If ($O365AcctSku -eq $null)
	{
		Write-UcmLog -Message "Unable to locate Licence on Tenant" -Severity 3 -Component $function
		$Return.Status = "Error"
		$Return.Message = "Unable to locate $LicenceType Licence"
		Return $Return
	}

	#Check to see if there are free licences. Trigger a warning on less than 5% available
	$LicenceUsedPercent = (($O365AcctSku.ConsumedUnits / $O365AcctSku.ActiveUnits) * 100)
	$AvailableLicenceCount = ($O365AcctSku.ActiveUnits - $O365AcctSku.ConsumedUnits)
	If (($LicenceUsedPercent -ge 95) -or ($AvailableLicenceCount -le 5))
	{
		Write-UcmLog -Message "Only $AvailableLicenceCount $LicenceType Licences Left" -Severity 3 -Component $function
		Write-UcmLog -Message "Available licence count low..." -Severity 3 -Component $function
		$WarningFlag = $True
		$WarningMessage = "Low Licence Count"
	}

	#Check for user
	Write-UcmLog -Message "Checking for Existing User $UPN ..." -Severity 2 -Component $function

	Try 
	{
		$O365User = (Get-MsolUser -UserPrincipalName $UPN -ErrorAction Stop)
		Write-UcmLog -Message "User Exists. checking licences..." -Severity 2 -Component $function
		If ($O365User.Licenses.accountSkuID -contains $LicenceToAssign)
	  {
		  Write-UcmLog -Message "User already has that licence, Skipping" -Severity 3 -Component $function

			#Check to see if we encountered a warning during the run and inject it into the status message
		  If ($warningFlag) 
			{
				$Return.Status = "Warning"
				$Return.Message = "Skipped: Already Licenced, Warning Message $WarningMessage"
				Return $Return
			}
			Else
			{
				$Return.Status = "OK"
				$Return.Message = "Skipped: Already Licenced"
				Return $Return
			}
	  }


		#User Exists, try assigning a licence to the user
		Write-UcmLog -Message "User Exists, Grant Licence" -Severity 2 -Component $function
		Try 
		{
			#Set the User location, this is required to set the relevant licences. Users can be created without setting a country mistakenly.
			Write-UcmLog -Message "Setting Location" -Severity 2 -Component $function
			[void] (Set-MsolUser -UserPrincipalName $UPN -UsageLocation $Country)
			
			#Try assigning the licence
			[Void] (Set-MsolUserLicense -UserPrincipalName $UPN -AddLicenses $LicenceToAssign -ErrorAction stop)
			Write-UcmLog -Message "Licence Granted" -Severity 2 -Component $function
			
			#Check to see if we encountered a warning during the run and inject it into the status message
			If ($warningFlag)
			{
				$Return.Status = "Warning"
				$Return.Message = "Licence Granted, Warning Message $WarningMessage"
				Return $Return
			}
			Else
			{
				$Return.Status = "OK"
				$Return.Message = "Licence Granted"
				Return $Return
			}
		}
		#Something Failed either setting the licence or the country
		Catch 
		{
			Write-UcmLog -Message "Something went wrong licencing user $UPN" -Severity 3 -Component $function
			Write-UcmLog -Message $Error[0] -Severity 3 -Component $function
			$Return.Status = "Error"
			$Return.Message = $Error[0]
			Return $Return
		}
	} #End User Check try block #Todo, split this up into seperate blocks to minimise nesting.

	#User doesnt exist, throw error message
	Catch 
	{ 
		Write-UcmLog -Message "Something went wrong granting $UPN's licence" -Severity 3 -Component $function
		Write-UcmLog -Message "Could not locate user $UPN" -Severity 2 -Component $function
		$Return.Status = "Error"
		$Return.Message = "User Not Found"
		Return $Return
	}
	#endregion FunctionWork


	#region FunctionReturn
 
	#Default Return Variable for my HTML Reporting Fucntion
	Write-UcmLog -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
	$return.Status = "Unknown"
	$return.Message = "Write-UcmLog did not encounter return statement"
	Return $Return
	#endregion Write-UcmLogReturn
}
# SIG # Begin signature block
# MIINFwYJKoZIhvcNAQcCoIINCDCCDQQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUh78RbCMEQT7TrvrHrAsKM8mj
# 5FKgggpZMIIFITCCBAmgAwIBAgIQD274plv3rQv2N1HXnqk5jzANBgkqhkiG9w0B
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
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUH4K255JYhRM9IjK5
# mn2glcCZDKcwDQYJKoZIhvcNAQEBBQAEggEAVd1MqEOk1Y5tWVn6nZY4knv48aGK
# J3EFfNC6asWUC0udxxxxU3J1VANtgROqYoLR87muK6oRw9VjrDkc10TTfKnxL8+b
# BWTBHI0mhTprnIErAZMKJWnkfTSo59+5uUgvgfu7AIY0H8Y4kttFw1hrILbECX5x
# OOuXT37uioomHXcBfUuA5fq5tIPlxwMS83jaKonAVppspoUT0D9A8k2Tx1/7C+hZ
# oDNQHwzrOhsLNrXixgZ2sojc48Df1izIg7X7jVeJYquVUOTuFSKhE1Rs1RqaIlt4
# qgQI5cP1nnRQ14tM0ZgJtbc3DM4Wr/i9jXyz2lFCPErlic3j8CoyUhvs1A==
# SIG # End signature block
