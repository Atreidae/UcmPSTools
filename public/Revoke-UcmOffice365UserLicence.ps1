#PerformScriptSigning
Function Revoke-UcmOffice365UserLicence
{
	<#
			.SYNOPSIS
			Revokes a licence to an Office365 user

			.DESCRIPTION
			Function will check for revoke the requested licence from the supplied user

			.EXAMPLE
			PS> Revoke-UcmOffice365UserLicence -upn 'button.mash@contoso.com' -LicenceType 'MCOEV'
			Grants the Microsoft Phone System Licence to the user Button Mash

			.INPUTS
			This function accepts both parameter and pipline input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple Keys to indicate status
			$Return.Status
			$Return.Message

			Return.Status can return one of four values
			"OK"      : The licence has been removed.
			"Warn"    : The licence was not assigned to the user, no changes have been made
			"Error"   : Unable to revoke licence, check $return.message for more information
			"Unknown" : Cmdlet reached the end of the fucntion without returning anything, this shouldnt happen, if it does please log an issue on Github

			Return.Message returns descriptive text based on the outcome, mainly for logging or reporting

			.NOTES
			Version:		1.1
			Date:			03/04/2021

			.VERSION HISTORY
			1.1: Updated to "Ucm" naming convention
			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Modules
			AzureAD							(Install-Module AzureAD)
			MSOnline						(Install-Module MSOnline)
			UcmPSTools						(Install-Module UcmPsTools) Includes Cmdlets below.

			Cmdlets
			Write-UcmLog:					https://github.com/Atreidae/UcmPSTools/blob/main/public/Write-UcmLog.ps1
			Test-UcmMSOLConnection:			https://github.com/Atreidae/UcmPSTools/blob/main/public/Test-UcmMSOLConnection.ps1
			New-UcmMSOLConnection:			https://github.com/Atreidae/UcmPSTools/blob/main/public/New-UcmMSOLConnection.ps1
			Write-UcmHTMLReport:			https://github.com/Atreidae/UcmPSTools/blob/main/public/Write-UcmHTMLReport.ps1

			.REQUIRED PERMISSIONS
			'Office365 User Admin' or better

			.LINK
			https://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPSTools

			.ACKNOWLEDGEMENTS
			Assign licenses for specific services in Office 365 using PowerShell:


	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '', Scope='Function')] #Todo, update return variable to return an array of pipeline objects, so we can report the status of each one to the calling function

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1,HelpMessage='The UPN of the user you wish to revoke the licence from, eg: button.mash@contoso.com')] [string]$UPN,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2,HelpMessage='The licence you wish to revoke, eg: MCOEV')] [string]$LicenceType
	)

	#region functionSetup, Set Default Variables for HTML Reporting and Write Log
	$Function = 'Revoke-UcmOffice365UserLicence'
	[hashtable]$Return = @{}
	$return.function = $Function
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

	#endregion functionSetup

	#region functionWork

	#Check to see if we are connected to MSOL
	$Test = (Test-UcmMSOLConnection -Reconnect)
	If ($Test.Status -ne "OK")
	{
		#MSOL check failed, return an error.
		Write-UcmLog -Message "Something went wrong granting $UPN's licence" -Severity 3 -Component $function
		Write-UcmLog -Message "Test-UcmMSOLConnection could not locate an MSOL connection" -Severity 2 -Component $function
		$Return.Status = "Error"
		$Return.Message = "No MSOL Connection"
		Return $Return
	}

	#Get the details of exisiting licences to build licence names
	Write-UcmLog -Message "Building Licence Prefix" -Severity 2 -Component $function
	Try
	{
		#Office365 does this thing where it preprends the tenant name on the licence
		#For example PHONESYSTEM_VIRTUALUSER would be "contoso:PHONESYSTEM_VIRTUALUSER"
		#So we need to learn the prefix, we do this by looking for the licence and storing it
		$O365AcctSku = $null
		$O365AcctSku = Get-MsolAccountSku | Where-Object {$_.SkuPartNumber -like $LicenceType}

		#Using the stored details, build the full licence name
		$LicenceToRevoke = "$($O365AcctSku.AccountName):$LicenceType"
	}

	Catch
	{
		#We couldnt get the licence details, it could be a permissions issue or the connection might be broken. Return an error.
		Write-UcmLog -Message "Error Running Get-MsolAccountSku" -Severity 3 -Component $function
		Write-UcmLog -Message $error[0]  -Severity 3 -Component $function
		$Return.Status = "Error"
		$Return.Message = "Unable to run Get-MsolAccountSku to obtain tenant prefix"
		Return $Return
	}

	If ($null -eq $O365AcctSku)
	{
		#The licence requested doesnt exist on the tenant, return an error
		Write-UcmLog -Message "Unable to locate Licence on Tenant" -Severity 3 -Component $function
		$Return.Status = "Error"
		$Return.Message = "Unable to locate $LicenceType Licence"
		Return $Return
	}

	#We have built the licence details, check to see if the specified user exists.
	Try
	{
		Write-UcmLog -Message "Checking for Existing User $UPN ..." -Severity 2 -Component $function
		$O365User = (Get-MsolUser -UserPrincipalName $UPN -ErrorAction Stop)
		Write-UcmLog -Message "User Exists. checking licences..." -Severity 2 -Component $function

		#Found the user, check to see if they have the licence.
		If ($O365User.Licenses.accountSkuID -Notcontains $LicenceToRevoke)
		{
			#Looks like the user doesnt have that licence, skip and return a warning.
			Write-UcmLog -Message "User doesnt have that licence, Skipping" -Severity 3 -Component $function
			$Return.Status = "Warning"
			$Return.Message = "Skipped: Not Licenced"
			Return $Return
		}

		#User has the licence, try revoking licence from the user
		Try
		{
			Write-UcmLog -Message "User has licence, Revoke Licence" -Severity 2 -Component $function
			#Try Removing the licence
			[Void] (Set-MsolUserLicense -UserPrincipalName $UPN -RemoveLicenses $LicenceToRevoke -ErrorAction stop)
			Write-UcmLog -Message "Licence Revoked" -Severity 2 -Component $function

			#Everything went well, return OK
			$Return.Status = "OK"
			$Return.Message = "Licence Revoked"
			Return $Return
		}
		#Something went wrong removing the licence.
		Catch
		{
			#Return an error
			Write-UcmLog -Message "Something went wrong removing the licence from user $UPN" -Severity 3 -Component $function
			Write-UcmLog -Message $Error[0] -Severity 3 -Component $function
			$Return.Status = "Error"
			$Return.Message = $Error[0]
			Return $Return
		}
	} #End User Check try block #Todo, split this up into seperate blocks to minimise nesting.

	#User doesnt exist, return an error message
	Catch
	{
		#Return an error
		Write-UcmLog -Message "Something went wrong revoking $UPN's licence" -Severity 3 -Component $function
		Write-UcmLog -Message "Could not locate user $UPN" -Severity 2 -Component $function
		$Return.Status = "Error"
		$Return.Message = "User Not Found"
		Return $Return
	}
	#endregion FunctionWork


	#region functionReturn

	#Default Return Variable for my HTML Reporting Fucntion
	Write-UcmLog -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
	$return.Status = "Unknown"
	$return.Message = "Write-UcmLog did not encounter return statement"
	Return $Return
	#endregion functionReturn
}
