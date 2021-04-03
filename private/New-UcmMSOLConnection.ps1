Function New-UcmMSOLConnection
{
	<#
			.SYNOPSIS
			Grabs stored creds and creates a new MSOL session

			.DESCRIPTION
			This function is designed to auto reconnect to Azure AD (V1) during batch migrations and the like.
			At present, it does not support modern auth. (I havent implemented it yet)
			
			When called, the function looks for a cred.xml file in the current folder and attempts to connect to Office 365 using Basic Auth
			
			If there is no cred.xml in the current folder it will prompt for credentials, encrypt them and store them in a cred.xml file.
			The encrypted credentials can only be read by the windows user that created them so other users on the same system cant steal your credentials.

			.EXAMPLE
			PS> New-MSOLConnection

			.INPUTS
			This function does not accept any input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple Keys to indicate status
			$Return.Status 
			$Return.Message 

			Return.Status can return one of three values
			"OK"      : Connected to Azure AD (V1)
			"Error"   : Not connected to Azure AD (V1)
			"Unknown" : Cmdlet reached the end of the fucntion without returning anything, this shouldnt happen, if it does please log an issue on Github
			
			Return.Message returns descriptive text showing the connected tenant, mainly for logging or reporting

			.NOTES
			Version:		1.1
			Date:			21/03/2021

			.VERSION HISTORY
			1.1: Updated to "Ucm" naming convention
			Better inline documentation
					
			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			UcmPSTools 								(Install-Module UcmPSTools)
				Write-UcmLog:						https://github.com/Atreidae/UcmPSTools/blob/main/public/Write-UcmLog.ps1
			MSOnline				 					(Install-Module MSOnline)

			.REQUIRED PERMISSIONS
			Any privledge level that can run 'Connect-MsolService' 
			Typically "Office 365 User Administrator" or better

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPSTools

			.ACKNOWLEDGEMENTS
			Greig Sheridan: Stop connect cmdlets deleting password variable https://github.com/Atreidae/BounShell/issues/7
	#>

	Param #No parameters
	(

	)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'New-UcmMSOLConnection'
	[hashtable]$Return = @{}
	$return.Function = $function
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
	
	#endregion FunctionSetup

	#region FunctionWork

	#Check we have creds in memory, if not check for cred.xml, failing that prompt the user and store them.
	If ($Global:Config.SignInAddress -eq $null)
	{
		Write-UcmLog -Message "No Credentials stored in Memory, checking for Creds file" -Severity 2 -Component $function
		If(!(Test-Path cred.xml)) 
		{
			Write-UcmLog -component $function -Message 'Could not locate creds file' -severity 2

			#Create a new creds variable
			$null = (Remove-Variable -Name Config -Scope Global -ErrorAction SilentlyContinue)
			$global:Config = @{}

			#Prompt user for creds
			$Global:Config.SignInAddress = (Read-Host -Prompt "Username")
			$Global:Config.Password = (Read-Host -Prompt "Password")
			$Global:Config.Override = (Read-Host -Prompt "OverrideDomain (Blank for none)")

			#Encrypt the creds
			$global:Config.Credential = ($Global:Config.Password | ConvertTo-SecureString -AsPlainText -Force)
			Remove-Variable -Name "Config.Password" -Scope "Global" -ErrorAction SilentlyContinue

			#write a secure creds file
			$Global:Config | Export-Clixml -Path ".\cred.xml"
		}
		Else
		{
			Write-UcmLog -component $function -Message 'Importing Credentials File' -severity 2
			$global:Config = @{}
			$global:Config = (Import-Clixml -Path ".\cred.xml")
			Write-UcmLog -component $function -Message 'Creds Loaded' -severity 2
		}
	}

	#Get the creds ready for the module

	$global:StoredPsCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($global:Config.SignInAddress, $global:Config.Credential)
	($global:StoredPsCred).Password.MakeReadOnly() #Stop modules deleteing the variable.

	#Connect to MSOL
	$pscred = $global:StoredPsCred
	Write-UcmLog -Message 'Connecting to MSOnline (AzureAD V1)' -Severity 2 -Component $function
	Try
	{
		$MSOLSession = (Connect-MsolService -Credential $pscred)
		
		#Import the connected session
		Import-Module (Import-PSSession -Session $MSOLSession -AllowClobber -DisableNameChecking) -Global -DisableNameChecking
		
		#We haven't errored so return sucsessful
		$Return.Status = "OK"
		$Return.Message  = "Connected"
		Return $Return
	}
	Catch
	{
		#Something went wrong during the try block, return error
		$Return.Status = "Error"
		$Return.Message  = "Failed to connect to Microsoft Online (AzureAD V1): $error[0]"
		Return $Return
	}
	#endregion FunctionWork

	#region FunctionReturn
 
	#Default Return Variable for my HTML Reporting Fucntion
	Write-UcmLog -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
	$return.Status = "Unknown"
	$return.Message = "Function did not encounter return statement"
	Return $Return
	#endregion FunctionReturn

}
# SIG # Begin signature block
# MIINFwYJKoZIhvcNAQcCoIINCDCCDQQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUwd10ZqtSJQ5FkXJ9I1JV2bKy
# cIKgggpZMIIFITCCBAmgAwIBAgIQD274plv3rQv2N1HXnqk5jzANBgkqhkiG9w0B
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
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUmOAg9b1a2/Pi4IPl
# hADLk4cTCaAwDQYJKoZIhvcNAQEBBQAEggEASry/bGKMXiB+IZCgE/GCXk1tB/96
# oBZKvnUzHijXfCjlvDr2jLEX9FsdsZICcI1aJR8EtAQALUFK5zhGvNxjDoFRolm7
# 5YLQRlpUUTYYGTowk2dvdDmgAwUxV4VkpTvmqS57HYjrRKGZDlmHFSD3VuPMWE+g
# aMSGG65g2bOZsf+put16ruPTdsbX9qo3BbYWBQNSRdyKpJoWsqp9/xpLwWIXnri/
# xEyA6rS2FoWEmkKhFBHaU78XSMj7tDjnUq4HIZQLwfZeDBni5cOuJn2yX8trX7aK
# vqMfsYXJMIYKerdaqfXDsV6ISod05bc5We9INJ9AAQQVCkkd36dxguS6dQ==
# SIG # End signature block
