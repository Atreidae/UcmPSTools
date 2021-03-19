Function New-EXHOConnection
{
	<#
			.SYNOPSIS
			Grabs stored creds and creates a new EXHO session

			.DESCRIPTION
			Grabs stored creds and creates a new EXHO session

			.EXAMPLE
			New-EXHOConnection

			.INPUTS
			This function does not accept any input

			.REQUIRED FUNCTIONS
			Write-Log: 						https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-Log.ps1
			SkypeOnlineConnector

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Fuctions

			.ACKNOWLEDGEMENTS

			.NOTES
			Version:		1.0
			Date:			15/12/2020

			.VERSION HISTORY
			1.0: Initial Public Release

	#>

	Param #No parameters
	(

	)


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'New-EXHOConnection'
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

	#Check we have creds, if not, get and store them
	If ($Global:Config.SignInAddress -eq $null)
	{
		Write-Log -Message "No Credentials stored in Memory, checking for Creds file" -Severity 2 -Component $function
		If(!(Test-Path cred.xml)) 
		{
			Write-Log -component $function -Message 'Could not locate creds file' -severity 2

			#Create a new creds file
			$null = (Remove-Variable -Name Config -Scope Global -ErrorAction SilentlyContinue)
			$global:Config = @{}
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
			Write-Log -component $function -Message 'Importing Credentials File' -severity 2
			$global:Config = @{}
			$global:Config = (Import-Clixml -Path ".\cred.xml")
			Write-Log -component $function -Message 'Creds Loaded' -severity 2
		}
	}

	#Get the creds ready for the module

	$global:StoredPsCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($global:Config.SignInAddress, $global:Config.Credential)
	($global:StoredPsCred).Password.MakeReadOnly() #Stop modules deleteing the variable.


	$pscred = $global:StoredPsCred
	#Exchange connection try block
	Write-Log -Message 'Connecting to Exchange Online' -Severity 2 -Component $function
	if ($Global:Config.override -eq $Null){ $EXCHOSession = (New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $pscred -Authentication Basic -AllowRedirection)}
	Else {$EXCHOSession = (New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $pscred -Authentication Basic -AllowRedirection) } #todo fix override
	Import-Module (Import-PSSession -Session $EXCHOSession -AllowClobber -DisableNameChecking) -Global -DisableNameChecking

	$Return.Status = "OK"
	$Return.Message  = "Connected"
	Return $Return
	


	#endregion FunctionWork

	#region FunctionReturn
 
	#Default Return Variable for my HTML Reporting Fucntion
	Write-Log -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
	$return.Status = "Unknown"
	$return.Message = "Function did not encounter return statement"
	Return $Return
	#endregion FunctionReturn

}