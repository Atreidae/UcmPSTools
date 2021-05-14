<#
		.SYNOPSIS

		This is a quick and nasty Teams AutoAttendant setup script
		It will check if the auto attendat exists, if not it will check/create the associated user, licence them and create the AA. 

		.DESCRIPTION

		Created by James Arber. www.UcMadScientist.com

		.EXAMPLE
		Initialize-CsAutoAttendants Todo Todo

		.INPUTS
		This function accepts both parameter and pipline input

		.REQUIRED FUNCTIONS
		Write-Log: 							https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-Log.ps1
		Test-MSOLConnection:				https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Test-MSOLConnection.ps1
		New-MSOLConnection:				https://github.com/Atreidae/PowerShell-Fuctions/blob/main/New-MSOLConnection.ps1
		New-Office365User:				https://github.com/Atreidae/PowerShell-Fuctions/blob/main/New-Office365User.ps1
		Grant-Office365UserLicence:	https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Grant-Office365UserLicence.ps1
		Write-HTMLReport:					https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-HTMLReport.ps1

		AzureAD					(Install-Module AzureAD) 
		Connect-MsolService

		.LINK
		http://www.UcMadScientist.com
		https://github.com/Atreidae/PowerShell-Fuctions

		.ACKNOWLEDGEMENTS

		.KNOWN ISSUES
		Leaving script open for long periods of time (days) can cause timeout issues with Office365. Close the PowerShell Window / ISE or kill any PSSessions to resolve.

		.NOTES
		Version:		0.1
		Date:			26/11/2020

		.VERSION HISTORY
		1.0: Initial Public Release

#>

Param
(
	[Parameter(ValueFromPipelineByPropertyName=$true, Position=1)] $AAUPN=$null, 
	[Parameter(ValueFromPipelineByPropertyName=$true, Position=1)] $CCUPN=$null, 
	[Parameter(ValueFromPipelineByPropertyName=$true, Position=2)] $Password=$null,
	[Parameter(ValueFromPipelineByPropertyName=$true, Position=3)] $FirstName=$null,
	[Parameter(ValueFromPipelineByPropertyName=$true, Position=4)] $LastName=$null,
	[Parameter(ValueFromPipelineByPropertyName=$true, Position=5)] $Country=$null,
	[Parameter(ValueFromPipelineByPropertyName=$true, Position=6)] $DisplayName=$null,
	[Parameter(ValueFromPipelineByPropertyName=$true, Position=7)] $CSVFile=$null
)

#todo, Non public release. Dot Source all the external functions



