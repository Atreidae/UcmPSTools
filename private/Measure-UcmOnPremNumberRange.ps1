#PerformScriptSigning
Function Measure-UcmOnPremNumberRange
{
  <#
      .SYNOPSIS
      A tool to audit Skype for Business Number ranges ready for migration

      .DESCRIPTION
      An Auditing tool, The tool will run through all your PSTN numbers, find number blocks, then report on what objects are in each.

      It will also highlight what it thinks are "weird" number blocks (Blocks with only one number in it, usually caused by a typing error) or optionally, number blocks that don't follow your numbering format. (IE, if you use 10 digit numbers and a 3 digit number is found, it will be highlighted)

      .EXAMPLE
      Measure-UcmOnPremNumberRange -NormalLength 12 -Report

      .PARAMETER NormalLength
      (Optional) Used to check all numbers are this long, will report on any that arent if set

      .PARAMETER Report
      (Optional) Uses the Write-UcmReport functions to generate a HTML and CSV report of the results in the current folder

      .INPUTS
      This function does not accept any inputs

      .REQUIRED FUNCTIONS/MODULES
      Modules
      Lync														(Lync Management Tools)
      or
      SkypeforBusiness								(Skype for Business Management Tools)
      UcmPSTools											(Install-Module UcmPsTools) Includes Cmdlets below.

      Cmdlets
      Write-UcmLog: 									https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-UcmLog.ps1
      Write-HTMLReport: 							https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-HTMLReport.ps1 (optional)

      .REQUIRED PERMISSIONS
      'CSReadOnlyAdministrator' or better

      .LINK
      https://www.UcMadScientist.com
      https://github.com/Atreidae/UcmPSTools


      .NOTES
      Version:		1.0
      Date:			02/03/2022

      .VERSION HISTORY
      1.0: Initial Public Release

  #>

  Param
  (
    [Parameter(Position = 1)] $NormalLength = 0,
    [Parameter(Position = 2)] [bool]$Debuging = $false,
    [Parameter(Position = 3)] [bool]$Report = $false
  )

  #region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
  $function = 'Measure-CsNumberRange'
  [hashtable]$Return = @{}
  $return.Function = $function
  $return.Status = 'Unknown'
  $return.Message = 'Function did not return a status message'

  # Log why we were called
  Write-UcmLog -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
  Write-UcmLog -Message 'Parameters' -Severity 1 -Component $function -LogOnly
  Write-UcmLog -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
  Write-UcmLog -Message 'Parameters Values' -Severity 1 -Component $function -LogOnly
  Write-UcmLog -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
  Write-UcmLog -Message 'Optional Arguments' -Severity 1 -Component $function -LogOnly
  Write-UcmLog -Message "$Args" -Severity 1 -Component $function -LogOnly
  Write-Host '' #Insert a blank line to make reading output easier on loops

  #endregion FunctionSetup

  #region FunctionWork

  Write-UcmLog -Message 'Initializing variables and reports' -Severity 2 -Component $function

  #Global Variables
  [int]$global:100NumberBlocks = 0
  [int]$global:EVwithNoNumber = 0
  [int]$global:OnPremUsersWithoutEV = 0
  [int]$global:OnPremUsersWithEV = 0
  [int]$global:CloudUsersWithoutEV = 0
  [int]$global:CloudUsersWithEV = 0
  [int]$global:CloudRooms = 0
  [int]$global:NumberAndDisabled = 0
  [int]$global:NumberAndNoEV = 0
  [int]$global:IncorrectLength = 0
  [int]$global:ValidNumbers = 0
  [int]$global:BadObjects = 0

  #Declare a new "NumberObject" Class

  Class NumberObject
  {
    [string]$ObjectType
    [string]$SipAddress
    [string]$Identity
    [string]$DisplayName
    [string]$PstnNumber
    [string]$NumberRange
    [bool]$IsWeird = $false
    [string]$WhyWeird
    [string]$Source
  }


  Class NumberBlock
  {
    [String]$Identity
    [String]$Users
    [String]$MeetingRooms
    [String]$AnalogDevices
    [String]$CommonAreaPhones
    [String]$ExchangeUmContacts
    [String]$DialInConferencingAccessNumber
    [String]$TrustedAppEndpoints
    [String]$RgsWorkflow
    [String]$RgsAgents
    [String]$TotalNumbersUsed
  }

  #Now create an empty "Number Hashtable"

  $global:NumberObjects = @()
  $global:NumberBlocks = @()

  #Todo init html report

  If ($report)
  {
    Initialize-UcmReport -Title 'Number Range Audit' -Subtitle 'Existing Number Ranges found in the Skype for Business Environment'
  }

  #Build a hashtable of every number in the platform and store it in a useful format
  Write-UcmLog -Message 'Obtaining Skype User data, this make take some time...' -Severity 2 -Component $function
  Write-Progress -Activity 'Obtaining Skype Enviroment Data' -Status 'Obtain User Data'  -PercentComplete (((1) / 8) * 100)

  If ($Debuging)
  {
    $Userlist = Import-Csv -Path userlist.csv

    Write-Progress -Activity 'Obtaining Skype Enviroment Data' -Status 'Meeting Rooms'  -PercentComplete (((1) / 8) * 100)
    $MeetingRooms = Import-Csv -Path Meetingroom.csv

    Write-Progress -Activity 'Obtaining Skype Enviroment Data'-Status 'Analog Devices'  -PercentComplete (((2) / 8) * 100)
    $AnalogDevices = Import-Csv -Path AnalogDevice.csv

    Write-Progress -Activity 'Obtaining Skype Enviroment Data'-Status 'Common Area Phones'   -PercentComplete (((3) / 8) * 100)
    $CommonAreaPhones = Import-Csv -Path CommonArea.csv

    Write-Progress -Activity 'Obtaining Skype Enviroment Data'-Status 'Exchange UM Endpoints'  -PercentComplete (((4) / 8) * 100)
    $ExchangeUM = Import-Csv -Path Exchange.csv

    Write-Progress -Activity 'Obtaining Skype Enviroment Data'-Status 'Dial In Conferencing Numbers'  -PercentComplete (((5) / 8) * 100)
    $DialInConf = Import-Csv -Path DialinConf.csv

    Write-Progress -Activity 'Obtaining Skype Enviroment Data'-Status 'Trusted App Endpoints'  -PercentComplete (((6) / 8) * 100)
    $TrustedAppEndpoints = Import-Csv -Path TrustedApp.csv

    Write-Progress -Activity 'Obtaining Skype Enviroment Data' -Status 'Response Group Data'  -PercentComplete (((7) / 8) * 100)
    $ResponseGroupWorkflows = Import-Csv -Path RgsWorkflow.csv
    $ResponseGroupAgents = Import-Csv -Path Agents.csv

    Write-UcmLog -Message 'Done.' -Severity 2 -Component $function
  }
  Else
  {
    { $Userlist = Get-CsUser

      Write-Progress -Activity 'Obtaining Skype Enviroment Data' -Status 'Meeting Rooms'  -PercentComplete (((1) / 8) * 100)
      $MeetingRooms = Get-CsMeetingRoom

      Write-Progress -Activity 'Obtaining Skype Enviroment Data'-Status 'Analog Devices'  -PercentComplete (((2) / 8) * 100)
      $AnalogDevices = Get-CsAnalogDevice

      Write-Progress -Activity 'Obtaining Skype Enviroment Data'-Status 'Common Area Phones'   -PercentComplete (((3) / 8) * 100)
      $CommonAreaPhones = Get-CsCommonAreaPhone

      Write-Progress -Activity 'Obtaining Skype Enviroment Data'-Status 'Exchange UM Endpoints'  -PercentComplete (((4) / 8) * 100)
      $ExchangeUM = Get-CsExUmContact

      Write-Progress -Activity 'Obtaining Skype Enviroment Data'-Status 'Dial In Conferencing Numbers'  -PercentComplete (((5) / 8) * 100)
      $DialInConf = Get-CsDialInConferencingAccessNumber

      Write-Progress -Activity 'Obtaining Skype Enviroment Data'-Status 'Trusted App Endpoints'  -PercentComplete (((6) / 8) * 100)
      $TrustedAppEndpoints = Get-CsTrustedApplicationEndpoint

      Write-Progress -Activity 'Obtaining Skype Enviroment Data' -Status 'Response Group Data'  -PercentComplete (((7) / 8) * 100)
      $ResponseGroupWorkflows = Import-Csv -Path RgsWorkflow.csv
      $ResponseGroupAgents = Import-Csv -Path Agents.csv

      Write-UcmLog -Message 'Done.' -Severity 2 -Component $function }
  }

  #region Process Data
  Merge-CsNumberObject -Objects $Userlist -ObjectType 'Users'

  Merge-CsNumberObject -Objects $MeetingRooms -ObjectType 'MeetingRooms'

  Merge-CsNumberObject -Objects $AnalogDevices -ObjectType 'AnalogDevices'

  Merge-CsNumberObject -Objects $CommonAreaPhones -ObjectType 'CommonAreaPhones'

  Merge-CsNumberObject -Objects $ExchangeUM -ObjectType 'ExchangeUmContacts'

  Merge-CsNumberObject -Objects $DialInConf -ObjectType 'DialInConferencingAccessNumber'

  Merge-CsNumberObject -Objects $TrustedAppEndpoints -ObjectType 'TrustedAppEndpoints'

  Merge-CsNumberObject -Objects $ResponseGroupWorkflows -ObjectType 'RgsWorkflow'

  #Merge-CsNumberObject -Objects $ResponseGroupAgents -ObjectType 'RgsAgents' #todo, this is a bit more complex\
  #endregion Process Data

  # Calculate the number of blocks
  $HundredNumberBlocks = ($NumberObjects.PstnNumber -replace '(.*)\d{2}$', '$1' | Select-Object -Unique)
  #Create a Progress Report for the filtering loop
  #Setup progress variables
  $ObjectCount = $HundredNumberBlocks.count
  $CurrentObject = 0
  $maxI = 250
  $StartTime = Get-Date

  Foreach ($HundredNumberBlock in $HundredNumberBlocks) #Numberblock Loop
  {
    Write-UcmLog -Message "Auditing Numberblock $HundredNumberBlock" -Severity 1 -Component $function
    #Capture data for time estimate, we have to do this now as we might exit early.
    if ($CurrentObject -ge 1)
    {
      $ElapsedTime = $(Get-Date) - $StartTime

      #do the ratios and "the math" to compute the Estimated Time Of Completion
      $EstimatedTotalSeconds = $ObjectCount / $CurrentObject * $ElapsedTime.TotalSeconds
      $EstimatedTotalSecondsTS = New-TimeSpan -Seconds $EstimatedTotalSeconds
      $EstimatedCompletionTime = $StartTime + $EstimatedTotalSecondsTS
      $EstimatedTimeLeft = $EstimatedCompletionTime - (Get-Date)
      #Give us a human readable time
      $Eta = ($EstimatedTimeLeft.ToString('mm\:ss'))
    }

    $CurrentObject ++
    Write-Progress -Activity "Processing $NumberRange" -Status "$ObjectType $CurrentObject of $ObjectCount., Remaining Time $ETA / Completion @ $EstimatedCompletionTime" -PercentComplete ((($CurrentObject) / $ObjectCount) * 100)
    Measure-UcmNumberBlock -NumberRange $HundredNumberBlock
  }


  #Report on each of the 100 number blocks



  #Summarize findings
  Write-UcmLog -Message '' -Severity 2 -Component $function
  Write-UcmLog -Message 'Number Check Complete' -Severity 2 -Component $function
  Write-UcmLog -Message 'Summary' -Severity 2 -Component $function
  Write-UcmLog -Message "Processed $($global:NumberObjects.count) Number objects, $ValidNumbers of which appear to be valid phone numbers" -Severity 2 -Component $function
  Write-UcmLog -Message "Located a total of $($HundredNumberBlocks.count) unique number ranges" -Severity 2 -Component $function
  Write-UcmLog -Message "Found $($Userlist.count) users, $($MeetingRooms.count) MeetingRooms, $($AnalogDevices.count) AnalogDevices, $($CommonAreaPhones.count) CommonAreaPhones, $($ExchangeUM.count) ExchangeUmContacts, $($DialInConf.count) DialInConferencingAccessNumbers, $($TrustedAppEndpoints.count) and TrustedAppEndpoints, $($ResponseGroupWorkflows.count) ResponseGroupWorkflows" -Severity 2 -Component $function
  Write-UcmLog -Message "$global:CloudUsersWithoutEV cloud hosted users without EV" -Severity 2 -Component $function
  Write-UcmLog -Message "$global:CloudUsersWithEV cloud hosted users with EV" -Severity 2 -Component $function
  Write-UcmLog -Message '' -Severity 2 -Component $function
  Write-UcmLog -Message 'Cautions' -Severity 2 -Component $function
  Write-UcmLog -Message "Found $global:NumberAndDisabled On-Prem users with a phone number and disabled in Skype/Lync" -Severity 2 -Component $function
  Write-UcmLog -Message "Found $global:NumberAndNoEV On-Prem users with a phone number, but Enterprise Voice is Disabled" -Severity 2 -Component $function
  Write-UcmLog -Message "Found $global:EVwithNoNumber On-Prem users with Enterprise Voice Enabled, but no phone number set" -Severity 2 -Component $function
  Write-UcmLog -Message "Found $global:BadObjects Objects with errors" -Severity 2 -Component $function
  If ($NormalLength -ne 0) { Write-UcmLog -Message "$global:IncorrectLength users with a phone number that is not $NormalLength digits long" -Severity 2 -Component $function }

  if ($Debuging)
  {
    $NumberObjects | Export-Csv -Path NumberObjects.csv -NoTypeInformation
    $NumberObjects | Out-GridView
    $NumberBlocks | Export-Csv -Path NumberBlocks.csv -NoTypeInformation
    $NumberBlocks | Out-GridView
    $NumberBlocks | Format-Table *
  }

}#End of main function


