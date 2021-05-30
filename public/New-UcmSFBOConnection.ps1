#PerformScriptSigning
Function New-UcmSFBOConnection
{
	<#
			.SYNOPSIS
			Grabs stored creds and creates a new SFBO session

			.DESCRIPTION
			This function is designed to auto reconnect to Skype for Business online during batch migrations and the like.
			At present, it does not support modern auth. (The New-CsOnlineSession cmdlet doesnt support certificates yet)
			
			When called, the function looks for a cred.xml file in the current folder and attempts to connect to Skype for Business online using Basic Auth
			
			If there is no cred.xml in the current folder it will prompt for credentials, encrypt them and store them in a cred.xml file.
			The encrypted credentials can only be read by the windows user that created them so other users on the same system cant steal your credentials.

			.EXAMPLE
			PS> New-UcmSFBOConnection

			.INPUTS
			This function does not accept any input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple Keys to indicate status
			$Return.Status 
			$Return.Message 

			Return.Status can return one of three values
			"OK"      : Connected to Skype for Business Online
			"Error"   : Unable to connect to Skype for Business Online
			"Unknown" : Cmdlet reached the end of the function without returning anything, this shouldnt happen, if it does please log an issue on Github
			
			Return.Message returns descriptive text showing the connected tenant, mainly for logging or reporting

			.NOTES
			Version:		1.2
			Date:			15/05/2021

			.VERSION HISTORY
			1.2: Fixed required module references (incorrectly referenced the Exchange Module)
			
			1.1: Updated to "Ucm" naming convention
			Better inline documentation
					
			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Modules
			Microsoft Teams						(Install-Module MicrosoftTeams)
			UcmPSTools							(Install-Module UcmPsTools) Includes Cmdlets below.

			Cmdlets
			Write-UcmLog: 						https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-UcmLog.ps1
			Write-HTMLReport: 					https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-HTMLReport.ps1 (optional)


			.REQUIRED PERMISIONS
			'Exchange Read Only Administrator' or better

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPsTools

			.ACKNOWLEDGEMENTS
			Greig Sheridan: Stop connect cmdlets deleting password variable https://github.com/Atreidae/BounShell/issues/7
	#>

	Param #No parameters
	(

	)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'New-UcmSFBOConnection'
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

	#Check we have creds, if not, get and store them
	If ($Global:Config.SignInAddress -eq $null)
	{
		Write-UcmLog -Message "No Credentials stored in Memory, checking for Creds file" -Severity 2 -Component $function
		If(!(Test-Path cred.xml)) 
		{
			Write-UcmLog -component $function -Message 'Could not locate creds file' -severity 2

			#Create a new creds variable
			$null = (Remove-Variable -Name Config -Scope Global -ErrorAction SilentlyContinue)
			$global:Config = @{}

			#Prompt user for creds
			$Global:Config.SignInAddress = (Read-Host -Prompt "Username")
			$Global:Config.Password = (Read-Host -Prompt "Password")
			$Global:Config.Override = (Read-Host -Prompt "OverrideDomain (Blank for none)")

			#Encrypt the creds
			$global:Config.Credential = ($Global:Config.Password | ConvertTo-SecureString -AsPlainText -Force)
			Remove-Variable -Name "Config.Password" -Scope "Global" -ErrorAction SilentlyContinue

			#write a secure creds file
			$Global:Config | Export-Clixml -Path ".\cred.xml"
		}
		Else #Cred XML Exists, load it
		{
			Write-UcmLog -component $function -Message 'Importing Credentials File' -severity 2
			$global:Config = @{}
			$global:Config = (Import-Clixml -Path ".\cred.xml")
			Write-UcmLog -component $function -Message 'Creds Loaded' -severity 2
		}
	}

	#Get the creds ready for the module

	$global:StoredPsCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($global:Config.SignInAddress, $global:Config.Credential)
	($global:StoredPsCred).Password.MakeReadOnly() #Stop modules deleteing the variable.

	#Connect to SFBO
	$pscred = $global:StoredPsCred
	Write-UcmLog -Message 'Connecting to Skype4B Online' -Severity 2 -Component $function
	Try
	{
		#Handle Domain Override
		If ($Global:Config.override -eq "")
		{
			$S4BOSession = (New-CsOnlineSession -Credential $pscred)
		}
		Else 
		{
			$S4BOSession = (New-CsOnlineSession -Credential $pscred -OverrideAdminDomain $Global:Config.Override) 
		}
		
		#Import the connected session
		Import-Module (Import-PSSession -Session $S4BOSession -AllowClobber -DisableNameChecking) -Global -DisableNameChecking
		
		#We haven't errored so return sucsessful
		$Return.Status = "OK"
		$Return.Message  = "Connected"
		Return $Return
	}
	Catch
	{
		#Something went wrong during the try block, return error
		$Return.Status = "Error"
		$Return.Message  = "Failed to connect to Skype for Business Online: $error[0]"
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