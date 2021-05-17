Function Grant-UcmOffice365UserLicence
{
	<#
			.SYNOPSIS
			Assigns a licence to an Office365 user

			.DESCRIPTION
			Function will check for available licences and assign one to the supplied user
			This function will also notify you if you are below 5% of your below licences, a similar warning will be generated if you have less than 5 licences available
			For a full list of Licence codes, see https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference

			.EXAMPLE
			PS> Grant-UcmOffice365UserLicence -upn 'button.mash@contoso.com' -LicenceType 'MCOEV' -Country 'AU'
			Grants the Microsoft Phone System Licence to the user Button Mash

			PS> Grant-UcmOffice365UserLicence -upn 'button.mash@contoso.com' -LicenceType 'MCOCAP' -Country 'AU'
			Grants the Teams Common Area Phone Licence to the user Button Mash

			PS> Grant-UcmOffice365UserLicence -upn 'button.mash@contoso.com' -LicenceType 'MCOPSTN1' -Country 'AU'
			Grants the Microsoft Domestic Calling Licence to the user Button Mash

			PS> Grant-UcmOffice365UserLicence -upn 'button.mash@contoso.com' -LicenceType 'MCOPSTN2' -Country 'AU'
			Grants the Microsoft Domestic/International Calling Licence to the user Button Mash

			PS> Grant-UcmOffice365UserLicence -upn 'button.mash@contoso.com' -LicenceType 'MCOPSTNEAU2' -Country 'AU'
			Grants the TELSTRA CALLING FOR O365 Licence to the user Button Mash (Australia Only)

			PS> Grant-UcmOffice365UserLicence -upn 'button.mash@contoso.com' -LicenceType 'MEETING_ROOM' -Country 'AU'
			Grants the Teams Meeting Room Licence to the user Button Mash

			PS> Grant-UcmOffice365UserLicence -upn 'button.mash@contoso.com' -LicenceType 'MCOMEETADV' -Country 'AU'
			Grants the Teams Advanced Meeting Room Licence to the user Button Mash

			PS> Grant-UcmOffice365UserLicence -upn 'button.mash@contoso.com' -LicenceType 'ENTERPRISEPREMIUM' -Country 'AU'
			Grants the Microsoft E5 Licence to the user Button Mash

			PS> Grant-UcmOffice365UserLicence -upn 'button.mash@contoso.com' -LicenceType 'ENTERPRISEPACK' -Country 'AU'
			Grants the Microsoft E3 Licence to the user Button Mash

			.INPUTS
			This function accepts both parameter and pipline input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple Keys to indicate status
			$Return.Status 
			$Return.Message 
			
			Return.Status can return one of four values
			"OK"      : The licence has been assigned, or is already assigned to the user.
			"Warn"    : The licence was assigned, but there was an issue. for example, low availability of licences. Check $return.message for more information
			"Error"   : Unable to assign licence. check $return.message for more information
			"Unknown" : Cmdlet reached the end of the fucntion without returning anything, this shouldnt happen, if it does please log an issue on Github

			Return.Message returns descriptive text based on the outcome, mainly for logging or reporting

			.NOTES
			Version:		1.2
			Date:			15/05/2021

			.VERSION HISTORY
			1.2: Updated Examples to include more licences
			Added link to Microsoft licence documentation

			1.1: Updated to "Ucm" naming convention
			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Modules
			AzureAD										(Install-Module AzureAD)
			MSOnline									(Install-Module MSOnline)
			UcmPSTools 									(Install-Module UcmPSTools) Includes Cmdlets below.

			Cmdlets
			Write-UcmLog:								https://github.com/Atreidae/UcmPSTools/blob/main/public/Write-UcmLog.ps1
			Test-UcmMSOLConnection:						https://github.com/Atreidae/UcmPSTools/blob/main/public/Test-UcmMSOLConnection.ps1
			New-UcmMSOLConnection:						https://github.com/Atreidae/UcmPSTools/blob/main/public/New-UcmMSOLConnection.ps1
			Write-UcmHTMLReport:						https://github.com/Atreidae/UcmPSTools/blob/main/public/Write-UcmHTMLReport.ps1

			.REQUIRED PERMISSIONS
			'Office365 User Admin' or better

			.LINK
			https://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPSTools

			.ACKNOWLEDGEMENTS
			Assign licenses for specific services in Office 365 using PowerShell: 


	#>

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1,HelpMessage='The UPN of the user you wish to enable the licence on, eg: button.mash@contoso.com')] [string]$UPN, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2,HelpMessage='The licence you wish to assign, eg: MCOEV')] [string]$LicenceType,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=3,HelpMessage='The 2 letter country code for the users country, must be in capitals. eg: AU')] [String]$Country #TODO Add country validation.
	)


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$Function = 'Grant-UcmOffice365UserLicence'
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
	Write-Host '' #Insert a blank line to make reading output easier on loops
	
	#endregion functionSetup


	#region FunctionWork

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

	#MSOL Connection test passed, check the tenant has the requested licence.
	Write-UcmLog -Message "Verifying $LicenceType is available" -Severity 2 -Component $function
	Try
	{
		#Office365 does this thing where it preprends the tenant name on the licence
		#For example PHONESYSTEM_VIRTUALUSER would be "contoso:PHONESYSTEM_VIRTUALUSER"
		#So we need to learn the prefix, we do this by looking for the licence and storing its name
		$O365AcctSku = $null
		$O365AcctSku = Get-MsolAccountSku | Where-Object {$_.SkuPartNumber -like $LicenceType}
		
		#Using the stored details, build the full licence name
		$LicenceToAssign = "$($O365AcctSku.AccountName):$LicenceType"
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

	If ($O365AcctSku -eq $null)
	{
		#The licence requested doesnt exist on the tenant, return an error
		Write-UcmLog -Message "Unable to locate requested licence on the current tenant" -Severity 3 -Component $function
		$Return.Status = "Error"
		$Return.Message = "Unable to locate $LicenceType licence"
		Return $Return
	}

	#The tenant has the requested licence, check to see any are free. Trigger a warning when there is less than 5 or 5% available
	$LicenceUsedPercent = (($O365AcctSku.ConsumedUnits / $O365AcctSku.ActiveUnits) * 100)
	$AvailableLicenceCount = ($O365AcctSku.ActiveUnits - $O365AcctSku.ConsumedUnits)
	If (($LicenceUsedPercent -ge 95) -or ($AvailableLicenceCount -le 5))
	{
		Write-UcmLog -Message "Only $AvailableLicenceCount $LicenceType Licences Left" -Severity 3 -Component $function
		Write-UcmLog -Message "Available licence count low..." -Severity 3 -Component $function

		#We encountered something we need to report on, set the warning flag and store a warning message.
		$WarningFlag = $True
		$WarningMessage = "Low Licence Count"
	}

	#There are licences free, check to see if the specified user exists.
	Try
	{
		Write-UcmLog -Message "Checking for existing User $UPN ..." -Severity 2 -Component $function
		$O365User = (Get-MsolUser -UserPrincipalName $UPN -ErrorAction Stop)
		Write-UcmLog -Message "User exists. checking their assigned licences..." -Severity 2 -Component $function

		#Found the user, check to see if they already have the licence.
		If ($O365User.Licenses.accountSkuID -contains $LicenceToAssign)
		{
			#Looks like the user already has that licence
			Write-UcmLog -Message "User already has that licence, Skipping" -Severity 3 -Component $function

			#Check to see if we encountered a warning during the run and inject it into the status message
			If ($warningFlag) 
			{
				#Yes, we did, return the warning
				$Return.Status = "Warning"
				$Return.Message = "Skipped: Already Licenced, Warning Message $WarningMessage"
				Return $Return
			}
			Else
			{
				#No warning, just return OK
				$Return.Status = "OK"
				$Return.Message = "Skipped: Already Licenced"
				Return $Return
			}
		}

		#User exists, and doesnt already have the licence, try assigning the licence to them
		Try
		{
			Write-UcmLog -Message "User Exists, Grant Licence" -Severity 2 -Component $function
			
			#Set the user location, this is required to set the relevant licences. Users can be created without setting a country mistakenly.
			Write-UcmLog -Message "Setting Location" -Severity 2 -Component $function
			[void] (Set-MsolUser -UserPrincipalName $UPN -UsageLocation $Country)
			
			#Try assigning the licence to the user
			[Void] (Set-MsolUserLicense -UserPrincipalName $UPN -AddLicenses $LicenceToAssign -ErrorAction stop)
			Write-UcmLog -Message "Licence Granted" -Severity 2 -Component $function
			
			#Licence assigned OK. Check to see if we encountered a warning during the run and inject it into the status message
			If ($warningFlag)
			{
				#Yes, we did, return the warning
				$Return.Status = "Warning"
				$Return.Message = "Licence Granted, Warning Message $WarningMessage"
				Return $Return
			}
			Else
			{
				#No warning, just return OK
				$Return.Status = "OK"
				$Return.Message = "Licence Granted"
				Return $Return
			}
		}
		#Something Failed either setting the licence or the country
		Catch 
		{
			#Return an error
			Write-UcmLog -Message "Something went wrong licencing user $UPN" -Severity 3 -Component $function
			Write-UcmLog -Message $Error[0] -Severity 3 -Component $function
			$Return.Status = "Error"
			$Return.Message = $Error[0]
			Return $Return
		}
	} #End User Check try block #Todo, split this up into seperate blocks to minimise nesting.

	#User doesnt exist, throw error message
	Catch 
	{
		#Return an error
		Write-UcmLog -Message "Something went wrong granting $UPN's licence" -Severity 3 -Component $function
		Write-UcmLog -Message "Could not locate user $UPN" -Severity 2 -Component $function
		$Return.Status = "Error"
		$Return.Message = "User Not Found"
		Return $Return
	}
	#endregion FunctionWork


	#region FunctionReturn
 
	#Default Return Variable for my HTML Reporting Fucntion
	Write-UcmLog -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
	$return.Status = "Unknown"
	$return.Message = "Write-UcmLog did not encounter return statement"
	Return $Return
	#endregion Write-UcmLogReturn
}