Function Merge-CsNumberObject
{
  Param
  (
    [Parameter(Position = 1)] $Objects,
    [Parameter(Position = 2)] [ValidateSet('Users', 'MeetingRooms', 'AnalogDevices', 'CommonAreaPhones', 'ExchangeUmContacts', 'DialInConferencingAccessNumber', 'TrustedAppEndpoints', 'RgsWorkflow', 'RgsAgents')] $ObjectType
  )
  #check we actually got something
  If ($Objects.count -eq 0)
  {
    Write-UcmLog -Message "No $ObjectType Found, Skipping..." -Severity 2 -Component $function
    Return
  }

  #Create a Progress Report for the filtering loop
  #Setup progress variables
  $ObjectCount = $objects.count
  $CurrentObject = 0
  $maxI = 250
  $StartTime = Get-Date

  Write-UcmLog -Message "Categorizing $ObjectType data..." -Severity 2 -Component $function
  :ObjectFilterLoop Foreach ($Object in $Objects) #Object Loop
  {
    $HumanNumber = $null
    #Capture data for time estimate, we have to do this now as we might exit early.
    if ($CurrentObject -ge 1)
    {
      $ElapsedTime = $(Get-Date) - $StartTime

      #do the ratios and "the math" to compute the Estimated Time Of Completion
      $EstimatedTotalSeconds = $ObjectCount / $CurrentObject * $ElapsedTime.TotalSeconds
      $EstimatedTotalSecondsTS = New-TimeSpan -Seconds $EstimatedTotalSeconds
      $EstimatedCompletionTime = $StartTime + $EstimatedTotalSecondsTS
      $EstimatedTimeLeft = $EstimatedCompletionTime - (Get-Date)
      #Give us a human readable time
      $Eta = ($EstimatedTimeLeft.ToString('mm\:ss'))
    }

    $CurrentObject ++
    Write-Progress -Activity "Processing $ObjectType" -Status "$ObjectType $CurrentObject of $ObjectCount., Remaining Time $ETA / Completion @ $EstimatedCompletionTime" -PercentComplete ((($CurrentObject) / $ObjectCount) * 100)
    #User Specific Code
    If ($ObjectType -eq 'Users')
    {
      if ($Object.HostingProvider -ne 'SRV:')
      {
        #Check to see if object is actually is in SFBO/Teams,
        if ($Object.HostingProvider -ne 'sipfed.online.lync.com')
        {
          $global:BadObjects ++
          Write-UcmLog -Message "Object $($Object.SipAddress) has an invalid Hosting Provider! is '$($Object.HostingProvider)' Should be 'SRV:' for OnPrem and 'sipfed.online.lync.com' for Cloud Hosted. Skipping Object!" -Severity 3 -Component $function
          Continue ObjectFilterLoop #Breaks out of Filter Loop
        }
        #object is in SFBO/Teams, check their number
        If (($Object.Lineuri -eq '') -and ($Object.PrivateLine -eq ''))
        {
          $global:CloudUsersWithoutEV ++
          $global:NumberObjects += [NumberObject]@{ SipAddress = $Object.SipAddress; Identity = $Object.Identity; DisplayName = $Object.DisplayName; PstnNumber = "$null" ; NumberRange = "$null"; IsWeird = $false ; WhyWeird = ''; Source = 'Get-CsUser'; ObjectType = $ObjectType }
          Continue ObjectFilterLoop #Breaks out of Filter Loop
        }
        else
        {
          #We have a number, Covert to a human readable format
          $HumanNumber = $Object.Lineuri.replace('tel:+', '')
          $HumanNumber = ($HumanNumber -Split (';'))[0]
          $global:CloudUsersWithEV ++
          $global:NumberObjects += [NumberObject]@{ SipAddress = $Object.SipAddress; Identity = $Object.Identity; DisplayName = $Object.DisplayName; PstnNumber = $humannumber ; NumberRange = ($humannumber.Substring(0, $humannumber.length - 2)) ; IsWeird = $False ; WhyWeird = ''; Source = 'Get-CsUser' ; ObjectType = $ObjectType }
          Continue ObjectFilterLoop #Breaks out of Filter Loop
        }
      }
    }
    else
    {
      #Do nothing, we will handle it below.
    }

    #check to see if we actually have a number
    If ($Object.Lineuri -eq '')
    {
      #Object doesnt have a number, check to see if it has EV
      If ($Object.EnterpriseVoiceEnabled -eq $true)
      {
        $global:NumberObjects += [NumberObject]@{ SipAddress = $Object.SipAddress; Identity = $Object.Identity; DisplayName = $Object.DisplayName; PstnNumber = "$null" ; NumberRange =  "$null"; IsWeird = $true ; WhyWeird = "$Object with no number but EV"; ObjectType = $ObjectType }
        Write-UcmLog -Message "$ObjectType $($Object.Sipaddress) is an on-prem user without a number, but an EV licence. Either remove the EV licence or assign a number" -Severity 3 -Component $function
        $global:BadObjects ++
        Continue ObjectFilterLoop #Breaks out of Filter Loop
      }
      else #On-prem object without a number or EV
      {
        $global:NumberObjects += [NumberObject]@{ SipAddress = $Object.SipAddress; Identity = $Object.Identity; DisplayName = $Object.DisplayName; PstnNumber = "$null" ; NumberRange =  "$null"; IsWeird = $false ; WhyWeird = ''; ObjectType = $ObjectType }
        $global:OnPremUsersWithoutEV ++
        Continue ObjectFilterLoop #Breaks out of Filter Loop
      }
    }


    #We have a number, Covert to a human readable format
    $HumanNumber = $Object.Lineuri.replace('tel:+', '')
    $HumanNumber = ($HumanNumber -Split (';'))[0]

    #check for PrimaryURI (Used in RGS and Dialin Conf)
    If ($Object.PrimaryUri)
    {
      $Object | Add-Member -NotePropertyName SipAddress -NotePropertyValue $Object.PrimaryUri
    }
    #todo, deal with Private line!

    #Okay, check to see if the object is Disabled, or Not Ev Licenced.
    if ($ObjectType -eq 'Users' -or $ObjectType -eq 'MeetingRooms' -or $ObjectType -eq 'CommonAreaPhones' -or $ObjectType -eq 'AnalogDevices')
    {
      If ($Object.EnterpriseVoiceEnabled -ne $true)
      {
        $global:NumberObjects += [NumberObject]@{ SipAddress = $Object.SipAddress; Identity = $Object.Identity; DisplayName = $Object.DisplayName; PstnNumber = $humannumber ; NumberRange = ($humannumber.Substring(0, $humannumber.length - 2)); IsWeird = $true ; WhyWeird = 'Object with Number but no EV'; ObjectType = $ObjectType }
        Write-UcmLog -Message "Object $($Object.Sipaddress) has an assigned number, but no EV in S4B. The number $HumanNumber can probably be reclaimed" -Severity 2 -Component $function
        $global:NumberAndNoEV ++
        Continue ObjectFilterLoop #No EV, break out
      }

      If ($Object.Enabled -ne $true)
      {
        $global:NumberObjects += [NumberObject]@{ SipAddress = $Object.SipAddress; Identity = $Object.Identity; DisplayName = $Object.DisplayName; PstnNumber = $humannumber ; NumberRange = ($humannumber.Substring(0, $humannumber.length - 2)); IsWeird = $true ; WhyWeird = 'Disabled Object with Number'; ObjectType = $ObjectType }
        Write-UcmLog -Message "Object $($Object.Sipaddress) has an assigned number, but is disabled in S4B. The number $HumanNumber can probably be reclaimed" -Severity 2 -Component $function
        $global:NumberAndDisabled ++
        Continue ObjectFilterLoop #Not enabled, break out
      }
    }

    #Check Number Length
    If ($NormalLength -ne 0)
    {
      #Check the length of the human readable number
      if ($HumanNumber.Length -ne $NormalLength)
      {
        $global:NumberObjects += [NumberObject]@{ SipAddress = $Object.SipAddress; Identity = $Object.Identity; DisplayName = $Object.DisplayName; PstnNumber = $humannumber ; NumberRange = ($humannumber.Substring(0, $humannumber.length - 2)); IsWeird = $true ; WhyWeird = 'Number Length Inconsistent'; ObjectType = $ObjectType }
        Write-UcmLog -Message "Object $($Object.Sipaddress)'s number $humannumber does not match the specified NormalLength of $normalLength" -Severity 2 -Component $function
        $global:IncorrectLength ++
        Continue ObjectFilterLoop #Object stored, break out
      }
    }

    #Number seems okay, mark it as okay and move on
    $global:NumberObjects += [NumberObject]@{ SipAddress = $Object.SipAddress; Identity = $Object.Identity; DisplayName = $Object.DisplayName; PstnNumber = $humannumber ; NumberRange = ($humannumber.Substring(0, $humannumber.length - 2)); IsWeird = $False ; WhyWeird = ''; ObjectType = $ObjectType }
    $global:ValidNumbers++

  } #End of Object For Each Loop
  #Cleanup Objects to ensure we dont have problems
  $Objects = $null
}


