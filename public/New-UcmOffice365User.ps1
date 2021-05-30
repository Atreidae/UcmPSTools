#PerformScriptSigning
Function New-UcmOffice365User
{
	<#
			.SYNOPSIS
			Checks for and creates a new blank Office 365 user

			.DESCRIPTION
			Checks for and creates a new blank Office 365 user
			Handy for some situations where you need to create a user account for things that cant be sorted by a resource account.

			.EXAMPLE
			New-Office365User -UPN button.mash@contoso.com -Password "Passw0rd1!" -FirstName Caleb -LastName Sills -Country AU -DisplayName "Button Mash"

			.PARAMETER UPN
			The UPN of the user you wish to create, eg: "button.mash@contoso.com"

			.PARAMETER Password
			The Password for the user you wish to create, eg: "%%32/young/PRESS/road/86%%"

			.PARAMETER FirstName
			The first name of the user you wish to create eg: "Button"

			.PARAMETER LastName
			The first name of the user you wish to create eg: "Mash"

			.PARAMETER DisplayName
			The Display Name of the user you wish to create, eg: "Button Mash"

			.INPUTS
			This function accepts both parameter and pipline input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple keys to indicate status
			$Return.Status 
			$Return.Message 

			Return.Status can return one of four values
			"OK"      : Created User
			"Warning" : User already exists, creation was skipped
			"Error"   : Something happend when attempting to create the user, check $return.message for more information
			"Unknown" : Cmdlet reached the end of the function without returning anything, this shouldnt happen, if it does please log an issue on Github
			
			Return.Message returns descriptive text showing the connected tenant, mainly for logging or reporting

			.LINK
			https://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPSTools

			.ACKNOWLEDGEMENTS

			.NOTES
			Version:		1.1
			Date:			03/04/2021

			.VERSION HISTORY
			1.1: Updated to "Ucm" naming convention
			Better inline documentation
			Optmized Try, Catch blocks to neaten code
					
			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Modules
			AzureAD								(Install-Module AzureAD)
			MSOnline							(Install-Module MSOnline)
			UcmPSTools							(Install-Module UcmPsTools) Includes Cmdlets below.

			Cmdlets
			Write-UcmLog: 						https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-UcmLog.ps1
			Test-UcmMSOLConnection				https://github.com/Atreidae/UcmPsTools/blob/main/public/Test-UcmMSOLConnection.ps1
			New-UcmMSOLConnection				https://github.com/Atreidae/UcmPsTools/blob/main/public/New-UcmMSOLConnection.ps1

			.REQUIRED PERMISIONS
			'Office 365 User Administrator' or better

	#>

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1,HelpMessage='The UPN of the user you wish to create, eg: button.mash@contoso.com')] [string]$UPN, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2,HelpMessage='The Password for the user you wish to create, eg: %%32/young/PRESS/road/86%%')] [string]$Password,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=3,HelpMessage='The first name of the user you wish to create eg: Button')] [string]$FirstName,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=4,HelpMessage='The last name of the user you wish to create eg: Mash')] [string]$LastName,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=6,HelpMessage='The display name of the user you wish to create eg: Button Mash')] [string]$DisplayName,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=5,HelpMessage='The 2 letter country code for the users country, must be in capitals. eg: AU')] [String]$Country #TODO Add country validation.
	)


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'New-UcmOffice365User'
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

	#Check to see if we are connected to MSOL
	$Test = (Test-UcmMSOLConnection) #Todo need to update to support auto reconnect
	If ($Test.Status -ne "OK")
	{
		Write-UcmLog -Message "Something went wrong creating user $UPN" -Severity 3 -Component $function
		Write-UcmLog -Message "Test-UcmMSOLConnection could not locate an MSOL connection" -Severity 2 -Component $function
		$Return.Status = "Error"
		$Return.Message = "No MSOL Connection"
		Return $Return
	}

	#Check to see if the user already exists
	Try
	{
		Write-UcmLog -Message "Checking for Existing User $UPN ..." -Severity 2 -Component $function
		[void] (Get-MsolUser -UserPrincipalName $UPN -ErrorAction Stop)#Returns an error if the user doesnt exist

		#User must exist, otherwise we would have hit the catch block by now. Return a warning
		Write-UcmLog -Message "User Exists, Skipping" -Severity 3 -Component $function
		$Return.Status = "Warning"
		$Return.Message = "User Already Exists"
		Return $Return
	}
	Catch
	{
		#User doesnt exist, let's make themaap)o
		Write-UcmLog -Message "Existing user Not Found. Creating user $UPN" -Severity 2 -Component $function
	}

#Removed from catch block above to neaten code
	Try
	{
		[Void] (New-MsolUser -UserPrincipalName $UPN -DisplayName $DisplayName -FirstName $Firstname -LastName $LastName -UsageLocation $Country -Password $Password -ErrorAction Stop)
		
		#User was created, return OK
		Write-UcmLog -Message "User Created Sucessfully" -Severity 2 -Component $function
		$Return.Status = "OK"
		$Return.Message = "User Created"
		Return $Return
	}
	Catch
	{
		#Something went wrong creating the user, return an error
		Write-UcmLog -Message "Something went wrong creating user $UPN" -Severity 3 -Component $function
		Write-UcmLog -Message $Error[0] -Severity 3 -Component $Function
		$Return.Status = "Error"
		$Return.Message = $Error[0]
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