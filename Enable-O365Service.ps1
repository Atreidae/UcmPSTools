Function Enable-O365Service
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
	$function = 'Enable-O365Service'
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
	$AppEnabled = $False
	#Get the user Licence details
	$LicenseDetails = (Get-MsolUser -UserPrincipalName $UPN).Licenses

	#Run through all the services on each licence
	ForEach ($License in $LicenseDetails) {
		Write-Log -Message "Checking $($License.AccountSkuId) for $Servicename" -Severity 1 -Component $function
		
		#Find all the Disabled licences and add them to an array, except for the requsted service
		$DisabledOptions = @()
		ForEach ($Service in $License.ServiceStatus)
		{
			Write-Log -Message "Checking $($Service.ServicePlan.ServiceName)" -Severity 1 -Component $function
			If ($Service.ProvisioningStatus -eq "Disabled") 
			{
				#The Service Is disabled, check to see if its the requested service
				If ($Service.ServicePlan.ServiceName -eq $ServiceName)
				{
					Write-Log -Message "$Servicename Was disabled, Exlcuding from Disabled Options" -Severity 2 -Component $function
					$AppEnabled = $true
					Write-Log -Message "Licence enabled" -Severity 2 -Component $function
				}
				Else
				{
					Write-Log -Message "$($Service.ServicePlan.ServiceName) is disabled, adding to Disabled Options" -Severity 1 -Component $function
					$DisabledOptions += "$($Service.ServicePlan.ServiceName)"
				}
			}
		}
		#Set the Licence options using the new list of disabled licences
		Try {
			Write-Log -Message "Setting Licence Options with the following Disabled Services" -Severity 1 -Component $function
			Write-Log -Message "$DisabledOptions" -Severity 1 -Component $function
			If ($DisabledOptions.count -eq 0)
			{
				$LicenseOptions = New-MsolLicenseOptions -AccountSkuId $License.AccountSkuId -DisabledPlans $DisabledOptions
			}
			Else
			{ 
				$LicenseOptions = New-MsolLicenseOptions -AccountSkuId $License.AccountSkuId -DisabledPlans $DisabledOptions
			}
			Set-MsolUserLicense -UserPrincipalName $UPN -LicenseOptions $LicenseOptions

		}
		Catch
		{
			Write-Log -Message "Something went wrong assinging the licence" -Severity 3 -Component $function 
				
		}
	} #Repeat for the next Licence


	If ($AppEnabled){
		$Return.Status = "OK"
		$Return.Message  = "Enabled"
		Return $Return
	}
	Else{
		$Return.Status = "Error"
		$Return.Message  = "Unknown Error"
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