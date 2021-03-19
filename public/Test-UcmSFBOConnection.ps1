Function Test-SFBOConnection
{
	<#
			.SYNOPSIS
			Checks to see if we are connected to an SFBO session

			.DESCRIPTION
			Tries to pull tenant info and will call New-SFBOConnection if unsucsessful

			.EXAMPLE
			Test-SFBOConnection

			.INPUTS
			This function does not accept any input

			.REQUIRED FUNCTIONS
			Write-Log: 						https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-Log.ps1
			Connect-SFBOConnection:		https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Connect-MSOLConnection.ps1
			Write-HTMLReport: 			https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-HTMLReport.ps1 (optional)
			SkypeOnlineConnector

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Fuctions

			.ACKNOWLEDGEMENTS

			.NOTES
			Version:		1.0
			Date:			25/11/2020

			.VERSION HISTORY
			1.0: Initial Public Release

	#>

	Param #No parameters
	(

	)


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Test-SFBOConnection'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = "Unknown"
	$return.Message = "Function did not return a status message"

	# Log why we were called
	Write-Log -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-Log -Message "Parameters" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$Args" -Severity 1 -Component $function -LogOnly
Write-Host '' #Insert a blank line to make reading output easier on loops
	
	#endregion FunctionSetup

	#region FunctionWork


	Write-Log -Message "Checking for Existing SFBO Connection" -Severity 1 -Component $function
	$Session =(Get-PSSession | Where-Object {$_.Name -like "SfBPowerShellSession*"}) 
if($Session.state -ne "opened")
	{
		Get-PSSession | Where-Object {$_.Name -like "SfBPowerShellSession*"} |Remove-PSSession
		Write-Log -Message "We dont appear to be connected to Office365!" -Severity 3 -Component $function
		New-SFBOConnection
		$Return.Status = "OK"
		$Return.Message  = "Reconnected"
		Return $Return
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
	Write-Log -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
	$return.Status = "Unknown"
	$return.Message = "Function did not encounter return statement"
	Return $Return
	#endregion FunctionReturn

}