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
			- Licences the account with an appropriate calling licence specified using -LicenceType
			- Creates an AutoAttendant with a 24 hour schedule
			- Configures a forward rule in the AutoAttendant

			Note: All accounts will be "Cloud born" and use your tenants onmicrosoft domain as syncing accounts is a PITA
			Warning: The script presently only supports Cloud Numbers, attempting to use Direct Routing numbers will fail.

			.EXAMPLE
			PS> New-UcmCsFixedNumberDiversion -OriginalNumber +61370105550 -TargetNumber +61755501234 -Domain Contoso.onmicrosoft.com -Country-AU -LicenceType MCOPSTNEAU2
			Forwards the number 61370105550 to 61755501234

			.PARAMETER OriginalNumber
			The number of the new AutoAttendant. IE: The number to wish to forward FROM

			.PARAMETER TargetNumber
			The number the AutoAttendant will forward calls to. IE: the number to wish to forward TO

			.PARAMETER Domain
			This is the domain name that will be used to create the resource accounts for the diversion. This should be an "onmicrosoft" domain or fully AzureAD domain to minimise any directory sync issues
			For example "Contoso.onmicrosoft.com"

			.PARAMETER LicenceType
			How will we licence the AutoAttendant to make PSTN calls, Valid options are, MCOPSTN1, MCOPSTN2, MCOPSTNEAU2
			Note, we presently dont support direct routing. I'll get there.

			.PARAMETER Country
			As we are setting licence's for the virtual users, we need to know what country to licence them in.
			Make sure to use upper case!

			.PARAMETER AccountPrefix (optional)
			This is the name that will be placed before the inbound phone number in the account name, used if you have a special naming convention for service accounts
			"PSTN_FWD_" by default


			.PARAMETER AADisplayName (optional)
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
			Version:		1.2
			Date:			23/03/2023

			.VERSION HISTORY

			1.2 Updates for UcmPsTools public module
				Added Country Validation

			1.1: Documentation changes

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
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function')] #Todo https://github.com/Atreidae/UcmPSTools/issues/27

Param
(
	[Parameter(ValueFromPipelineByPropertyName=$true, mandatory=$true, Position=1)] [string]$OriginalNumber,
	[Parameter(ValueFromPipelineByPropertyName=$true, mandatory=$true, Position=2)] [string]$TargetNumber,
	[Parameter(ValueFromPipelineByPropertyName=$true, Position=3)] [string]$AccountPrefix="PSTN_FWD_",
	[Parameter(ValueFromPipelineByPropertyName=$true, mandatory=$true, Position=4)] [string]$Domain,
	[Parameter(ValueFromPipelineByPropertyName=$true, mandatory=$true, Position=5)] [string]$LicenceType,
	[Parameter(ValueFromPipelineByPropertyName=$true, mandatory=$true, Position=6, HelpMessage='The 2 letter country code for the users country, must be in capitals. eg: AU')] [ValidateSet("AF","AX","AL","DZ","AS","AD","AO","AI","AQ","AG","AR","AM","AW","AU","AT","AZ","BS","BH","BD","BB","BY","BE","BZ","BJ","BM","BT","BO","BQ","BA","BW","BV","BR","IO","BN","BG","BF","BI","CV","KH","CM","CA","KY","CF","TD","CL","CN","CX","CC","CO","KM","CG","CD","CK","CR","CI","HR","CU","CW","CY","CZ","DK","DJ","DM","DO","EC","EG","SV","GQ","ER","EE","SZ","ET","FK","FO","FJ","FI","FR","GF","PF","TF","GA","GM","GE","DE","GH","GI","GR","GL","GD","GP","GU","GT","GG","GN","GW","GY","HT","HM","VA","HN","HK","HU","IS","IN","ID","IR","IQ","IE","IM","IL","IT","JM","JP","JE","JO","KZ","KE","KI","KP","KR","KW","KG","LA","LV","LB","LS","LR","LY","LI","LT","LU","MO","MG","MW","MY","MV","ML","MT","MH","MQ","MR","MU","YT","MX","FM","MD","MC","MN","ME","MS","MA","MZ","MM","NA","NR","NP","NL","NC","NZ","NI","NE","NG","NU","NF","MK","MP","NO","OM","PK","PW","PS","PA","PG","PY","PE","PH","PN","PL","PT","PR","QA","RE","RO","RU","RW","BL","SH","KN","LC","MF","PM","VC","WS","SM","ST","SA","SN","RS","SC","SL","SG","SX","SK","SI","SB","SO","ZA","GS","SS","ES","LK","SD","SR","SJ","SE","CH","SY","TW","TJ","TZ","TH","TL","TG","TK","TO","TT","TN","TR","TM","TC","TV","UG","UA","AE","GB","US","UM","UY","UZ","VU","VE","VN","VG","VI","WF","EH","YE","ZM","ZW")][String]$Country,
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
	$Test = (Test-UcmMSOLConnection -reconnect)
	If ($Test.Status -eq "Error")
	{
	Write-UcmLog -Message "Couldnt configure diversions." -Severity 3 -Component $function
	Write-UcmLog -Message "Test-UcmMSOLConnection could not locate an MSOL connection" -Severity 2 -Component $function
	$Return.Status = "Error"
	$Return.Message = "No MSOL Connection ( $($test.message) )"
	Return $Return
	}
}


