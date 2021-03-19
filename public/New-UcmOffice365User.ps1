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

			.INPUTS
			This function accepts both parameter and pipline input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple keys to indicate status
			$Return.Status 
			$Return.Message 

			Return.Status can return one of four values
			"OK"      : Created User
			"Warn"    : User already exists, creation was skipped
			"Error"   : Something happend when attempting to create the user, check $return.message for more information
			"Unknown" : Cmdlet reached the end of the fucntion without returning anything, this shouldnt happen, if it does please log an issue on Github
			
			Return.Message returns descriptive text showing the connected tenant, mainly for logging or reporting

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Functions

			.ACKNOWLEDGEMENTS

			.NOTES
			Version:		1.1
			Date:			18/03/2021

			.VERSION HISTORY
			1.1: Updated to "Ucm" naming convention
			Better inline documentation
					
			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Write-UcmLog: https://github.com/Atreidae/PowerShell-Functions/blob/main/Write-UcmLog.ps1
			AzureAD 			(Install-Module AzureAD) 
			MSOnline			(Install-Module MSOnline) 

			.REQUIRED PERMISIONS
			'Office 365 User Administrator' or better

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
	$Script:LogFileLocation = $PSCommandPath -replace '.ps1','.log'
	$VerbosePreference = "Continue"


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
	$Test = (Test-UcmMSOLConnection)
	If ($Test.Status -ne "OK")
	{
		Write-UcmLog -Message "Something went wrong creating user $UPN" -Severity 3 -Component $function
		Write-UcmLog -Message "Test-UcmMSOLConnection could not locate an MSOL connection" -Severity 2 -Component $function
		$Return.Status = "Error"
		$Return.Message = "No MSOL Connection"
		Return $Return
	}

	#Check to see if the user already exists
	Write-UcmLog -Message "Checking for Existing User $UPN ..." -Severity 2 -Component $function
	Try
	{
		[void] (Get-MsolUser -UserPrincipalName $UPN -ErrorAction Stop)
		Write-UcmLog -Message "User Exists, Skipping" -Severity 3 -Component $function
		$Return.Status = "Warning"
		$Return.Message = "User Already Exists"
		Return $Return
	}
	Catch
	{ #User Doesnt Exist, make them
		Write-UcmLog -Message "Not Found. Creating user $UPN" -Severity 2 -Component $function
		Try 
		{
			[Void] (New-MsolUser -UserPrincipalName $UPN -DisplayName $DisplayName -FirstName $Firstname -LastName $LastName -UsageLocation $Country -Password $Password -ErrorAction Stop)
			Write-UcmLog -Message "User Created Sucessfully" -Severity 2 -Component $function
			$Return.Status = "OK"
			$Return.Message = "User Created"
			Return $Return
		}
		Catch
		{ #Something went wrong creating the user
			Write-UcmLog -Message "Something went wrong creating user $UPN" -Severity 3 -Component $function
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