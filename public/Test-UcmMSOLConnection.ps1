Function Test-UcmMSOLConnection
{
	<#
			.SYNOPSIS
			Checks to see if we have a connection to Office365

			.DESCRIPTION
			Tries to pull tenant info and will return an error if unsucsessful

			.EXAMPLE
			Test-UcmMSOLConnection
			Checks to see if we are connected to Office365, will return $Return.Status of 'OK' if true.

			.INPUTS
			This function does not accept any input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple Keys to indicate status
			$Return.Status 
			$Return.Message 
			
			Return.Status can return one of three values
			"OK"      : Connected to Exchange Online
			"Error"   : Not connected to Exchange Online
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
			Write-UcmLog: 						https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-UcmLog.ps1
			Write-HTMLReport:		 			https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-HTMLReport.ps1 (optional)
			AzureAD 									(Install-Module AzureAD) 
			MSOnline				 					(Install-Module MSOnline) 

			.REQUIRED PERMISSIONS
			Any privledge level that can run 'Get-MsolCompanyInformation'

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Fuctions

			.ACKNOWLEDGEMENTS

	#>

	Param #No parameters
	(

	)


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Test-UcmMSOLConnection'
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

	Write-UcmLog -Message "Checking for Existing O365 Connection" -Severity 1 -Component $function
	Try #Check if we can pull company info
	{
		$Companyinfo = (Get-MsolCompanyInformation) #this will throw an error if we arent connected
		Write-UcmLog -Message "Connected to Tenant $($CompanyInfo.DisplayName)" -Severity 1 -Component $function
		$Return.Status = "OK"
		$Return.Message  = "Tenant: $($CompanyInfo.DisplayName)"
		Return $Return
	}
	Catch
	{
		Write-UcmLog -Message "We dont appear to be connected to Office365! Connect to O365 and try again" -Severity 3 -Component $function
		Write-UcmLog -Message "Error running Get-MsolCompanyInformation" -Severity 2 -Component $function
		Write-UcmLog -Message $error[0] -Severity 2 -Component $function
		$Return.Status = "Error"
		$Return.Message  = "No Office365 Connection"
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