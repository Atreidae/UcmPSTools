$operatorObjectId = (Get-CsOnlineUser PSTN_FWD_61386500932@skype4badmin.onmicrosoft.com).identity
$operatorEntity = New-CsAutoAttendantCallableEntity -Identity $operatorObjectId -Type User

$greetingPrompt = New-CsAutoAttendantPrompt -TextToSpeechPrompt "Welcome to Contoso!"
$defaultCallFlow = New-CsAutoAttendantCallFlow -Name "Default call flow" -Greetings @($greetingPrompt) -Menu $defaultMenu

$afterHoursGreetingPrompt = New-CsAutoAttendantPrompt -TextToSpeechPrompt "Welcome to Contoso! Unfortunately, you have reached us outside of our business hours. We value your call please call us back Monday to Friday, between 9 A.M. to 12 P.M. and 1 P.M. to 5 P.M. Goodbye!"
$automaticMenuOption = New-CsAutoAttendantMenuOption -Action Disconnect -DtmfResponse Automatic
$afterHoursMenu=New-CsAutoAttendantMenu -Name "After Hours menu" -MenuOptions @($automaticMenuOption)
$afterHoursCallFlow = New-CsAutoAttendantCallFlow -Name "After Hours call flow" -Greetings @($afterHoursGreetingPrompt) -Menu $afterHoursMenu

$timerange1 = New-CsOnlineTimeRange -Start 09:00 -end 12:00
$timerange2 = New-CsOnlineTimeRange -Start 13:00 -end 17:00
$afterHoursSchedule = New-CsOnlineSchedule -Name "After Hours Schedule" -WeeklyRecurrentSchedule -MondayHours @($timerange1, $timerange2) -TuesdayHours @($timerange1, $timerange2) -WednesdayHours @($timerange1, $timerange2) -ThursdayHours @($timerange1, $timerange2) -FridayHours @($timerange1, $timerange2) -Complement

$afterHoursCallHandlingAssociation = New-CsAutoAttendantCallHandlingAssociation -Type AfterHours -ScheduleId $afterHoursSchedule.Id -CallFlowId $afterHoursCallFlow.Id

$aa = New-CsAutoAttendant -Name "Main auto attendant" -DefaultCallFlow $defaultCallFlow -CallFlows @($afterHoursCallFlow) -CallHandlingAssociations @($afterHoursCallHandlingAssociation) -LanguageId "en-US" -TimeZoneId "UTC"