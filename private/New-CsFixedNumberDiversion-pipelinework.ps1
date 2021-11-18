#PerformScriptSigning
Function New-UcmCsFixedNumberDiversion
{
    <#
			.SYNOPSIS
			Diverts a number associated with Microsoft Teams Via Microsoft Calling plans or Telstra Calling to an external PSTN number

			.DESCRIPTION
			Diverts a number associated with Microsoft Teams Via Microsoft Calling plans or Telstra Calling to an external PSTN number by performing the following actions
			- Creates a Resource Account with named "PSTN_FWD_<inboundNumber>@domain.onmicrosoft.com" by default (Configurable using -AccountPrefix)
			- Licences the account with a Virtual Phone System Licence
			- Licences the account with an appropriate calling licence (Will attempt to locate a calling licence using Locate-CsCallingLicence)
			- Creates an AutoAttendant with a 24 hour schedule
			- Configures a forward rule in the AutoAttendant

			Note: All accounts will be "Cloud born" and use your tenants onmicrosoft domain as syncing accounts is a PITA
			Warning: The script presently only supports Cloud Numbers, attempting to use Direct Routing numbers will fail.
			

			.EXAMPLE
			PS> New-CsFixedNumberDiversion -OriginalNumber +61370105550 -TargetNumber +61755501234
			Enables Microsoft Teams for the user Button Mash 

			PS> New-CsFixedNumberDiversion -UPN 'button.mash@contoso.com' -ServiceName 'MCOPSTNEAU'
			Enables Telstra Calling (Australian version of Microsoft Calling) for the user Button Mash

			.PARAMETER OriginalNumber
			The number of the new AutoAttendant. IE: The number to wish to forward FROM

			.PARAMETER TargetNumber
			The number the AutoAttendant will forward calls to. IE: the number to wish to forward TO

			.PARAMETER AccountPrefix
			This is the name that will be placed before the inbound phone number in the account name, used if you have a special naming convention for service accounts
			"PSTN_FWD_" by default

			.PARAMETER Domain
			This is the domain name that will be used to create the resource accounts for the diversion. This should be an "onmicrosoft" domain to minimise any directory sync issues
			For example "Contoso.onmicrosoft.com"

			.PARAMETER LicenceType
			How will we licence the AutoAttendant to make PSTN calls, Valid options are, MCOPSTN1, MCOPSTN2, MCOPSTNEAU2
			Note, we presently dont support direct routing. I'll get there.
			
			.PARAMETER Country
			As we are setting licence's for the virtual users, we need to know what country to licence them in. 
			Make sure to use upper case!

			.PARAMETER AADisplayName
			The name to assign to the AutoAttendant "<Original Number> Forward" by default

			.INPUTS
			This function accepts both parameter and pipline input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple Keys to indicate status
			$Return.Status 
			$Return.Message 
			
			Return.Status can return one of three values
			"OK"      : The Auto Attendent was created
			"Error"   : Something went wrong creating the AA, check the output for more information.
			"Unknown" : Cmdlet reached the end of the function without returning anything, this shouldnt happen, if it does please log an issue on Github
			
			Return.Message returns descriptive text based on the outcome, mainly for logging or reporting

			.NOTES
			Version:		1.0
			Date:			27/09/2021

			.VERSION HISTORY

			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Modules
			AzureAD								(Install-Module AzureAD)
			MSOnline							(Install-Module MSOnline)
			UcmPSTools							(Install-Module UcmPsTools) Includes Cmdlets below.

			Cmdlets
			Write-UcmLog: 						https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-UcmLog.ps1
			Write-HTMLReport: 					https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-HTMLReport.ps1 (optional)
			New-UcmTeamsResourceAccount
			New-UcmOffice365User
			Grant-UcmOffice365UserLicence
			Test-UcmO365ServicePlan

			.REQUIRED PERMISSIONS
			'Office365 User Admin' and 'Teams Admin' or better

			.LINK
			https://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPSTools

			.ACKNOWLEDGEMENTS
			Stack Overflow, disabling services: https://stackoverflow.com/questions/50492591/how-can-i-disable-and-enable-office-365-apps-for-all-users-at-once-using-powersh
			Alex Verboon, Powershell script to remove Office 365 Service Plans from a User: https://www.verboon.info/2015/12/powershell-script-to-remove-office-365-service-plans-from-a-user/
	#>
Param
(
	[Parameter(ValueFromPipelineByPropertyName=$true, mandatory=$true, Position=1)] [string]$OriginalNumber, 
	[Parameter(ValueFromPipelineByPropertyName=$true, mandatory=$true, Position=2)] [string]$TargetNumber, 
	[Parameter(ValueFromPipelineByPropertyName=$true, Position=3)] [string]$AccountPrefix="PSTN_FWD_",
	[Parameter(ValueFromPipelineByPropertyName=$true, mandatory=$true, Position=4)] [string]$Domain,
	[Parameter(ValueFromPipelineByPropertyName=$true, mandatory=$true, Position=5)] [string]$LicenceType,
	[Parameter(ValueFromPipelineByPropertyName=$true, mandatory=$true, Position=6)] [string]$Country,
	[Parameter(ValueFromPipelineByPropertyName=$true, Position=7)] [string]$AADisplayName
)


BEGIN
{
	$ScriptVersion = 1.0
	$StartTime = Get-Date
	$Script:LogFileLocation = $PSCommandPath -replace '.ps1','.log' #Needing to actually figure out a better way of doing this for the module TODO

	Write-UcmLog -Message "$ScriptVersion script started at $StartTime" -Severity 1 -Component $Function
	Write-UcmLog -Message "Perfoming connection checks" -Severity 2 -Component $Function

	#Check to see if we are connected to SFBO
	$Test = (Test-SFBOConnection -reconnect)
	If ($Test.Status -eq "Error")
	{
	Write-UcmLog -Message "Couldnt configure diversions." -Severity 3 -Component $function
	Write-UcmLog -Message "Test-SFBOConnection could not locate an SFBO connection" -Severity 2 -Component $function
	$Return.Status = "Error"
	$Return.Message = "No SFBO Connection ( $($test.message) )"
	Return $Return
	}

	#Check to see if we are connected to MSOL
	$Test = (Test-MSOLConnection -reconnect)
	If ($Test.Status -eq "Error")
	{
	Write-UcmLog -Message "Couldnt configure diversions." -Severity 3 -Component $function
	Write-UcmLog -Message "Test-MSOLConnection could not locate an MSOL connection" -Severity 2 -Component $function
	$Return.Status = "Error"
	$Return.Message = "No MSOL Connection ( $($test.message) )"
	Return $Return
	}

	#Create an object to store all our pipeline objects
	$Objects= @()
}


PROCESS
{
	#Check to see if we got something on the pipeline, if we did. process it


	if ($OriginalNumber)
	{
		#Store the object for processing
		Write-UcmLog -Message "Storing object for $OriginalNumber" -Severity 1 -Component $Function
		$Objects += $_
	}
	Else
	{
		Write-UcmLog -Message "Couldnt configure diversions." -Severity 3 -Component $function
		Write-UcmLog -Message "No objects to process" -Severity 2 -Component $function
		$Return.Status = "Error"
		$Return.Message = "Pipeline Empty"
		Return $Return
	}
	#endregion FunctionWork
}


END {
	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	Foreach ($Diversion in $objects)
	{
		$Diversion
		Pause
	}

	#Actually do the work!

	#Resource Accounts
	Foreach ($Diversion in $objects)
	{	
		Write-UcmLog -Message "Creating Resource Account for $($Diversion.originalNumber)" -Severity 2 -Component $Function
		#if ($Diversion.AADisplayName = $Null) {$Diversion.AADisplayName = ($Diversion.OriginalNumber + " Forward")}
		$Diversion.AADisplayName
		$Diversion.AADisplayName = ($OriginalNumber + " Forward")  #todo fix the damn naming problem
		Write-UcmLog -Message "Displayname $($Diversion.AADisplayName)" -Severity 2 -Component $Function
		#Create the resource account
		$UPN = ($Diversion.AccountPrefix + $Diversion.originalNumber + "@" + $Diversion.domain)
		Write-UcmLog -Message "Creating Required Resource Account" -Severity 2 -Component $function
		$AAAccount = (New-UcmTeamsResourceAccount -upn $upn -ResourceType Autoattendant -displayname "$($Diversion.originalnumber) forward")

		#todo, better error handling
		#If ($AAAccount.status -eq "Error") {Throw "something went wrong creating the resource account"}
	}
	Write-UcmLog -Message "Resource accounts complete, wait 10 seconds for replication" -Severity 2 -Component $Function
	Start-sleep -seconds 10

	#Licences
	Foreach ($Diversion in $objects)
	{	
		#calculate the UPN again
		$UPN = ($Diversion.AccountPrefix + $Diversion.originalNumber + "@" + $Diversion.domain)

		#Licence the account for Phone system
		Write-UcmLog -Message "Licencing Resource Account for $($Diversion.originalNumber)" -Severity 2 -Component $Function
		$Licence1 = (Grant-UcmOffice365UserLicence -licencetype PHONESYSTEM_VIRTUALUSER -country $Diversion.country -upn $upn)

		#Licence the account for PSTN calling
		$Licence2 = (Grant-UcmOffice365UserLicence -licencetype $licencetype -country $Diversion.country -upn $upn)
		
		#todo, better error handling
		If ($licence1.status -eq "Error" -or $Licence2.status -eq "Error") {Throw "Something went wrong assinging licences"}
	}

	Write-UcmLog -Message "Licences assigned, wait 30 seconds for replication" -Severity 2 -Component $Function
	Start-sleep -seconds 30

	#Assign the phone number to the resource account
	Foreach ($Diversion in $objects)
	{	
		#calculate the UPN again
		$UPN = ($Diversion.AccountPrefix + $Diversion.originalNumber + "@" + $Diversion.domain)

		Write-UcmLog -Message "Assigning Number to Resource Account $upn" -Severity 2 -Component $function

		$telephoneNumber = ($Diversion.$OriginalNumber).TrimStart("tel:+")
		$telephoneNumber = ($Diversion.$OriginalNumber).TrimStart("+")

		#Set-CsOnlineApplicationInstance -Identity $AAUPN -OnpremPhoneNumber $telephoneNumber   ## Direct Routing version!
		Set-CsOnlineVoiceApplicationInstance -Identity $UPN -TelephoneNumber $telephoneNumber

	}

	#Build the AutoAttendant
	Foreach ($Diversion in $objects)
	{	
		#calculate the UPN AGAIN....
		$UPN = ($Diversion.AccountPrefix + $Diversion.originalNumber + "@" + $Diversion.domain)

		Write-UcmLog -Message "Creating Autoattendant for $upn" -Severity 2 -Component $Function

		#Create a callable destination
		Write-UcmLog -Message "New-CsAutoAttendantCallableEntity" -Severity 1 -Component $function
		$CallForwardEntity = New-CsAutoAttendantCallableEntity -Identity "tel:+$($Diversion.TargetNumber)" -Type ExternalPSTN

		#Make a "Menu option" that sends the call to the target
		Write-UcmLog -Message "New-CsAutoAttendantMenuOption" -Severity 1 -Component $function
		$DiversionMenuOption = New-CsAutoAttendantMenuOption -Action TransferCallToTarget -DtmfResponse Automatic -CallTarget $CallForwardEntity
		
		#Make a "Menu" that contains the object
		Write-UcmLog -Message "New-CsAutoAttendantMenu" -Severity 1 -Component $function
		$DiversionMenu = New-CsAutoAttendantMenu -Name "Fixed Diversion" -MenuOptions @($DiversionMenuOption)

		#Make a "Call Flow" that contains the Menu
		Write-UcmLog -Message "New-CsAutoAttendantCallFlow" -Severity 1 -Component $function
		$DiversionCallFlow = New-CsAutoAttendantCallFlow -Name "Fixed Diversion" -Menu $DiversionMenu
		
		#Make the Autoattendant that contains the menu and defaults to the diversion call flow
		Write-UcmLog -Message "New-CsAutoAttendant" -Severity 1 -Component $function
		$o=New-CsAutoAttendant -Name $AADisplayName -DefaultCallFlow $DiversionCallFlow -CallHandlingAssociations @($afterHoursCallHandlingAssociation) -Language "en-AU" -TimeZoneId "AUS Eastern Standard Time" 

		#Find the resource account GUID
		Write-UcmLog -Message "App instance lookup" -Severity 1 -Component $function
		$applicationInstanceId = (Get-CsOnlineUser $UPN).ObjectId 

		#Associate the AutoAttendant with the resource account
		Write-UcmLog -Message "New-CsOnlineApplicationInstanceAssociation" -Severity 2 -Component $function
		New-CsOnlineApplicationInstanceAssociation -Identities @($applicationInstanceId) -ConfigurationId $O.identity -ConfigurationType AutoAttendant

		#Write-UcmLog -Message "Get-csAutoAttendant" -Severity 1 -Component $function
		#Get-csAutoAttendant -Identity $o.identity
	}
	Write-UcmLog -Message "AutoAttendants complete" -Severity 2 -Component $Function

	
	# Log why we were called
	Write-UcmLog -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-UcmLog -Message "Parameters" -Severity 3 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$Args" -Severity 1 -Component $function -LogOnly
	
	#endregion FunctionSetup
	
	Write-UcmLog -Message "Executing process block with Attendant $DisplayName" -Severity 1 -Component $Function

}

}#end function