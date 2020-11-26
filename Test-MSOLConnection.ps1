Function Test-MSOLConnection
{
	<#
			.SYNOPSIS
			Checks to see if we are connected to an MSOL session

			.DESCRIPTION
			Tries to pull tenant info and will call New-MSOLConnection if unsucsessful

			.EXAMPLE
			Test-MSOLConnection

			.INPUTS
			This function does not accept any input

			.REQUIRED FUNCTIONS
			Write-Log: 						https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-Log.ps1
			Connect-MSOLConnection:		https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Connect-MSOLConnection.ps1
			Write-HTMLReport: 			https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-HTMLReport.ps1 (optional)
			AzureAD 							(Install-Module AzureAD) 
			Connect-MsolService

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
	$function = '.\Test-MSOLConnection'
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

	Write-Log -Message "Checking for Existing O365 Connection" -Severity 1 -Component $function
	Try #Check if we can pull company info
	{
		$Companyinfo = (Get-MsolCompanyInformation)
		Write-Log -Message "Connected to Tenant $($CompanyInfo.DisplayName)" -Severity 1 -Component $function
		$Return.Status = "OK"
		$Return.Message  = "Tenant: $($CompanyInfo.DisplayName)"
		Return $Return
	}
	Catch
	{
		#Todo, call my connection script here
		Write-Log -Message "We dont appear to be connected to Office365! Connect to O365 and try again" -Severity 3 -Component $function
		Write-Log -Message "Error running Get-MsolCompanyInformation" -Severity 2 -Component $function
		Write-Log -Message $error[0] -Severity 2 -Component $function
		$Return.Status = "Aborted"
		$Return.Message  = "No Office365 Connection"
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