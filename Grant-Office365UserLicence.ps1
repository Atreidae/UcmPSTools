Function Grant-Office365UserLicence
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
			Write-Log: 				https://github.com/Atreidae/PowerShell-Functions/blob/main/Write-Log.ps1
			Test-MSOLConnection:	https://github.com/Atreidae/PowerShell-Functions/blob/main/Test-MSOLConnection.ps1
			New-MSOLConnection:	https://github.com/Atreidae/PowerShell-Functions/blob/main/New-MSOLConnection.ps1
			New-Office365User:	https://github.com/Atreidae/PowerShell-Functions/blob/main/New-Office365User.ps1
			Write-HTMLReport:		https://github.com/Atreidae/PowerShell-Functions/blob/main/Write-HTMLReport.ps1
			AzureAD					(Install-Module AzureAD) 
			Connect-MsolService

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Functions

			.ACKNOWLEDGEMENTS
			Assign licenses for specific services in Office 365 using PowerShell: 

			.NOTES
			Version:		1.0
			Date:			25/11/2020

			.VERSION HISTORY
			1.0: Initial Public Release

	#>

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1)] $UPN, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2)] $LicenceType
	)


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Grant-Office365UserLicence'
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

	#Check to see if we are connected to MSOL
	$Test = (Test-MSOLConnection)
	If ($Test.Status -ne "OK")
	{
		Write-Log -Message "Something went wrong granting $UPN's licence" -Severity 3 -Component $function
		Write-Log -Message "Test-MSOLConnection could not locate an MSOL connection" -Severity 2 -Component $function
		$Return.Status = "Error"
		$Return.Message = "No MSOL Connection"
		Return $Return
	}

	#Check Tenant has the licence
	Write-Log -Message "Verifying $LicenceType is available" -Severity 2 -Component $function
	Try
	{
		#Office365 does this thing where it preprends the tenant name on the licence
		#For example PHONESYSTEM_VIRTUALUSER would be "contoso:PHONESYSTEM_VIRTUALUSER"
		#So we need to learn the prefix, we do this by looking for the licence and storing it
		$O365AcctSku = $null
		$O365AcctSku = Get-MsolAccountSku | Where-Object {$_.SkuPartNumber -like $LicenceType}
		$LicenceToAssign = "$($O365AcctSku.AccountName):$LicenceType" #Build the full licence name
	}
	Catch
	{
		Write-Log -Message "Error Running Get-MsolAccountSku" -Severity 3 -Component $function
		Write-Log -Message $error[0]  -Severity 3 -Component $function
		$Return.Status = "Error"
		$Return.Message = "Unable to run Get-MsolAccountSku"
		Return $Return
	}

	if ($O365AcctSku -eq $null)
	{
		Write-Log -Message "Unable to locate Licence on Tenant" -Severity 3 -Component $function
		$Return.Status = "Error"
		$Return.Message = "Unable to locate $LicenceType Licence"
		Return $Return
	}

	#Check to see if there are free licences. Trigger a warning on less than 5% available
	$LicenceAvailablePercent = (($O365AcctSku.ConsumedUnits / $O365AcctSku.ActiveUnits) * 100)
	$AvailableLicenceCount = ($O365AcctSku.ActiveUnits - $O365AcctSku.ConsumedUnits)
	If (($LicenceAvailablePercent -le 5) -or ($AvailableLicenceCount -le 2))
	{
		Write-Log -Message "Only $AvailableLicenceCount $LicenceType Licences Left" -Severity 3 -Component $function
		Write-Log -Message "Available licence count low..." -Severity 3 -Component $function
		$WarningFlag = $True
		$WarningMessage = "Low Licence Count"
	}

	#Check for user
	Write-Log -Message "Checking for Existing User $UPN ..." -Severity 2 -Component $function
	Try #Check user exits
	{
		$O365User = (Get-MsolUser -UserPrincipalName $UPN -ErrorAction Stop)
		Write-Log -Message "User Exists. checking licences..." -Severity 2 -Component $function
		if ($O365User.Licenses.accountSkuID -contains $LicenceToAssign)
	  {
		  Write-Log -Message "User already has that licence, Skipping" -Severity 3 -Component $function
		  if ($warningFlag) #We Encounted a warning during the run
			{
				$Return.Status = "Warning"
				$Return.Message = "Skipped: Already Licenced, Warning Message $WarningMessage"
				Return $Return
			}
			Else
			{
				$Return.Status = "OK"
				$Return.Message = "Skipped: Already Licenced"
				Return $Return
			}
	  }



		Write-Log -Message "User Exists, Grant Licence" -Severity 2 -Component $function
		Try #Assign Licence
		{
			[Void] (Set-MsolUserLicense -UserPrincipalName $UPN -AddLicenses $LicenceToAssign -ErrorAction stop)
			Write-Log -Message "Licence Granted" -Severity 2 -Component $function
			if ($warningFlag) #We Encounted a warning during the run
			{
				$Return.Status = "Warning"
				$Return.Message = "Licence Granted, Warning Message $WarningMessage"
				Return $Return
			}
			Else
			{
				$Return.Status = "OK"
				$Return.Message = "Licence Granted"
				Return $Return
			}
		}
		Catch #Assigning Licence went wrong
		{
			Write-Log -Message "Something went wrong licencing user $UPN" -Severity 3 -Component $function
			Write-Log -Message $Error[0] -Severity 3 -Component $Function
			$Return.Status = "Error"
			$Return.Message = $Error[0]
			Return $Return
		}
	} #End User Check try block
	Catch #User exist Catch
	{ #User Doesnt Exist, error out
		Write-Log -Message "Something went wrong granting $UPN's licence" -Severity 3 -Component $function
		Write-Log -Message "Could not locate user $UPN" -Severity 2 -Component $function
		$Return.Status = "Error"
		$Return.Message = "User Not Found"
		Return $Return
	}
	#endregion FunctionWork


	#region FunctionReturn
 
	#Default Return Variable for my HTML Reporting Fucntion
	Write-Log -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
	$return.Status = "Unknown"
	$return.Message = "Function did not encounter return statement"
	Return $Return
	#endregion FunctionReturn
}