PROCESS
{
	#Check to see if we got something on the pipeline, if we did. process it

	if ($OriginalNumber)
	{
		Write-UcmLog -Message "Executing process block with Diversion for $originalNumber" -Severity 2 -Component $Function
		if ($null -eq $AADisplayName) {$AADisplayName = ($OriginalNumber + " Forward")}

		$AADisplayName = ($OriginalNumber + " Forward")  #todo fix the damn naming problem
		Write-UcmLog -Message "Displayname $AADisplayName" -Severity 2 -Component $Function
		#Create the resource account
		$UPN = ($AccountPrefix + $OriginalNumber + "@" + $domain)



		#Check for Resource Account
		#Powershell throws an error if the account isnt found, so lets trap it and use that instead

		Try
		{
			$AAAccount = (get-csonlineapplicationinstance -Identities $upn)
			Write-UcmLog -Message "Found Existing Resource Account, skipping creation" -Severity 2 -Component $function
			Write-UcmLog -Message $AAAccount -Severity 2 -Component $function
		}

		Catch
		{
			Write-UcmLog -Message "Creating Required Resource Account" -Severity 2 -Component $function
			$AAAccount = (New-UcmTeamsResourceAccount -upn $upn -ResourceType Autoattendant -displayname "$originalnumber forward")
			Write-UcmLog -Message "waiting for account to appear" -Severity 2 -Component $function
			#Dodgy hack
			Start-sleep -seconds 20
		}

		#todo, better error handling
		#If ($AAAccount.status -eq "Error") {Throw "something went wrong creating the resource account"}

		#Licence the account for Phone system
		$Licence1 = (Grant-UcmOffice365UserLicence -licencetype PHONESYSTEM_VIRTUALUSER -country $country -upn $upn)

		#Licence the account for PSTN calling
		$Licence2 = (Grant-UcmOffice365UserLicence -licencetype $licencetype -country $country -upn $upn)

		#todo, better error handling
		If ($licence1.status -eq "Error" -or $Licence2.status -eq "Error") {Throw "Something went wrong assinging licences"}


		#Pull the user and make it a callable object

		#$operatorObjectId = (Get-CsOnlineUser $UPN).ObjectId
		#$operatorEntity = New-CsAutoAttendantCallableEntity -Identity $operatorObjectId -Type User

		#check to see if the Autoattendant already exists
		Write-UcmLog -Message "Checking for Existing Autoattendant" -Severity 2 -Component $function
		$o=$null
		$o=(Get-CsAutoAttendant -NameFilter $AADisplayName)

		If ($o -eq $BeNullOrEmpty)
		{
			Write-UcmLog -Message "New-CsAutoAttendantCallableEntity" -Severity 1 -Component $function
			$CallForwardEntity = New-CsAutoAttendantCallableEntity -Identity "tel:+$TargetNumber" -Type ExternalPSTN

			Write-UcmLog -Message "New-CsAutoAttendantMenuOption" -Severity 1 -Component $function
			$DiversionMenuOption = New-CsAutoAttendantMenuOption -Action TransferCallToTarget -DtmfResponse Automatic -CallTarget $CallForwardEntity

			Write-UcmLog -Message "New-CsAutoAttendantMenu" -Severity 1 -Component $function
			$DiversionMenu = New-CsAutoAttendantMenu -Name "Fixed Diversion" -MenuOptions @($DiversionMenuOption)

			Write-UcmLog -Message "New-CsAutoAttendantCallFlow" -Severity 1 -Component $function
			$DiversionCallFlow = New-CsAutoAttendantCallFlow -Name "Fixed Diversion" -Menu $DiversionMenu

			Write-UcmLog -Message "New-CsAutoAttendant" -Severity 1 -Component $function
			$o=New-CsAutoAttendant -Name $AADisplayName -DefaultCallFlow $DiversionCallFlow -CallHandlingAssociations @($afterHoursCallHandlingAssociation) -Language "en-AU" -TimeZoneId "AUS Eastern Standard Time"

			Write-UcmLog -Message "App instance lookup" -Severity 1 -Component $function
			$applicationInstanceId = (Get-CsOnlineUser $UPN).ObjectId

			Write-UcmLog -Message "New-CsOnlineApplicationInstanceAssociation" -Severity 2 -Component $function
			New-CsOnlineApplicationInstanceAssociation -Identities @($applicationInstanceId) -ConfigurationId $O.identity -ConfigurationType AutoAttendant

			Write-UcmLog -Message "Get-csAutoAttendant" -Severity 1 -Component $function
			Get-csAutoAttendant -Identity $o.identity
		}

		Else
		{
			Write-UcmLog -Message "Found Existing Autoattendant, Checking for Resource Account" -Severity 2 -Component $function

			if ([bool]$o.ApplicationInstances -eq $false)
			{
				Write-UcmLog -Message "Resource Account Association Missing, fixing" -Severity 3 -Component $function

				Write-UcmLog -Message "App instance lookup" -Severity 1 -Component $function
				$applicationInstanceId = (Get-CsOnlineUser $UPN).ObjectId

				Write-UcmLog -Message "New-CsOnlineApplicationInstanceAssociation" -Severity 2 -Component $function
				New-CsOnlineApplicationInstanceAssociation -Identities @($applicationInstanceId) -ConfigurationId $O.identity -ConfigurationType AutoAttendant

			}
		}

		#Assign the phone number to the resource account
		Write-UcmLog -Message "Assigning Number to Resource Account" -Severity 2 -Component $function

		$telephoneNumber = ($OriginalNumber).TrimStart("tel:+")
		$telephoneNumber = ($OriginalNumber).TrimStart("+")

		#Set-CsOnlineApplicationInstance -Identity $AAUPN -OnpremPhoneNumber $telephoneNumber   ## Direct Routing version!
		Set-CsOnlineVoiceApplicationInstance -Identity $UPN -TelephoneNumber $telephoneNumber -verbose
	}
	Else
	{
		Throw "Nothing to process"
	}
	#endregion FunctionWork
}


END
{
	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'END-Block'

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