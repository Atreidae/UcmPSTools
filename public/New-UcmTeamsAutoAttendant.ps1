Function New-UcmTeamsAutoAttendant
{
	<#
			.SYNOPSIS
			Creates a new Microsoft Teams Auto Attendant and associatated Call Queue with default settings

			.DESCRIPTION
			This function creates a new Auto Attendant and associated Call Queue with default settings
			The Call Queue is created first, with

			.EXAMPLE
			New-Office365User -UPN calebs@contoso.onmicrosoft.com -Password "Passw0rd1!" -FirstName Caleb -LastName Sills -Country US -DisplayName "Caleb Sills"

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
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1)] $AAUPN, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2)] $CCUPN,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=3)] $LineUri,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=4)] $DisplayName,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=5)] $Language,
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=6)] $TimeZoneID
	)

#CallQueue


$Queue = (New-CsCallQueue -Name "$DisplayName" -UseDefaultMusicOnHold $true -AllowOptOut $true -ConferenceMode $true)


#$Queue = (New-CsCallQueue -Name "PowerShellTest2" -UseDefaultMusicOnHold $true -AllowOptOut $true -ConferenceMode $true)
$applicationInstanceId = (Get-CsOnlineUser $CCUPN).ObjectId 
New-CsOnlineApplicationInstanceAssociation -Identities @($applicationInstanceId) -ConfigurationId $Queue.identity -ConfigurationType CallQueue
Get-CsCallQueue -Identity $Queue.identity





## AutoAttendant
$telephoneNumber = ($LineUri).TrimStart("tel:")
Set-CsOnlineApplicationInstance -Identity $AAUPN -OnpremPhoneNumber $telephoneNumber



$CallQueueEntity = New-CsAutoAttendantCallableEntity -Identity $applicationInstanceId -Type ApplicationEndpoint

$dcfGreetingPrompt = New-CsAutoAttendantPrompt -TextToSpeechPrompt "Welcome to Contoso!"
$defaultMenuOption = New-CsAutoAttendantMenuOption -Action TransferCallToTarget -CallTarget $CallQueueEntity -DtmfResponse Automatic 
$defaultMenu=New-CsAutoAttendantMenu -Name "$DisplayName Menu" -MenuOptions @($defaultMenuOption)
$defaultCallFlow = New-CsAutoAttendantCallFlow -Name "$DisplayName call flow" -Greetings @($dcfGreetingPrompt) -Menu $defaultMenu

$afterHoursGreetingPrompt = New-CsAutoAttendantPrompt -TextToSpeechPrompt "Welcome to Contoso! Unfortunately, you have reached us outside of our business hours. We value your call please call us back Monday to Friday, between 9 A.M. and 5 P.M. Goodbye!"
$afterHoursMenuOption = New-CsAutoAttendantMenuOption -Action DisconnectCall -DtmfResponse Automatic 
$afterHoursMenu=New-CsAutoAttendantMenu -Name "After Hours menu" -MenuOptions @($afterHoursMenuOption)
$afterHoursCallFlow = New-CsAutoAttendantCallFlow -Name "After Hours call flow" -Greetings @($afterHoursGreetingPrompt) -Menu $afterHoursMenu

$timerange1 = New-CsOnlineTimeRange -Start 09:00 -end 17:00
$afterHoursSchedule = New-CsOnlineSchedule -Name "After Hours Schedule" -WeeklyRecurrentSchedule -MondayHours @($timerange1) -TuesdayHours @($timerange1) -WednesdayHours @($timerange1) -ThursdayHours @($timerange1) -FridayHours @($timerange1) -Complement

$afterHoursCallHandlingAssociation = New-CsAutoAttendantCallHandlingAssociation -Type AfterHours -ScheduleId $afterHoursSchedule.Id -CallFlowId $afterHoursCallFlow.Id


$o=New-CsAutoAttendant -Name $DisplayName -DefaultCallFlow $defaultCallFlow  -CallFlows @($afterHoursCallFlow) -CallHandlingAssociations @($afterHoursCallHandlingAssociation) -Language "en-AU" -TimeZoneId "AUS Eastern Standard Time" 



$applicationInstanceId = (Get-CsOnlineUser $AAUPN).ObjectId 
New-CsOnlineApplicationInstanceAssociation -Identities @($applicationInstanceId) -ConfigurationId $O.identity -ConfigurationType AutoAttendant
Get-csAutoAttendant -Identity $o.identity

}