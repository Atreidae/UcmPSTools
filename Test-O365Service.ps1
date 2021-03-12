Function Test-O365Service
{
	<#
			.SYNOPSIS
			Enables a Specified Service in Office365

			.DESCRIPTION
		

			.EXAMPLE
			Enable-O365Service -ServiceName MCOEV

			.INPUTS
			User UPN

			.REQUIRED FUNCTIONS
			Write-Log: 						https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-Log.ps1
			Write-HTMLReport: 			https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-HTMLReport.ps1 (optional)

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Fuctions

			.ACKNOWLEDGEMENTS

			.NOTES
			Version:		1.0
			Date:			10/03/2021

			.VERSION HISTORY
			1.0: Initial Public Release

	#>

	Param #No parameters
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1)] $UPN, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2)] $ServiceName 
	)


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Test-O365Service'
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
	$Enabled =$false
	#region FunctionWork

	#Get the users licences and enumerate through them looking for the relevant service
	$LicenseDetails = (Get-MsolUser -UserPrincipalName $UPN).Licenses
	ForEach ($License in $LicenseDetails) {
		$License.ServiceStatus | ForEach-Object {
			If ($_.ProvisioningStatus -eq "Disabled" -and $_.ServicePlan.ServiceName -eq "$serviceName")
			{ 
				Write-Log -Message "$ServiceName Disabled" -Severity 2 -Component $function
			}
			Elseif ($_.ProvisioningStatus -eq "Success" -and $_.ServicePlan.ServiceName -eq "$serviceName")
			{ 
				Write-Log -Message "$ServiceName Enabled" -Severity 2 -Component $function
				$Enabled = $true
			}
			ElseIf ($_.ServicePlan.ServiceName -like "*$serviceName*")
			{
				Write-Log -Message "$ServiceName is in unknown state" -Severity 2 -Component $function
				$Enabled = "Error"
			}
		}
	}

	If ($enabled -eq "Error")
	{ 
		Write-Log -Message "$ServiceName is in unknown state" -Severity 2 -Component $function
		$Return.Status = "ERROR"
		$Return.Message  = "$ServiceName is in unknown state"
		Return $Return
	}
	Elseif ($enabled -eq $true)
	{ 
		Write-Log -Message "$ServiceName Enabled" -Severity 2 -Component $function
		$Return.Status = "OK"
		$Return.Message  = "$ServiceName Enabled"
		Return $Return
	}
	ElseIf ($_.ServicePlan.ServiceName -like "*$serviceName*")
	{
		Write-Log -Message "$ServiceName Disabled" -Severity 2 -Component $function
		$Return.Status = "Warn"
		$Return.Message  = "$ServiceName Disabled"
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