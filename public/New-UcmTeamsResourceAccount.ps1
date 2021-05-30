#PerformScriptSigning
Function New-UcmTeamsResourceAccount
{
	<#
			.SYNOPSIS
			Checks for and creates a new Microsoft Teams Resource Account for a Call Queue or AutoAttendant

			.DESCRIPTION
			Checks for and creates a new Microsoft Teams Resource Account for a Call Queue or AutoAttendant
			This function will also set the application ID depending on the setting of the ResourceType parameter

			.EXAMPLE
			UcmTeamsResourceAccount -UPN calebs@contoso.onmicrosoft.com -DisplayName 'Caleb Sills' -ResourceType CallQueue

			.PARAMETER UPN
			The UPN of the user you wish to create, eg: "button.mash@contoso.com"

			.PARAMETER DisplayName
			The Display Name of the user you wish to create, eg: "Button Mash"

			.PARAMETER ResourceType
			Used to set the ApplicationID of the new user
			Valid options are "AutoAttendant" or "CallQueue"

			.INPUTS
			This function accepts both parameter and pipline input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple keys to indicate status
			$Return.Status 
			$Return.Message 

			Return.Status can return one of four values
			"OK"      : Created Resource Account
			"Warn"    : Resource Account already exists, creation was skipped
			"Error"   : Something happend when attempting to create the Resource Account, check $return.message for more information
			"Unknown" : Cmdlet reached the end of the fucntion without returning anything, this shouldnt happen, if it does please log an issue on Github
			
			Return.Message returns descriptive text showing the connected tenant, mainly for logging or reporting

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPsTools

			.ACKNOWLEDGEMENTS

			.NOTES
			Version:		1.1
			Date:			03/04/2021

			.VERSION HISTORY
			1.1: Updated to "Ucm" naming convention
			Better inline documentation
					
			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Modules
			Microsoft Teams						(Install-Module MicrosoftTeams)
			UcmPSTools							(Install-Module UcmPsTools) Includes Cmdlets below.

			Cmdlets
			Write-UcmLog: 						https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-UcmLog.ps1
			New-UcmSFBOConnection				https://github.com/Atreidae/UcmPsTools/blob/main/public/New-UcmSFBOConnection.ps1

			.REQUIRED PERMISIONS
			'Teams Administrator' or better

	#>

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1,HelpMessage='The UPN of the user you wish to create, eg: "button.mash@contoso.com"')] [string]$UPN, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2,HelpMessage='The Display Name of the user you wish to create, eg: "Button Mash"')] [string]$DisplayName,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=3,HelpMessage='Used to set the ApplicationID of the new user, Valid options are "AutoAttendant" or "CallQueue"')] [ValidateSet('AutoAttendant', 'CallQueue')] [string]$ResourceType
	)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'New-UcmTeamsResourceAccount'
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

	#Calculate the Application ID for the new account
	Switch ($ResourceType)
	{
		'AutoAttendant' {$ApplicationID ='ce933385-9390-45d1-9512-c8d228074e07'}
		'CallQueue' {$ApplicationID ='11cd3e2e-fccb-42ad-ad00-878b93575e07'}
	}

	#Check to see if we are connected to SFBO
	$Test = (Test-UcmSFBOConnection)
	If ($Test.Status -eq "Error")
	{
		#Test-UcmSFBOConnection returned an error, return an error
		Write-UcmLog -Message "Something went wrong creating user $UPN" -Severity 3 -Component $function
		Write-UcmLog -Message "Test-UcmSFBOConnection could not locate an SFBO connection" -Severity 2 -Component $function
		$Return.Status = "Error"
		$Return.Message = "No SFBO Connection"
		Return $Return
	}

	#Check to see if the requested account exists
	Write-UcmLog -Message "Checking for Existing Resource Account $UPN ..." -Severity 2 -Component $function
	
	#TODO, we should be checking if that UPN exists in general. https://github.com/Atreidae/UcmPSTools/issues/1
	$AppInstance = $null
	$AppInstance = (Get-CsOnlineApplicationInstance | Where-Object {$_.UserPrincipalName -eq $UPN})#TODO is there a better way to filter this? https://github.com/Atreidae/UcmPSTools/issues/2

	If ($AppInstance.UserPrincipalName -eq $UPN)
	{
		#We found a resource account with the same name, assume it already been made, return a warning and skip
		Write-UcmLog -Message "Resource Account already exists, Skipping" -Severity 3 -Component $function
		$Return.Status = "Warning"
		$Return.Message = "Skipped: Account Already Exists"
		Return $Return
	}
	Else
	{
		#Resource account doesnt exist, let's make them
		Try
		{
			Write-UcmLog -Message "Account not found. Creating user $UPN" -Severity 2 -Component $function
			[Void] (New-CsOnlineApplicationInstance -UserPrincipalName $UPN -DisplayName $DisplayName -ApplicationId $ApplicationID -ErrorAction Stop)
			
			#We created the account OK, return an OK result.
			Write-UcmLog -Message "Resource Account Created Sucessfully" -Severity 2 -Component $function
			$Return.Status = "OK"
			$Return.Message = "Resource Account Created"
			Return $Return
		}
		Catch
		{
			#Something went wrong making the resource account, return an error
			Write-UcmLog -Message "Something went wrong creating resource account $UPN" -Severity 3 -Component $function
			Write-UcmLog -Message $Error[0] -Severity 3 -Component $Function
			$Return.Status = "Error"
			$Return.Message = $Error[0]
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