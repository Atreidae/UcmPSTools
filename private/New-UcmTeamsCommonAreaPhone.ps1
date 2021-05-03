#This needs a rewrite to support my new pipelining method


Function New-UcmTeamsCommonAreaPhone
{
	<#
			.SYNOPSIS
			Checks for and creates new Teams Common Area Phones

			.DESCRIPTION
			This cmdlet creates Common Area Phones in Teams, it's designed to take inputs on the pipeline with common area phones details
			The cmdlet will then create the Office365 users, assign them the proper licences, create the objects in Teams and assign them the relevant policies.
			
			Note: I highly reccomend using "onmicrosoft" accounts for your common area phones, this alleviates any AAD sync issues
			
			.EXAMPLE
			New-UcmCommonAreaPhone -UPN 'GoldenOaks@contoso.onmicrosoft.com'-DisplayName 'Golden Oaks Library Phone' -Password 'Passw0rd1' -LineUri '+61386408640' -OnlineVoiceRoutingPolicy 'AU-VIC-SBC' -VoiceRoutingPolicy 'InternationalCallsAllowed' -TenantDialPlan 'AU-Victoria'
			
			Creates a new common area phone user GoldenOaks@contoso.onmicrosoft.com and assigns it the details passed on the commandline

			.EXAMPLE
			Import-Csv .\CommonAreaPhones.csv | New-UcmCommonAreaPhone
			
			Creates the user accounts, objects and assigns policies per the CSV file CommonAreaPhones.csv

			.INPUTS
			This function accepts both parameter and pipline input

			.OUTPUT
			This cmdlet outputs a HTML report in the current working directory

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPsTools

			.ACKNOWLEDGEMENTS

			.NOTES
			Version:		1.1
			Date:			27/03/2021

			.VERSION HISTORY
			1.0: Initial Public Release


			.REQUIRED FUNCTIONS/MODULES
			AzureAD									(Install-Module AzureAD)
			Connect-MsolService						(Install-Modile MSOnline)
			UcmPSTools								(Install-Module UcmPsTools) Includes Cmdlets below.
				Write-UcmLog: 						https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-UcmLog.ps1
				Initialize-UcmHTMLReport			https://github.com/Atreidae/UcmPsTools/blob/main/public/Initialize-UcmHTMLReport.ps1
				New-UcmHTMLReportItem				https://github.com/Atreidae/UcmPsTools/blob/main/public/New-UcmHTMLReportItem.ps1
				New-UcmHTMLReportStep				https://github.com/Atreidae/UcmPsTools/blob/main/public/New-UcmHTMLReportStep.ps1
				Test-UcmSFBOConnection				https://github.com/Atreidae/UcmPsTools/blob/main/public/Test-UcmSFBOConnection.ps1
				New-UcmSFBOConnection				https://github.com/Atreidae/UcmPsTools/blob/main/public/New-UcmSFBOConnection.ps1
				Test-UcmMSOLConnection				https://github.com/Atreidae/UcmPsTools/blob/main/public/Test-UcmMSOLConnection.ps1
				New-UcmMSOLConnection				https://github.com/Atreidae/UcmPsTools/blob/main/public/New-UcmMSOLConnection.ps1
				New-UcmOffice365User				https://github.com/Atreidae/UcmPsTools/blob/main/public/New-UcmOffice365User.ps1
				Grant-UcmOffice365UserLicence		https://github.com/Atreidae/UcmPsTools/blob/main/public/Grant-UcmOffice365UserLicence.ps1

	#>

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory )] $UPN,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory )] $Password,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory)] $DisplayName,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory)] $LineURI,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory)] $VoicePolicy,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory)] $DialPlan
)


Begin
{
	#todo, Remove Debugging 
	$Script:LogFileLocation = $PSCommandPath -replace '.ps1','.log'
	$VerbosePreference = "Continue"


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'New-UcmTeamsCommonAreaPhone'
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

#Start a new report
Initialize-UcmHTMLReport -Title "UcmPsTools - Common Area Phones"

#Create a new custom object to hold everything from the Pipeline


}

#Capture everything on the pipeline and create report objects for them
Process
{
#Start a new line item in the HTML Report
New-UcmHTMLReportItem -LineTitle "Username" -LineMessage "$upn"

#Check that we have an SFBO Connection
$Return =(Test-SFBOConnection)
New-HTMLReportStep -StepName "$($Return.Function)" -StepResult "$($return.Status): $($return.message)"

#Check that we have an MSOL Connection
$Return =(Test-MSOLConnection)
New-HTMLReportStep -StepName "$($Return.Function)" -StepResult "$($return.Status): $($return.message)"

#Create the Common Area Phone User
$Return =(New-Office365User -UPN $upn -Password $Password -FirstName 'CAP' -LastName $DisplayName -Country "AU" -DisplayName $DisplayName)
New-HTMLReportStep -StepName "$($Return.Function)" -StepResult "$($return.Status): $($return.message)"

#Grant the user a Common Area Phone Licence
$Return =(Grant-Office365UserLicence -UPN $upn -Country 'AU' -LicenceType 'MCOCAP')
New-HTMLReportStep -StepName "$($Return.Function)" -StepResult "$($return.Status): $($return.message)"

#todo Check number is in use

#Enable EV and set number
#todo fix the reporting
$Return =(Set-CsUser -Identity $Upn -OnPremLineURI $LineURI -EnterpriseVoiceEnabled $true)
New-HTMLReportStep -StepName "Enable-EV" -StepResult "$($return.Status): $($return.message)"

#Grant Policies #Todo better reporting

	Write-UcmLog -Message "Resetting Password" -Severity 1 -Component $function
Set-MsolUserPassword -UserPrincipalName $upn -NewPassword $password -ForceChangePassword $False


	Write-UcmLog -Message "Granting Policies..." -Severity 1 -Component $function
Grant-CsOnlineVoiceRoutingPolicy -Identity $Upn -PolicyName $VoicePolicy
Grant-CsTenantDialplan -Identity $Upn  -PolicyName $Dialplan
Grant-CsTeamsIPPhonePolicy -Identity $Upn -PolicyName 'CAP'
Grant-CsTeamsUpgradePolicy -PolicyName UpgradeToTeams -Identity $Upn
Grant-CsVoiceRoutingPolicy -Identity $upn -PolicyName "InternationalCallsAllowed"

#>

#Output User

Get-CsOnlineUser -Identity $upn| fl Displayname, UsageLocation,ProvisionedPlan,OnPremLineUri,LineUri,MCOValidationError,TenantDialPlan
}

end
{
New-HTMLReportItem -LineTitle "Username" -LineMessage "Last User"
New-HTMLReportStep -StepName "Enable-EV" -StepResult "$($return.Status): $($return.message)"
Export-HTMLReport
}
}