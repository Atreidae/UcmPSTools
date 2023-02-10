#PerformScriptSigning
Function Enable-UcmO365Service
{
	<#
			.SYNOPSIS
			Enables a Specified Service Plan in Office365

			.DESCRIPTION
			Cmdlet uses an existing Azure AD connection to filter through a users licences and enable the requested service.
			Handy if an administrator has disabled Skype for Business Online for example.

			.EXAMPLE
			PS> Enable-UcmO365Service -User 'button.mash@Contoso.com' -ServiceName 'MCOSTANDARD'
			Enables Skype for Business Online for the user Button Mash

			PS> Enable-UcmO365Service -UPN 'button.mash@contoso.com' -ServiceName 'TEAMS1'
			Enables Microsoft Teams for the user Button Mash

			PS> Enable-UcmO365Service -UPN 'button.mash@contoso.com' -ServiceName 'MCOPSTNEAU'
			Enables Telstra Calling (Australian version of Microsoft Calling) for the user Button Mash

			.PARAMETER UPN
			The users username in UPN format

			.PARAMETER ServiceName
			Office365 Service Plan you wish to enable

			.INPUTS
			This function accepts both parameter and pipline input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple Keys to indicate status
			$Return.Status
			$Return.Message

			Return.Status can return one of three values
			"OK"      : The Service Plan was enabled
			"Error"   : The Service Plan was wasnt enabled, it may not have been found or there was an error setting the users attributes.
			"Unknown" : Cmdlet reached the end of the function without returning anything, this shouldnt happen, if it does please log an issue on Github

			Return.Message returns descriptive text based on the outcome, mainly for logging or reporting

			.NOTES
			Version:		1.3
			Date:			13/07/2021

			.VERSION HISTORY
			1.3: Added a check and return if the service is already enabled instead of getting caught in the catchall error
			Updated Catchall error message
			Added MSOL cmdlet error catching and return
			Added a check to see if the Service Plan existss for that user
			Added a check to see if the user is licenced at all

			1.2: Fixed issue with random "-Message" messages being written to the pipeline
			Added check to only attempt to write the service changes if we actually changed something
			Added more infomative error messages when the cmdet fails to set a service

			1.1: Updated to "Ucm" naming convention
			Better inline documentation

			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Modules
			AzureAD								(Install-Module AzureAD)
			MSOnline							(Install-Module MSOnline)
			UcmPSTools							(Install-Module UcmPsTools) Includes Cmdlets below.

			Cmdlets
			Write-UcmLog: 						https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-UcmLog.ps1
			Write-HTMLReport: 					https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-HTMLReport.ps1 (optional)

			.REQUIRED PERMISSIONS
			'Office365 User Admin' or better

			.LINK
			https://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPSTools

			.ACKNOWLEDGEMENTS
			Stack Overflow, disabling services: https://stackoverflow.com/questions/50492591/how-can-i-disable-and-enable-office-365-apps-for-all-users-at-once-using-powersh
			Alex Verboon, Powershell script to remove Office 365 Service Plans from a User: https://www.verboon.info/2015/12/powershell-script-to-remove-office-365-service-plans-from-a-user/

	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '', Scope='Function')] #todo, https://github.com/Atreidae/UcmPSTools/issues/23
	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1,HelpMessage='The UPN of the user you wish to enable the Service Plan on, eg: button.mash@contoso.com')] [string]$UPN,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2,HelpMessage="The name of the Office365 Service Plan you wish enable, eg: 'MCOSTANDARD' for Skype Online")] [string]$ServiceName
	)


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Enable-UcmO365Service'
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


	#endregion FunctionSetup

	#region FunctionWork

	#Set a flag to track if we enabled the app or not
	$AppEnabled = $False
	#Set a flag to track if we found the app or not
	$servicePlanExists = $False

	#Check the user is even licenced in O365
	If ((Get-MsolUser -UserPrincipalName $UPN).isLicensed -ne $true)
	{
		Write-UcmLog -Message 'User does not have ANY valid O365 licence, abort' -Severity 3 -Component $function
		$Return.Status = 'Error'
		$Return.Message  = "User has no O365 licence, run 'Get-MsolUser -UserPrincipalName $Upn' for more info"
		Return $Return
	}


	#Get the user Licence details
	$LicenseDetails = (Get-MsolUser -UserPrincipalName $UPN).Licenses

	#Run through all the servicesplans on each licence, one licence at a time.
	ForEach ($License in $LicenseDetails) {
		Write-UcmLog -Message "Checking $($License.AccountSkuId) for $Servicename" -Severity 1 -Component $function

		#Find all the Disabled services and add them to an array, except for the requsted service. We need them for later
		$DisabledOptions = @()
		ForEach ($Service in $License.ServiceStatus)
		{
			#Check this service plan
			Write-UcmLog -Message "Checking $($Service.ServicePlan.ServiceName)" -Severity 1 -Component $function

			#check if we this is the plan and its already enabled
			If ($Service.ServicePlan.ServiceName -eq $ServiceName)
			{
			Write-UcmLog -Message "Found requested Serviceplan" -Severity 1 -Component $function
			$servicePlanExists = $True
			If ($Service.ProvisioningStatus -eq 'Success')
				{
				Write-UcmLog -Message "Service Plan is already enabled, returning" -Severity 1 -Component $function
				$Return.Status = 'OK'
				$Return.Message  = 'Already Enabled'
				Return $Return
				}
			}
			#Else check if the ServicePlan is disabled so we can track it (and enable it if needed)
			If ($Service.ProvisioningStatus -eq 'Disabled')
			{
				#The Service Is disabled, check to see if its the requested service
				Write-UcmLog -Message "Service Plan is currently Disabled" -Severity 1 -Component $function
				If ($Service.ServicePlan.ServiceName -eq $ServiceName)
				{
					Write-UcmLog -Message "$Servicename Was disabled, Enabling" -Severity 2 -Component $function
					$AppEnabled = $true
				}
				#Not the requested service, add it to the array
				Else
				{
					Write-UcmLog -Message "$($Service.ServicePlan.ServiceName) is disabled, adding to Disabled Options" -Severity 1 -Component $function
					$DisabledOptions += "$($Service.ServicePlan.ServiceName)"
				}
			}
			Else #$Service.ProvisioningStatus check
			{
				Write-UcmLog -Message "Service Plan is currently Enabled" -Severity 1 -Component $function
			}
		}
		#Did we change any services? if so. Set the licence options using the new list of disabled licences
		If ($AppEnabled -eq $true)
		{
			Try {
				Write-UcmLog -Message 'Setting Licence Options with the following Disabled Services' -Severity 1 -Component $function
				Write-UcmLog -Message "$DisabledOptions" -Severity 1 -Component $function

				#If there are zero options in the disabled list, dont use the -DisabledPlans flag.
				If ($DisabledOptions.count -eq 0)
				{
					$LicenseOptions = New-MsolLicenseOptions -AccountSkuId $License.AccountSkuId
				}
				Else
				{
					$LicenseOptions = New-MsolLicenseOptions -AccountSkuId $License.AccountSkuId -DisabledPlans $DisabledOptions
				}

				#Using the License Options attributes, set the users licence.
				Set-MsolUserLicense -UserPrincipalName $UPN -LicenseOptions $LicenseOptions

				#Reset the AppEnabled Flag
				$AppEnabled = $False

				#Set a flag so we can see it was changed
				$MadeChanges= $True


			}
			Catch #Something went wrong setting user licence
			{
				Write-UcmLog -Message 'Something went wrong assinging the licence' -Severity 3 -Component $function
				$AppEnabled = $false
				$MadeChanges= $False
				$Return.Status = 'Error'
				$Return.Message  = 'Error running New-MsolLicenseOptions or Set-MsolUserLicense'
				Return $Return
			}
		}
		#Otherwise we didnt change anything, no need to rewrite the licence
	} #Repeat for the next Licence

		#Does the service plan even exist? Abort if not
		If ($servicePlanExists -ne $true)
		{
		Write-UcmLog -Message "Could not locate $Servicename on user $UPN, make sure the appropriate licence is assigned" -Severity 3 -Component $function
		$Return.Status = 'Error'
		$Return.Message  = "Unable to locate $ServiceName"
		Return $Return
		}



	#Report on success/failure based on the $AppEnabled flag
	If ($MadeChanges){
		$Return.Status = 'OK'
		$Return.Message  = 'Enabled'
		Return $Return
	}
	Else{
		Write-UcmLog -Message "No Services were enabled, Either the service is provisioning, has an error, or it is not available with the current assigned licences" -Severity 3 -Component $function
		$Return.Status = 'Error'
		$Return.Message  = 'Service exists, but returned unknown state'
		Return $Return
	}
	#endregion FunctionWork

	#region FunctionReturn

	#Default Return Variable for UcmPsTools HTML Reporting Fucntion
	Write-UcmLog -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
	$return.Status = 'Unknown'
	$return.Message = 'Function did not encounter return statement'
	Return $Return
	#endregion FunctionReturn
}