BEGIN
{
	#############################
	# Script Specific Variables #
	#############################

	$ScriptVersion					 =  0.1
	$StartTime						 =  Get-Date
	$Script:LogFileLocation		 =  $PSCommandPath -replace '.ps1','.log' #Where do we store the log files? (In the same folder by default)

	#region Functions
	##################
	# Function Block #
	##################
	$Function = "Begin-Block, Fucntion Import"
	. ..\PowerShell-Functions\Write-Log.ps1

  Write-Log -Message "$ScriptVersion script started at $StartTime" -Severity 1 -Component $Function
  Write-Log -Message 'Importing functions' -Severity 1 -Component $Function

	#Import my External Functions

	. ..\PowerShell-Functions\Initialize-HTMLReport.ps1
	. ..\PowerShell-Functions\New-Office365User.ps1
	. ..\PowerShell-Functions\New-TeamsResourceAccount.ps1
	. ..\Powershell-Functions\Grant-Office365UserLicence.ps1
	. ..\Powershell-Functions\Test-MSOLConnection.ps1
	. ..\Powershell-Functions\Test-SFBOConnection.ps1

Function Invoke-CsAutoAttendant
{
	<#
			.SYNOPSIS
			Checks for and creates everything for an AutoAttendant

			.DESCRIPTION
			Checks for and creates everything for an AutoAttendant

			.EXAMPLE
			Invoke-CsAutoAttendant -AAUPN T-AA-emergency@contoso.onmicrosoft.com -CCUPN T-CC-emergency@contoso.onmicrosoft.com -FirstName Caleb -LastName Sills -Country US -DisplayName "Caleb Sills"


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
			#If specified what are we sending teh call to #todo

			.PARAMETER AADefaultRouteDestination (Optional)
			#If specified what SIP address/Number are we going to #todo


			.INPUTS
			This function accepts both parameter and pipline input

			.REQUIRED FUNCTIONS
			Write-Log: https://github.com/Atreidae/PowerShell-Functions/blob/main/New-Office365User.ps1
			AzureAD (Install-Module AzureAD) 
			Connect-MsolService

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Functions

			.ACKNOWLEDGEMENTS

			.NOTES
			Version:		1.0
			Date:			25/11/2020

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
	$function = 'Invoke-CsAutoAttendant'
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

	#Check to see if we are connected to SFBO

			$Test = (Test-SFBOConnection)
			If ($Test.Status -ne "OK")
			{
			Write-Log -Message "Something went wrong creating user $UPN" -Severity 3 -Component $function
			Write-Log -Message "Test-MSOLConnection could not locate an MSOL connection" -Severity 2 -Component $function
			$Return.Status = "Error"
			$Return.Message = "No MSOL Connection"
			Return $Return
			}
	#>
	Write-Log -Message "Checking for Existing Resource Account $UPN ..." -Severity 2 -Component $function
	#Check user exits
	
	$AppInstance = $null
	$AppInstance = (Get-CsOnlineApplicationInstance | Where-Object {$_.UserPrincipalName -eq $UPN})
	if ($AppInstance.UserPrincipalName -eq $UPN)
	{
		Write-Log -Message "Resource Account already exists, Skipping" -Severity 3 -Component $function
		$Return.Status = "Warning"
		$Return.Message = "Skipped: Account Already Exists"
		Return $Return
	}
	Else
	{ #User Doesnt Exist, make them
		Write-Log -Message "Not Found. Creating user $UPN" -Severity 2 -Component $function
		Try 
		{
			[Void] (New-CsOnlineApplicationInstance -UserPrincipalName $UPN -DisplayName $DisplayName -ApplicationId $ApplicationID -ErrorAction Stop)
			Write-Log -Message "Resource Account Created Sucessfully" -Severity 2 -Component $function
			$Return.Status = "OK"
			$Return.Message = "Resource Account Created"
			Return $Return
		}
		Catch
		{
			Write-Log -Message "Something went wrong creating user $UPN" -Severity 3 -Component $function
			Write-Log -Message $Error[0] -Severity 3 -Component $Function
			$Return.Status = "Error"
			$Return.Message = $Error[0]
			Return $Return
		}
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
	#endregion Functions
}

PROCESS
{


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Process-Block'
	
	# Log why we were called
	Write-Log -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-Log -Message "Parameters" -Severity 3 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$Args" -Severity 1 -Component $function -LogOnly
Write-Host '' #Insert a blank line to make reading output easier on loops
	
	#endregion FunctionSetup

	#region FunctionWork
	#Assume if we cant see a UPN, then we didnt get passed anything on the pipeline
	if (!$UPN)
	{ 

		#Now check for a CSV file attribute
		Write-Log -Message "No UPN Found, checking for CSV" -Severity 1 -Component $function

		If (!$CSVFile)
		{
			Write-Log -Message 'No CSV Provided, Prompting user' -Severity 2 -Component $Function
			Write-Host ''
			Write-Host ''
			Write-Host 'No attendants to create! Please enter a CSV filename in the script folder'
			$CSVFile = (Read-Host -Prompt 'Filename')
			Write-Log -component $Function -message "User provided $CSVFile" -Severity 1
		}
		#Now we have a CSV file defined, check for it
		Write-Log -Message 'Checking for CSV File' -Severity 2 -Component $Function
		$CSVFilePath = $PSCommandPath -replace 'Initialize-CsAutoAttendants.ps1', $CSVFile
		If(!(Test-Path -Path $CSVFilePath ))
		{
			Write-Log -Message "Could not locate $CSVFile in the same folder as this script" -Severity 3 -Component $Function
			Write-Log -Message "No Attendants to process, Exiting Script" -Severity 5 -Component $Function
			Exit
		}
		Write-Log -Message 'Calling Main Loop' -Severity 1 -Component $Function
		#Okay, we have what we think is a good CSV file, pass it to Invoke-CSUser
		Write-Log -Message "Executing process block with Attendant $DisplayName" -Severity 1 -Component $Function
		Import-CSV -Path $CSVFilePath | ForEach-object {$_ | Invoke-CsAutoAttendant}
	}
     
	#Check to see if we got something on the pipeline, if we did. process it
	if ($AAUPN)
	{
		Write-Log -Message "Executing process block with Attendant $DisplayName" -Severity 2 -Component $Function
		$_ | Invoke-CsAutoAttendant
	}
	#endregion FunctionWork
}


END {
	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'END-Block'
	
	# Log why we were called
	Write-Log -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-Log -Message "Parameters" -Severity 3 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$Args" -Severity 1 -Component $function -LogOnly
	
	#endregion FunctionSetup
	
	Write-Log -Message "Executing process block with Attendant $DisplayName" -Severity 1 -Component $Function

}


#Check for and create the users

<#
ForEach ($Attendant in $aa) {$Attendant | New-TeamsResourceAccount -ResourceType AutoAttendant}
ForEach ($Attendant in $aa) {$Attendant | Grant-Office365UserLicence -licencetype PHONESYSTEM_VIRTUALUSER}
ForEach ($CallQueue in $cc) {$CallQueue | New-TeamsResourceAccount -ResourceType CallQueue}
ForEach ($CallQueue in $CC) {$CallQueue | Grant-Office365UserLicence -licencetype PHONESYSTEM_VIRTUALUSER}


#Licnec for stuff PHONESYSTEM_VIRTUALUSER
#>