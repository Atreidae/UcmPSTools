﻿#DontPerformScriptSigning
Function Invoke-UcmBatchSfb2TeamsMove
{
	<#
			.SYNOPSIS
			Migrates a large number of users from Skype for Business to Teams in one batch in an attempt to reduce migration time

			.DESCRIPTION
			Provided with an array object on the pipeline containing CsUser objects, will attempt to migrate them all to O365, locate the results file and return an array with global sucssess/failure as well as the results file path
			
			Looks for,(todo) and attempts to use the credentials stored in $Global:Creds

			.EXAMPLE
			PS> Invoke-UcmBatchSfb2TeamsMove

			.INPUTS
			This function accepts a PSCustom Object on the Pipeline with for the UPN, SamAccountName, or SipAddress Parameters, all others must be specified in when calling the function

			UPN - The full upn of the user you wish to migrate eg: "Button.Mash@UcMadScientist.com"
			SamAccountName - The SamAccountName of the user you with to migrate, without any domain prefix eg: "B.mash"
			SipAddress - The Sip Address of the user you wish to move, eg: "button.mash@contoso.com"

			.PARAMETER UPN
			The UPN of the user you wish to move, eg: "button.mash@contoso.com"
			Can be passed as an array of objects on the pipeline

			.PARAMETER SamAccountName 
			The SamAccountName of the user you wish to move, eg: "B.mash"
			Can be passed as an array of objects on the pipeline

			.PARAMETER SipAddress
			The Sip Address of the user you wish to move, eg: "button.mash@contoso.com"
			Can be passed as an array of objects on the pipeline

			.PARAMETER Target
			The desired target of the move, "SipFed.Online.Lync.com" by default.

			.PARAMETER HostedMigrationOverrideUrl (Required)
			The url to pass to Move-CsUser as a Hosted Migration Overide. 
			For information on how to locate this, see Sean Boss' article over here
			https://uclikeaboss.wordpress.com/2020/02/16/get-sfb-hosted-migration-override-url-programmatically/

			.PARAMETER ProxyPool (Required)
			The On-Prem pool used to move the user online, must have an associated edge server

			.PARAMETER -Credential (Highly Reccomended)
			Provides use creds to the move-csuser cmdlet to stop it re-promping for user creds and getting stuck after 10 users.
			Pass as a System.Management.Automation.PSCredential object (Get-Credential format)

			.PARAMETER DontBypassAudioConferencingCheck
			When set, shows the warning that the online user doesnt have a Dial In Audio Conferencing licence 

			.PARAMETER -DontUseOAuth 
			When set, doesnt ask Move-CsUser to use OAuth authentication for Skype4B 2015 and better instead of the live signin assistant.
			Not reccomended unless you're on Lync 2013

			.OUTPUTS
			This Cmdet returns a PSCustomObject with multiple keys to indicate status
			$Return.Status 
			$Return.Message
			$Return.Results 

			Return.Status can return one of three values
			"OK"      : Connected to Azure AD (V1)
			"Error"   : Not connected to Azure AD (V1)
			"Unknown" : Cmdlet reached the end of the fucntion without returning anything, this shouldnt happen, if it does please log an issue on Github
			
			Return.Message returns descriptive text showing the connected tenant, mainly for logging or reporting

			$Return.Results returns the results HTML file from Move-CsUser for mapping into HTML-Report

			.NOTES
			Version:		1.0
			Date:			20/07/2021

			.VERSION HISTORY
					
			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Modules
			Lync or SkypeForBusiness			(Included with your Lync or Skype install)
			UcmPSTools							(Install-Module UcmPsTools) Includes Cmdlets below.

			Cmdlets
			Write-UcmLog: 						https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-UcmLog.ps1

			.REQUIRED PERMISSIONS
			Any privledge level that can run relocate users to O365  
			Typically "Office 365 User Administrator" and "Teams Administrator" in O365 as well as "CsAdministrator" on prem

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPSTools

			.ACKNOWLEDGEMENTS
			Greig Sheridan: Stop connect cmdlets deleting password variable https://github.com/Atreidae/BounShell/issues/7
	#>

	Param #No parameters
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Position=1,HelpMessage='The UPN of the user you wish to move, eg: button.mash@contoso.com')] [string]$UPN, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Position=2,HelpMessage='The SamAccountName of the user you wish to move, eg: "B.mash"')] [string]$SamAccountName,
		[Parameter(ValueFromPipelineByPropertyName=$true, Position=3,HelpMessage='The Sip Address of the user you wish to move, eg: "button.mash@contoso.com"')] [string]$SipAddress,
		[Parameter(ValueFromPipelineByPropertyName=$False, Position=4,HelpMessage='The desired target of the move')] [string]$Target = 'SipFed.Online.Lync.com',
		[Parameter(ValueFromPipelineByPropertyName=$False, Mandatory, Position=6,HelpMessage='The url to pass to Move-CsUser as a Hosted Migration Overide.')] [string]$HostedMigrationOverrideUrl,
		[Parameter(ValueFromPipelineByPropertyName=$False, Mandatory, Position=5,HelpMessage='The pool used to move the user online, must have an associated edge server')] [String]$ProxyPool, 
		[Parameter(ValueFromPipelineByPropertyName=$False, Position=7,HelpMessage='Show the warning that the online user doesnt have a Dial In Audio Conferencing licence')] [Switch]$DontBypassAudioConferencingCheck, 
		[Parameter(ValueFromPipelineByPropertyName=$False, Position=8,HelpMessage='Dont ask Move-CsUser to use OAuth authentication for Skype4B 2015 and better instead of the live signin assistant')] [Switch]$DontUseOAuth,
		[Parameter(ValueFromPipelineByPropertyName=$False, Position=9,HelpMessage='O365 Credentials to move the users')] [SecureString]$Credential
	)
	Begin
	{
		#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
		$function = 'Invoke-UcmBatchSfb2TeamsMove'
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
		

		#Check for a -Credential Flag, then fall back to $config.Credential, Then throw an error
		#Check we have actually been passed at least one user

		if (($UPN -eq "") -and ($SamAccountName -eq "") -and ($SipAddress -eq ""))
		{
			Write-UcmLog -Message "No user details provided" -Severity 1 -Component $function

			Write-UcmLog -Message 'No users specified' -Severity 5 -Component $function
			Throw "No Users, Stop"
		}
		
		#SipAddress Not Implemented, Throw an error
		if ($SipAddress -ne "")
		{
			Write-UcmLog -component $function -message 'Find-UcmSuppliedUserDetails with a sip address, not implemented yet im afraid' -severity 3
			Throw "No Sip Address Support"

		}



		#Check for a -Credential Flag, then fall back to $config.Credential, Then throw an error

		if (!$Credential)
		{
			Write-UcmLog -Message "No credentials provided on the command line" -Severity 1 -Component $function
			if (!$config.Credential)
			{
				Write-UcmLog -Message "Global Credential Variable missing" -Severity 1 -Component $function

				Write-UcmLog -Message 'No valid credentials found, Please either define $Config.credental or specifiy -credentials when invoking the cmdlet' -Severity 5 -Component $function
				Throw "No Creds, Stop"

			}

		}


		#Check for and import the Skype4BModule
		$ModuleCheck = (Import-CsOnPremTools)
		If ($ModuleCheck.Status -contains "Err")
		{
			Write-UcmLog -Message "Something went wrong running Import-CsOnPremTools, Cannot Continue" -Severity 5 -Component $function
			End
		}

		#Create an array to store the users to move

		$UserObjects= @()

		#endregion FunctionSetup
	}

	PROCESS
	{

		#Translate the passed SamAccountName or UPN into a user object and store that
		$CsUserSearch = ""
		if ($_.UPN -ne "") {$CsUserSearch =  ($_.UPN.split('@')[0])}
		if ($_.SamAccountName -ne "") {$CsUserSearch =  $_.SamAccountName}

		#region FunctionWork


		Find-UcmSuppliedUserDetails -Skipprompt -csusername 

		#Check we have creds in memory, if not check for cred.xml, failing that prompt the user and store them.
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
			Else
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

		#Connect to MSOL
		$pscred = $global:StoredPsCred
		Write-UcmLog -Message 'Connecting to MSOnline (AzureAD V1)' -Severity 2 -Component $function
		Try
		{
			$MSOLSession = (Connect-MsolService -Credential $pscred)
			
			#Import the connected session
			Import-Module (Import-PSSession -Session $MSOLSession -AllowClobber -DisableNameChecking) -Global -DisableNameChecking
			
			#We haven't errored so return sucsessful
			$Return.Status = "OK"
			$Return.Message  = "Connected"
			Return $Return
		}
		Catch
		{
			#Something went wrong during the try block, return error
			$Return.Status = "Error"
			$Return.Message  = "Failed to connect to Microsoft Online (AzureAD V1): $error[0]"
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