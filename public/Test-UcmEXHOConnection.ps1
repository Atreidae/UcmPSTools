Function Test-UcmEXHOConnection
{
	<#
			.SYNOPSIS
			Checks to see if we are connected to an Exchange Online session

			.DESCRIPTION
			Tries to pull tenant info and will call New-UcmEXHOConnection if unsucsessful

			.EXAMPLE
			Test-EXHOConnection

			.PARAMETER Reconnect
			When the flag is set Test-UcmEXHOConnection will attempt to automatically reconnect using New-UcmEXHOConnection

			.INPUTS
			This function does not accept any input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple Keys to indicate status
			$Return.Status 
			$Return.Message 
			
			Return.Status can return one of three values
			"OK"      : Connected to Office365
			"Error"   : Not connected to Office365
			"Unknown" : Cmdlet reached the end of the fucntion without returning anything, this shouldnt happen, if it does please log an issue on Github
			
			Return.Message returns descriptive text showing the connected tenant, mainly for logging or reporting

			.NOTES
			Version:		1.1
			Date:			18/03/2021

			.VERSION HISTORY
			1.1: Updated to "Ucm" naming convention
					 Better inline documentation
					
			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			UcmPSTools 								(Install-Module UcmPSTools)
				Write-UcmLog: 						https://github.com/Atreidae/PowerShell-Fuctions/blob/main/public/Write-UcmLog.ps1
				Connect-SFBOConnection:		https://github.com/Atreidae/PowerShell-Fuctions/blob/main/public/Connect-UcmEXHOConnection.ps1
				Write-HTMLReport: 				https://github.com/Atreidae/PowerShell-Fuctions/blob/main/public/Write-HTMLReport.ps1 (optional)
			ExchangeOnlineShell 			(Install-Module ExchangeOnlineShell) #Note this is a community module, the official Exchange module can only be installed via ClickOnce

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Fuctions

			.ACKNOWLEDGEMENTS

	#>

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1,HelpMessage='When set to $true will attempt to automatically reconnect using New-UcmEXHOConnection')] [switch]$Reconnect
	)


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Test-UcmEXHOConnection'
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


	Write-UcmLog -Message "Checking for Existing EXHO Connection" -Severity 1 -Component $function
	$Session =(Get-PSSession | Where-Object {$_.ConfigurationName -like "Microsoft.Exchange"}) 
If($Session.state -ne "opened")
	{
		Write-UcmLog -Message "We dont appear to be connected to Office365!" -Severity 3 -Component $function
		If ($Reconnect)
		{
			Try
			{ 
			Get-PSSession | Where-Object {$_.Name -like "Microsoft.Exchange"} | Remove-PSSession
			New-UcmEXHOConnection
			$Return.Status = "OK"
			$Return.Message  = "Reconnected"
			Return $Return
			}
			Catch
			{
			$Return.Status = "Error"
			$Return.Message  = "Unable to reconnect to Exchange Online $error[0]"
			Return $Return
			}
		}
		Else
		{
			$Return.Status = "Error"
			$Return.Message  = "Not Connected"
			Return $Return
		}
	}
Else
{
		$Return.Status = "OK"
		$Return.Message  = "Existing Connection"
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