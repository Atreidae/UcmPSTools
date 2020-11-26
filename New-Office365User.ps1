Function New-Office365User {
	<#
			.SYNOPSIS
			Checks for and creates a new blank Office 365 user

			.DESCRIPTION
			Checks for and creates a new blank Office 365 user

			.EXAMPLE
			New-Office365User -UPN calebs@contoso.onmicrosoft.com -Password "Passw0rd1!" -FirstName Caleb -LastName Sills -Country US -DisplayName "Caleb Sills"

			.INPUTS
			UriCheck the number to check against

			.REQUIRED FUNCTIONS
			Write-Log: https://github.com/Atreidae/PowerShell-Fuctions/blob/main/New-Office365User.ps1
			Write-HTMLReport: https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-HTMLReport.ps1 (optional)
			AzureAD (Install-Module AzureAD) 
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

	Param  (
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1)] $UPN, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2)] $Password,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=3)] $FirstName,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=4)] $LastName,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=5)] $Country,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=6)] $DisplayName
	)


	#todo, 
	$Script:LogFileLocation = $PSCommandPath -replace '.ps1','.log'


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'New-Office365User'
	[hashtable]$return = @{}
	$return.Status = "Unknown"
	$return.Message = "Function did not return a status message"

	# Log why we were called
	Write-Log -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-Log -Message "Parameters" -Severity 3 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$Args" -Severity 3 -Component $function -LogOnly
	
	#endregion FunctionSetup

	#region FunctionWork

	#TODO Check for Connection to AzureAD and call a new connection if required.

	Write-Log -Message "Creating user $UPN" -Severity 1 -Component $function
	Try 
	{
		New-MsolUser -UserPrincipalName $UPN -DisplayName $DisplayName -FirstName $Firstname -LastName $LastName -UsageLocation $Country -Password $Password -ErrorAction Stop
		$ReturnStatus = "OK"
		$ReturnMessage = "User Created"
	}
	Catch
	{
		Write-Log -Message "Something went wrong creating user $UPN" -Severity 3 -Component $function
		Write-Log -Message $Error[0] -Severity 3 -Component $Function
		$ReturnStatus = "Error"
		$ReturnMessage = $Error[0]
	}

	#endregion FunctionWork

	#Set-MsolUserLicense -UserPrincipalName <userPrincipalName> -AddLicenses <tenantName:DEVELOPERPACK> -LicenseOptions $MyServicePlans  
 

	#region FunctionReturn
 
	#Default Return Variable for my HTML Reporting Fucntion
	$Return.Object = $OutputCollection #Return the results to the calling function
	$return.Function = $function
	$return.Status = $ReturnStatus
	$return.Message = $ReturnMessage
	Return
	#endregion FunctionReturn
}