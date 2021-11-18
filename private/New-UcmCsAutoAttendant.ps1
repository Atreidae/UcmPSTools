#PerformScriptSigning
Function New-UcmCsAutoAttendantObject
{
	<#
			.SYNOPSIS
			Checks for and creates everything for an AutoAttendant

			.DESCRIPTION
			Checks for and creates everything for an AutoAttendant

			.EXAMPLE
			New-UcmCsAutoAttendantObject -AAUPN T-AA-emergency@contoso.onmicrosoft.com -CCUPN T-CC-emergency@contoso.onmicrosoft.com -FirstName Caleb -LastName Sills -Country US -DisplayName "Caleb Sills"

			.PARAMETER AAUPN
			Defines the UPN used to create the AutoAttendant Resource Account.

			.PARAMETER CCUPN
			Defines the UPN used to create the CallQueue Resource Account, by default the AutoAttendant will be pointed to this queue
			This must be different from the AA UPN

			.PARAMETER Language
			#todo

			.PARAMETER TimeZone
			#todo

			.PARAMETER TTSGreeting (Optional)
			#If specified will create a text to speech message 

			.PARAMETER AADefaultRouteType (Optional)
			#If specified what are we sending the call to

			.PARAMETER AADefaultRouteDestination (Optional)
			#If specified what SIP address/Number are we going to

			.INPUTS
			This function accepts both parameter and pipline input

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
			'Office365 User Admin' or better

			.LINK
			https://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPSTools


			.NOTES
			Version:		1.0
			Date:			27/09/2021

			.VERSION HISTORY
			1.0: Initial Public Release

	#>

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1)] $UPN, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2)] $DisplayName,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=3)][ValidateSet('AutoAttendant', 'CallQueue')] $ResourceType

	)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'New-UcmCsAutoAttendantObject'
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

	Write-UcmLog -Message "Checking for Existing Resource Account $UPN ..." -Severity 2 -Component $function
	#Check user exits
	
	$AppInstance = $null
	$AppInstance = (Get-CsOnlineApplicationInstance | Where-Object {$_.UserPrincipalName -eq $UPN})
	if ($AppInstance.UserPrincipalName -eq $UPN)
	{
		Write-UcmLog -Message "Resource Account already exists, Skipping" -Severity 3 -Component $function
		$Return.Status = "Warning"
		$Return.Message = "Skipped: Account Already Exists"
		Return $Return
	}
	Else
	{ #User Doesnt Exist, make them
		Write-UcmLog -Message "Not Found. Creating user $UPN" -Severity 2 -Component $function
		Try 
		{
			[Void] (New-CsOnlineApplicationInstance -UserPrincipalName $UPN -DisplayName $DisplayName -ApplicationId $ApplicationID -ErrorAction Stop)
			Write-UcmLog -Message "Resource Account Created Sucessfully" -Severity 2 -Component $function
			$Return.Status = "OK"
			$Return.Message = "Resource Account Created"
			Return $Return
		}
		Catch
		{
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
	#endregion Functions
}

PROCESS
{


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Process-Block'
	
	# Log why we were called
	Write-UcmLog -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-UcmLog -Message "Parameters" -Severity 3 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$Args" -Severity 1 -Component $function -LogOnly
Write-Host '' #Insert a blank line to make reading output easier on loops
	
	#endregion FunctionSetup

	#region FunctionWork
	#Assume if we cant see a UPN, then we didnt get passed anything on the pipeline
	if (!$UPN)
	{ 

		#Now check for a CSV file attribute
		Write-UcmLog -Message "No UPN Found, checking for CSV" -Severity 1 -Component $function

		If (!$CSVFile)
		{
			Write-UcmLog -Message 'No CSV Provided, Prompting user' -Severity 2 -Component $Function
			Write-Host ''
			Write-Host ''
			Write-Host 'No attendants to create! Please enter a CSV filename in the script folder'
			$CSVFile = (Read-Host -Prompt 'Filename')
			Write-UcmLog -component $Function -message "User provided $CSVFile" -Severity 1
		}
		#Now we have a CSV file defined, check for it
		Write-UcmLog -Message 'Checking for CSV File' -Severity 2 -Component $Function
		$CSVFilePath = $PSCommandPath -replace 'Initialize-CsAutoAttendants.ps1', $CSVFile
		If(!(Test-Path -Path $CSVFilePath ))
		{
			Write-UcmLog -Message "Could not locate $CSVFile in the same folder as this script" -Severity 3 -Component $Function
			Write-UcmLog -Message "No Attendants to process, Exiting Script" -Severity 5 -Component $Function
			Exit
		}
		Write-UcmLog -Message 'Calling Main Loop' -Severity 1 -Component $Function
		#Okay, we have what we think is a good CSV file, pass it to Invoke-CSUser
		Write-UcmLog -Message "Executing process block with Attendant $DisplayName" -Severity 1 -Component $Function
		Import-CSV -Path $CSVFilePath | ForEach-object {$_ | New-UcmCsAutoAttendantObject}
	}
     
	#Check to see if we got something on the pipeline, if we did. process it
	if ($AAUPN)
	{
		Write-UcmLog -Message "Executing process block with Attendant $DisplayName" -Severity 2 -Component $Function
		$_ | New-UcmCsAutoAttendantObject
	}
	#endregion FunctionWork
}


END {
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


#Check for and create the users

<#
ForEach ($Attendant in $aa) {$Attendant | New-TeamsResourceAccount -ResourceType AutoAttendant}
ForEach ($Attendant in $aa) {$Attendant | Grant-Office365UserLicence -licencetype PHONESYSTEM_VIRTUALUSER}
ForEach ($CallQueue in $cc) {$CallQueue | New-TeamsResourceAccount -ResourceType CallQueue}
ForEach ($CallQueue in $CC) {$CallQueue | Grant-Office365UserLicence -licencetype PHONESYSTEM_VIRTUALUSER}


#Licnec for stuff PHONESYSTEM_VIRTUALUSER
#>