Function Measure-UcmNumberBlock
{
  Param
  (
    [Parameter(Position = 1)] $NumberRange
  )
  #stuff the numberblock full of number objects
 
  $NumberRangeContents =                          ($NumberObjects | where-object -Property NumberRange -eq $NumberRange)

  [string]$Users =                          ($NumberRangeContents | where-object -Property ObjectType -eq 'Users').count
  [string]$MeetingRooms =                   ($NumberRangeContents | where-object -Property ObjectType -eq 'MeetingRooms').count
  [string]$AnalogDevices =                  ($NumberRangeContents | where-object -Property ObjectType -eq 'AnalogDevices').count
  [string]$CommonAreaPhones =               ($NumberRangeContents | where-object -Property ObjectType -eq 'CommonAreaPhones').count
  [string]$ExchangeUmContacts =             ($NumberRangeContents | where-object -Property ObjectType -eq 'ExchangeUmContacts').count
  [string]$DialInConferencingAccessNumber = ($NumberRangeContents | where-object -Property ObjectType -eq 'DialInConferencingAccessNumber').count
  [string]$TrustedAppEndpoints =            ($NumberRangeContents | where-object -Property ObjectType -eq 'TrustedAppEndpoints').count
  [string]$RgsWorkflow =                    ($NumberRangeContents | where-object -Property ObjectType -eq 'RgsWorkflow').count
  [string]$TotalNumbersUsed =               $NumberRangeContents.count


  
  #[NumberObject]$RgsAgents = $NumberRangeContents | where-object -Property ObjectType -eq 'RgsAgents'
  #Now put it into numberblocks
  $global:NumberBlocks += [NumberBlock]@{Identity = $NumberRange; Users = $Users; MeetingRooms = $MeetingRooms; AnalogDevices = $AnalogDevices ; CommonAreaPhones = $CommonAreaPhones ; ExchangeUmContacts = $ExchangeUmContacts ; DialInConferencingAccessNumber = $DialInConferencingAccessNumber; TrustedAppEndpoints = $TrustedAppEndpoints ; RgsWorkflow = $RgsWorkflow; TotalNumbersUsed = $TotalNumbersUsed}

  #Old way trying to cast the whole object for deeper diving, mybe we make a new function for auditing? this is just measuring after all
  <#
  [NumberObject]$Users =                          ($NumberRangeContents | where-object -Property ObjectType -eq 'Users')
  [NumberObject]$MeetingRooms =                   ($NumberRangeContents | where-object -Property ObjectType -eq 'MeetingRooms')
  [NumberObject]$AnalogDevices =                  ($NumberRangeContents | where-object -Property ObjectType -eq 'AnalogDevices')
  [NumberObject]$CommonAreaPhones =               ($NumberRangeContents | where-object -Property ObjectType -eq 'CommonAreaPhones')
  [NumberObject]$ExchangeUmContacts =             ($NumberRangeContents | where-object -Property ObjectType -eq 'ExchangeUmContacts')
  [NumberObject]$DialInConferencingAccessNumber = ($NumberRangeContents | where-object -Property ObjectType -eq 'DialInConferencingAccessNumber')
  [NumberObject]$TrustedAppEndpoints =            ($NumberRangeContents | where-object -Property ObjectType -eq 'TrustedAppEndpoints')
  [NumberObject]$RgsWorkflow =                    ($NumberRangeContents | where-object -Property ObjectType -eq 'RgsWorkflow')
  #[NumberObject]$RgsAgents = $NumberRangeContents | where-object -Property ObjectType -eq 'RgsAgents'
  #>
}