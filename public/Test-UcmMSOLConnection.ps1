#PerformScriptSigning
Function Test-UcmMSOLConnection
{
	<#
			.SYNOPSIS
			Checks to see if we have a connection to Office365

			.DESCRIPTION
			Tries to pull tenant info and will attempt to reconnect or return an error depending if the -Reconnect flag is true or not.
			Handy for any script functions that need to perform something on MSOL, call this first with -reconnect set and if there is no connection New-UcmMSOLConnection will be called to connect with stored credentials.

			.EXAMPLE
			Test-UcmMSOLConnection
			Checks to see if we are connected to Office365, will return $Return.Status of 'OK' if true.

			Test-UcmMSOLConnection -Reconnect
			Checks to see if we are connected to Office365, if not connected will invoke New-UcmMSOLConnection and return a warning on sucsess.

			.INPUTS
			This function does not accept any input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple Keys to indicate status
			$Return.Status
			$Return.Message

			Return.Status can return one of three values
			"OK"      : Connected to Office365
			"Warn"    : Reconnected to Office365
			"Error"   : Not connected to Office365 and didnt reconnect.
			"Unknown" : Cmdlet reached the end of the function without returning anything, this shouldnt happen, if it does please log an issue on Github

			Return.Message returns descriptive text showing the connected tenant, mainly for logging or reporting

			.NOTES
			Version:		1.2
			Date:			20/06/2022

			.VERSION HISTORY
			1.2: Fixed bug with Reconnect switch being mandatory.

      1.1: Updated to "Ucm" naming convention
			Better inline documentation
			Reconnect function

			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Write-UcmLog: 						https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-UcmLog.ps1
			Write-HTMLReport:		 			https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-HTMLReport.ps1 (optional)
			AzureAD										(Install-Module AzureAD)
			MSOnline				 					(Install-Module MSOnline)

			.REQUIRED PERMISSIONS
			Any privledge level that can run 'Get-MsolCompanyInformation'

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPsTools

			.ACKNOWLEDGEMENTS

	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '', Scope='Function')] #todo, https://github.com/Atreidae/UcmPSTools/issues/23
	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Position=1)] [switch]$Reconnect #Todo Should this even be allowed from Pipeline?
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


	#endregion FunctionSetup

	#region FunctionWork

	Write-UcmLog -Message "Checking for Existing O365 Connection" -Severity 1 -Component $function
	Try #Check if we can pull company info
	{
		$Companyinfo = (Get-MsolCompanyInformation -ErrorAction Stop) #this will throw an error if we arent connected
		Write-UcmLog -Message "Connected to Tenant $($CompanyInfo.DisplayName)" -Severity 1 -Component $function
		$Return.Status = "OK"
		$Return.Message  = "Tenant: $($CompanyInfo.DisplayName)"
		Return $Return
	}
	Catch
	{
		#Not connected, check if we are reconnecting
		If ($Reconnect)
		{
			#We are reconnecting, call New-UcmMSOLConnection
			$result = (New-UcmMSOLConnection)

			#check to see if the reconnection was sucsessful
			If ($result.Status -ne "OK")
			{
				#Something went wrong, throw an error
				Write-UcmLog -Message "Could not auto reconnect to Office365" -Severity 3 -Component $function
				Write-UcmLog -Message "Error running New-UcmMsolConnection" -Severity 2 -Component $function
				Write-UcmLog -Message $error[0] -Severity 2 -Component $function
				$Return.Status = "Error"
				$Return.Message  = "No Office365 Connection"
				Return $Return
			}

			Else
			{
				#We did reconnect, return a warning.
				Write-UcmLog -Message "Reconnected to Office365" -Severity 3 -Component $function
				$Return.Status = "Warning"
				$Return.Message  = "Reconnectd to Office365"
				Return $Return
			}
		}

		Else
		{
			#We arent connected and the reconnect flag is not set, return an error.
			Write-UcmLog -Message "We dont appear to be connected to Office365! Connect to O365 and try again" -Severity 3 -Component $function
			Write-UcmLog -Message "Error running Get-MsolCompanyInformation" -Severity 2 -Component $function
			Write-UcmLog -Message $error[0] -Severity 2 -Component $function
			$Return.Status = "Error"
			$Return.Message  = "No Office365 Connection"
			Return $Return
		}
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