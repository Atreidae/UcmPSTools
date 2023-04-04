#PerformScriptSigning
Function Test-UcmSFBOConnection
{
	<#
			.SYNOPSIS
			Checks to see if we are connected to an SFBO session

			.DESCRIPTION
			Tries to pull tenant info and will call New-SFBOConnection if unsucsessful

			.EXAMPLE
			Test-UcmSFBOConnection

			.INPUTS
			This function does not accept any input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple keys to indicate status
			$Return.Status
			$Return.Message

			Return.Status can return one of four values
			"OK"      : Connected to Skype for Business Online
			"Warning" : Reconnected to Skype for Business Online
			"Error"   : Not connected to Skype for Business Online
			"Unknown" : Cmdlet reached the end of the function without returning anything, this shouldnt happen, if it does please log an issue on Github

			Return.Message returns descriptive text showing the connected tenant, mainly for logging or reporting

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPsTools

			.ACKNOWLEDGEMENTS

			.NOTES
			Version:		1.2
			Date:			24/03/2023

			.VERSION HISTORY
			1.2: Updated to use Teams Cmdlets

			1.1: Updated to "Ucm" naming convention
			Better inline documentation

			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Modules
			Microsoft Teams						(Install-Module MicrosoftTeams)
			UcmPSTools							(Install-Module UcmPsTools) Includes Cmdlets below.

			Cmdlets
			Write-UcmLog: 						https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-UcmLog.ps1
			New-UcmSFBOConnection				https://github.com/Atreidae/UcmPsTools/blob/main/public/New-UcmSFBOConnection.ps1

			.REQUIRED PERMISIONS
			'Teams Administrator' or better

	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '', Scope='Function')] #todo, https://github.com/Atreidae/UcmPSTools/issues/23

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Position=1)] [switch]$Reconnect #Should re allow this from Pipeline?
	)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Test-UcmSFBOConnection'
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

	#endregion FunctionSetup

	#region FunctionWork


	Write-UcmLog -Message "Checking for Existing Teams Phone System Connection" -Severity 1 -Component $function
	Try
	{
		(Get-CsTenant).tenantid
		$Return.Status = "OK"
		$Return.Message  = "Existing Connection"
		Return $Return
	}
	Catch
	{
		Write-UcmLog -Message "We dont appear to be connected to Teams Phone System!" -Severity 3 -Component $function

		If ($Reconnect) #If the user wants us to reconnect
		{
			#Cleanup old session
			Get-PSSession | Where-Object {$_.Name -like "SfBPowerShellSession*"} |Remove-PSSession

			#Call New-UcmSFBOSession
			$Connection = (Connect-MicrosoftTeams)

			#Check we actually connected
			If ($Connection.status -eq "Error") #an error was reported
			{
				$Return.Status = "Error"
				$Return.Message  = "Could not reconnect to Skype for Business Online"
				Return $Return
			}
			Else #The connection was succsessful
			{
				$Return.Status = "Warning"
				$Return.Message  = "Reconnected"
				Return $Return
			}
		}
		Else #Reconnect not set
		{
			$Return.Status = "Error"
			$Return.Message  = "Not Connected to SFBO"
			Return $Return
		}
	}

	#endregion FunctionWork

	#region FunctionReturn

	#Default Return Variable for my HTML Reporting Function
	Write-UcmLog -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
	$return.Status = "Unknown"
	$return.Message = "Function did not encounter return statement"
	Return $Return
	#endregion FunctionReturn
}