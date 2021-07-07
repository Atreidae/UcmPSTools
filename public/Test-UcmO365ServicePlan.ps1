#PerformScriptSigning
Function Test-UcmO365ServicePlan
{
	<#
			.SYNOPSIS
			Checks the status of a specified Service Plan in Office365

			.DESCRIPTION
			Cmdlet uses an existing Azure AD connection to filter through a users licences and check if the requested Service Plan is enabled.
			Handy for checking if an administrator has disabled Skype for Business Online before attempting to migrate them from Skype4B on prem, for example.

			.PARAMETER UPN
			The users username in UPN format

			.PARAMETER ServiceName
			Office365 Service Plan you wish to check

			.EXAMPLE
			PS> Test-UcmO365ServicePlan -UPN 'button.mash@contoso.com' -ServiceName 'MCOSTANDARD'
			Enables a user for Skype for Business Online (Required to migrate to Teams)

			.INPUTS
			User UPN - Users username in UPN format
			ServiceName - Office365 Service Plan you want to check

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple Keys to indicate status
			$Return.Status 
			$Return.Message 
			
			Return.Status can return one of four values
			"OK"      : Service Plan is Enabled
			"Warning"    : Service Plan is Disabled
			"Error"   : Service Plan in an unknown state, like PendingProvisioning 
			"Unknown" : Cmdlet reached the end of the fucntion without returning anything, this shouldnt happen, if it does please log an issue on Github
			
			Return.Message returns descriptive text based on the outcome, mainly for logging or reporting

			.NOTES
			Version:		1.1
			Date:			03/04/2021

			.VERSION HISTORY
			1.1: Updated to "Ucm" naming convention
			Better inline documentation
			Updated PowerShell Verbage from Find to Test
			
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
			'Office365 User Admin' or better

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPsTools

			.ACKNOWLEDGEMENTS

	#>

	Param 
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1,HelpMessage='The UPN of the user you wish to check the Service Plan on, eg: button.mash@contoso.com')] [string]$UPN, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2,HelpMessage="The name of the Office365 Service Plan you wish check the status of, eg: 'MCOSTANDARD' for Skype Online")] [string]$ServiceName 
	)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Test-UcmO365ServicePlan'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = 'Unknown'
	$return.Message = 'Function did not return a status message'

	# Log why we were called
	Write-UcmLog -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-UcmLog -Message 'Parameters' -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message 'Parameters Values' -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message 'Optional Arguments' -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$Args" -Severity 1 -Component $function -LogOnly
	Write-Host '' #Insert a blank line to make reading output easier on loops
	
	#endregion FunctionSetup

	#region FunctionWork

	#Check to see if we are connected to MSOL
	$Test = (Test-UcmMSOLConnection -Reconnect)
	If ($Test.Status -ne "OK")
	{
		#MSOL check failed, return an error.
		Write-UcmLog -Message "Something went wrong checking $UPN's service plans" -Severity 3 -Component $function
		Write-UcmLog -Message "Test-UcmMSOLConnection could not locate an MSOL connection" -Severity 2 -Component $function
		$Return.Status = "Error"
		$Return.Message = "No MSOL Connection"
		Return $Return
	}

	#Set a flag to see if the licence is enabled
	$Enabled =$false

	#Get the users licences and enumerate through them looking for the relevant service plan
	$LicenseDetails = (Get-MsolUser -UserPrincipalName $UPN).Licenses

	ForEach ($License in $LicenseDetails)
	{
		#check the relevant service plans on this licence.
		ForEach ($ServiceStatus in $License.ServiceStatus)
		{
			#check to see if the service name matches the requested name and its status
			If ($ServiceStatus.ProvisioningStatus -eq 'Disabled' -and $_.ServicePlan.ServiceName -eq "$serviceName")
			{
				#Found the service plan, and its disabled, $Enabled is already $False, no need to set anything.
				Write-UcmLog -Message "$ServiceName Disabled" -Severity 2 -Component $function
			}
			Elseif ($ServiceStatus.ProvisioningStatus -eq 'Success' -and $_.ServicePlan.ServiceName -eq "$serviceName")
			{
				#Found the service plan, and its provisioned, Set the Enabled flag to true
				Write-UcmLog -Message "$ServiceName Enabled" -Severity 2 -Component $function
				$Enabled = $true
			}
			ElseIf ($ServiceStatus.ServicePlan.ServiceName -like "*$serviceName*")
			{
				#Found the service plan, and its not provisioned properly, this could be to a service issue or a multitude of other reasons (IE, MCOEV will error if the LineURI is already assigned). return an error
				Write-UcmLog -Message "$ServiceName is in unknown state , you may need to run '(Get-MsolUser -UserPrincipalName $UPN).Licenses' for more information" -Severity 3 -Component $function
				$Enabled = 'Error'
			}
		} #End Service Plan Status Loop
		
	}#End licence loop

	If ($enabled -eq 'Error')
	{
		#Encounted an error with Service Plan, return an error.
		Write-UcmLog -Message "$ServiceName is in unknown state" -Severity 2 -Component $function
		$Return.Status = 'ERROR'
		$Return.Message  = "$ServiceName is in unknown state, you may need to run '(Get-MsolUser -UserPrincipalName $UPN).Licenses' for more information"
		Return $Return
	}
	Elseif ($enabled -eq $true)
	{
		#The ServicePlan is enabled, return OK
		Write-UcmLog -Message "$ServiceName Enabled" -Severity 2 -Component $function
		$Return.Status = 'OK'
		$Return.Message  = "$ServiceName Enabled"
		Return $Return
	}
	ElseIf ($_.ServicePlan.ServiceName -like "*$serviceName*")
	{
		#The ServicePlan is disabled, return a warning
		Write-UcmLog -Message "$ServiceName Disabled" -Severity 2 -Component $function
		$Return.Status = 'Warning'
		$Return.Message  = "$ServiceName Disabled"
		Return $Return
	}
	#endregion FunctionWork

	#region FunctionReturn
 
	#Default Return Variable for my HTML Reporting Fucntion
	Write-UcmLog -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
	$return.Status = 'Unknown'
	$return.Message = 'Function did not encounter return statement'
	Return $Return
	#endregion FunctionReturn
}