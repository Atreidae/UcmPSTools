Function New-TeamsResourceAccount
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
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2)] $DisplayName,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=3)][ValidateSet('AutoAttendant', 'CallQueue')] $ResourceType

	)

	#todo, Remove Debugging 
	$Script:LogFileLocation = $PSCommandPath -replace '.ps1','.log'
	$VerbosePreference = "Continue"


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'New-TeamsResourceAccount'
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

	#Set the Application ID for the 
	Switch ($ResourceType)
	{
		'AutoAttendant' {$ApplicationID ='ce933385-9390-45d1-9512-c8d228074e07'}
		'CallQueue' {$ApplicationID ='11cd3e2e-fccb-42ad-ad00-878b93575e07'}
	}


	<#Check to see if we are connected to SFBO

			$Test = (Test-SFBOConnection)
			If ($Test.Status -ne "OK")
			{
			Write-Log -Message "Something went wrong creating user $UPN" -Severity 3 -Component $function
			Write-Log -Message "Test-MSOLConnection could not locate an MSOL connection" -Severity 2 -Component $function
			$Return.Status = "Error"
			$Return.Message = "No MSOL Connection"
			Return $Return
			}
	#>
	Write-Log -Message "Checking for Existing Resource Account $UPN ..." -Severity 2 -Component $function
	#Check user exits
	
	$AppInstance = $null
	$AppInstance = (Get-CsOnlineApplicationInstance | Where-Object {$_.UserPrincipalName -eq $UPN})
	if ($AppInstance.UserPrincipalName -eq $UPN)
	{
		Write-Log -Message "Resource Account already exists, Skipping" -Severity 3 -Component $function
		$Return.Status = "Warning"
		$Return.Message = "Skipped: Account Already Exists"
		Return $Return
	}
	Else
	{ #User Doesnt Exist, make them
		Write-Log -Message "Not Found. Creating user $UPN" -Severity 2 -Component $function
		Try 
		{
			[Void] (New-CsOnlineApplicationInstance -UserPrincipalName $UPN -DisplayName $DisplayName -ApplicationId $ApplicationID -ErrorAction Stop)
			Write-Log -Message "Resource Account Created Sucessfully" -Severity 2 -Component $function
			$Return.Status = "OK"
			$Return.Message = "Resource Account Created"
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