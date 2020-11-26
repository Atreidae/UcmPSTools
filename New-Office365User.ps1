Function New-Office365User
{
	<#
			.SYNOPSIS
			Checks for and creates a new blank Office 365 user

			.DESCRIPTION
			Checks for and creates a new blank Office 365 user

			.EXAMPLE
			New-Office365User -UPN calebs@contoso.onmicrosoft.com -Password "Passw0rd1!" -FirstName Caleb -LastName Sills -Country US -DisplayName "Caleb Sills"

			.INPUTS
			This function accepts both parameter and pipline input

			.REQUIRED FUNCTIONS
			Write-Log: https://github.com/Atreidae/PowerShell-Functions/blob/main/New-Office365User.ps1
			AzureAD (Install-Module AzureAD) 
			Connect-MsolService

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Functions

			.ACKNOWLEDGEMENTS

			.NOTES
			Version:		1.0
			Date:			25/11/2020

			.VERSION HISTORY
			1.0: Initial Public Release

	#>

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1)] $UPN, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2)] $Password,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=3)] $FirstName,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=4)] $LastName,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=5)] $Country,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=6)] $DisplayName
	)


	#todo, Remove Debugging 
	#$Script:LogFileLocation = $PSCommandPath -replace '.ps1','.log'
	$VerbosePreference = "Continue"


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'New-Office365User'
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

	#Check to see if we are connected to MSOL

	$Test = (Test-MSOLConnection)
	If ($Test.Status -ne "OK")
	{
		Write-Log -Message "Something went wrong creating user $UPN" -Severity 3 -Component $function
		Write-Log -Message "Test-MSOLConnection could not locate an MSOL connection" -Severity 2 -Component $function
		$Return.Status = "Error"
		$Return.Message = "No MSOL Connection"
		Return $Return
	}

	Write-Log -Message "Checking for Existing User $UPN ..." -Severity 2 -Component $function
	Try #Check user exits
	{
		[void] (Get-MsolUser -UserPrincipalName $UPN -ErrorAction Stop)
		Write-Log -Message "User Exists, Skipping" -Severity 3 -Component $function
		$Return.Status = "Warning"
		$Return.Message = "User Already Exists"
		Return $Return
	}
	Catch
	{ #User Doesnt Exist, make them
		Write-Log -Message "Not Found. Creating user $UPN" -Severity 2 -Component $function
		Try 
		{
			[Void] (New-MsolUser -UserPrincipalName $UPN -DisplayName $DisplayName -FirstName $Firstname -LastName $LastName -UsageLocation $Country -Password $Password -ErrorAction Stop)
			Write-Log -Message "User Created Sucessfully" -Severity 2 -Component $function
			$Return.Status = "OK"
			$Return.Message = "User Created"
			Return $Return
		}
		Catch
		{
			Write-Log -Message "Something went wrong creating user $UPN" -Severity 3 -Component $function
			Write-Log -Message $Error[0] -Severity 3 -Component $Function
			$Return.Status = "Error"
			$Return.Message = $Error[0]
			Return $Return
		}
	}
#endregion FunctionWork

#Set-MsolUserLicense -UserPrincipalName <userPrincipalName> -AddLicenses <tenantName:DEVELOPERPACK> -LicenseOptions $MyServicePlans


#region FunctionReturn
 
#Default Return Variable for my HTML Reporting Fucntion
Write-Log -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
$return.Status = "Unknown"
$return.Message = "Function did not encounter return statement"
Return $Return
#endregion FunctionReturn
}