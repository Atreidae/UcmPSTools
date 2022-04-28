#PerformScriptSigning
Function Measure-CsNumberRanges
{
  <#
      .SYNOPSIS
      A tool to audit Skype for Business Number ranges ready for migration

      .DESCRIPTION
      An Auditing tool, The tool will run through all your PSTN numbers, find number blocks, then report on what objects are in each.

      It will also highlight what it thinks are "weird" number blocks (Blocks with only one number in it, usually caused by a typing error) or optionally, number blocks that don't follow your numbering format. (IE, if you use 10 digit numbers and a 3 digit number is found, it will be highlighted)

      .EXAMPLE
      Measure-CsNumberRanges -NormalLength  -AAUPN T-AA-emergency@contoso.onmicrosoft.com -CCUPN T-CC-emergency@contoso.onmicrosoft.com -FirstName Caleb -LastName Sills -Country US -DisplayName "Caleb Sills"

      .PARAMETER NormalLength
      (Optional) Used to check all numbers are this long, will report on any that arent if set

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
    [Parameter(Position=1)] $NormalLength=0
  )

  #region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
  $function = 'Measure-CsNumberRanges'
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

  Write-UcmLog -Message "Initializing variables and reports" -Severity 2 -Component $function

  #Global Variables
  [int]$global:EVwithNoNumber = 0
  [int]$global:CloudUsers = 0 
  [int]$global:CloudRooms = 0 
  [int]$global:NumberAndDisabled = 0
  [int]$global:NumberAndNoEV = 0
  [int]$global:IncorrectLength = 0
  [int]$global:ValidNumbers= 0


  
  #Declare a new "NumberObject" Class

  Class NumberObject {
    [string]$SipAddress
    [string]$Identity
    [string]$DisplayName
    [string]$PstnNumber
    [string]$NumberRange
    [bool]$IsWeird = $false
    [string]$WhyWeird
    [string]$Source;
  }

  #Now create an empty "Number Hashtable"

  $global:NumberObjects=@()
  #Todo init html report



  #Build a hashtable of every number in the platform and store it in a useful format

  Write-UcmLog -Message "Obtaining Skype User data, this make take some time..." -Severity 2 -Component $function
  Write-Progress -Activity "Obtaining Skype Enviroment Data" -status "Obtain User Data"  -PercentComplete (((1)/8) * 100)

  #Todo - Real Data
  #$Userlist = (get-csuser)
  $Userlist = Import-Csv -Path userlist.csv
  
  Write-Progress -Activity "Obtaining Skype Enviroment Data" -status "Meeting Rooms"  -PercentComplete (((1)/8) * 100)
  $MeetingRooms = Import-Csv -Path Meetingroom.csv
  
  Write-Progress -Activity "Obtaining Skype Enviroment Data"-status "Analog Devices"  -PercentComplete (((2)/8) * 100)
  $AnalogDevices = Import-Csv -Path AnalogDevice.csv
  
  Write-Progress -Activity "Obtaining Skype Enviroment Data"-status "Common Area Phones"   -PercentComplete (((3)/8) * 100)
  $CommonAreaPhones = Import-Csv -Path CommonArea.csv
  
  Write-Progress -Activity "Obtaining Skype Enviroment Data"-status "Exchange UM Endpoints"  -PercentComplete (((4)/8) * 100)
  $ExchangeUM = Import-Csv -Path Exchange.csv
  
  Write-Progress -Activity "Obtaining Skype Enviroment Data"-status "Dial In Conferencing Numbers"  -PercentComplete (((5)/8) * 100)
  $DialInConf = Import-Csv -Path DialinConf.csv
  
  Write-Progress -Activity "Obtaining Skype Enviroment Data"-status "Trusted App Endpoints"  -PercentComplete (((6)/8) * 100)
  $TrustedAppEndpoints = Import-Csv -Path TrustedApp.csv
  
  Write-Progress -Activity "Obtaining Skype Enviroment Data" -status "Response Group Data"  -PercentComplete (((7)/8) * 100)
  $ResponseGroupWorkflows = Import-Csv -Path RgsWorkflow.csv
  $ResponseGroupAgents = Import-Csv -Path Agents.csv

  Write-UcmLog -Message "Done." -Severity 2 -Component $function


  #Assume we have at least one user, collect their data
  Merge-CsUserNumbers
  
  #region MeetingRooms
  $Roomcount = ($MeetingRooms.count)
  If ($Roomcount -ne 0) 
  { 
    #todo Merge-CsRoomNumbers
  } 
  Else
  {
    Write-UcmLog -Message "No Meeting Rooms Found, Skipping..." -Severity 2 -Component $function
  }
  #endregion MeetingRooms
  
  #region AnalogDevices
  $Analogcount = ($AnalogDevices.count)
  If ($Analogcount -ne 0)
  { 
    #todo Merge-CsAnalogNumbers
  } 
  Else 
  {
    Write-UcmLog -Message "No Analog Devices Found, Skipping..." -Severity 2 -Component $function
  }
  #endregion AnalogDevices
  
  #region CommonAreaPhones
  $CAPcount = ($CommonAreaPhones.count)
  If ($CAPcount -ne 0)
  { 
    #todo Merge-CsCommonAreaNumbers
  } 
  Else 
  {
    Write-UcmLog -Message "No Common Area Phones Found, Skipping..." -Severity 2 -Component $function
  }
  
  #endregion CommonAreaPhones
  
  
  #region Exchange
  
  #endregion Exchange
  
  
  #region Dialin
  
  
  #endregion Dialin
  
  
  #region TrustedApps
  
  
  #endregion TrustedApps
  
  
  #region ResponseGroupWorkflows
  
  
  #endregion ResponseGroupWorkflows
  
  
  
  
  
  
  
  
  Write-UcmLog -Message "Number Check Complete" -Severity 2 -Component $function
  Write-UcmLog -Message "$global:UserCount users total" -Severity 2 -Component $function
  Write-UcmLog -Message "$global:CloudUsers cloud hosted users (ignored)" -Severity 2 -Component $function
  Write-UcmLog -Message "$global:NumberAndDisabled Users with a phone number and disabled in Skype" -Severity 2 -Component $function
  Write-UcmLog -Message "$global:NumberAndNoEV users with a phone number, but Enterprise Voice is Disabled" -Severity 2 -Component $function
  Write-UcmLog -Message "$global:EVwithNoNumber users with Enterprise Voice Enabled, but no phone number set" -Severity 2 -Component $function
  If ($NormalLength -ne 0)  {Write-UcmLog -Message "$global:IncorrectLength users with a phone number that is not $NormalLength digits long" -Severity 2 -Component $function}
  Write-UcmLog -Message "Leaving $global:ValidNumbers users to check" -Severity 2 -Component $function

  Write-UcmLog -Message "Processed $($global:NumberObjects.count) Number objects" -Severity 2 -Component $function
  }#End of main function


Function Merge-CsUserNumbers
{
  #region users
  #Create a Progress Report for the filtering loop
  #Setup progress variables
  $global:UserCount = ($userlist.count)
  $currentuser = 0
  $maxI = 250 
  $startTime = get-date 
  
  

  Write-UcmLog -Message "Categorizing User data..." -Severity 2 -Component $function
  :UserFilterLoop Foreach ($user in $Userlist) #Filter Loop
  {
    $HumanNumber = $null
        
    #Capture data for time estimate, we have to do this now as we might exit early.
    if ($currentuser -ge 1)
    {
      $elapsedTime = $(get-date) - $startTime 

      #do the ratios and "the math" to compute the Estimated Time Of Completion 
      $estimatedTotalSeconds = $global:UserCount / $currentuser * $elapsedTime.TotalSeconds 
      $estimatedTotalSecondsTS = New-TimeSpan -seconds $estimatedTotalSeconds
      $estimatedCompletionTime = $startTime + $estimatedTotalSecondsTS
      #Give us a human readable time
      $eta = ($estimatedTotalSecondsTS.ToString("hh\:mm\:ss"))
    }
    
    $currentuser ++
    Write-Progress -Activity "Filtering Users" -Status "User $currentuser of $global:UserCount., ETA: $eta / @ $estimatedCompletionTime" -CurrentOperation Step1 -PercentComplete ((($currentuser) / $global:UserCount) * 100)
    #First things first, ignore any cloud users
    if ($user.HostingProvider -ne "SRV:")
    { 
      $global:CloudUsers ++
      Continue UserFilterLoop #Breaks out of Filter Loop
      Throw "This code should never run! - Cloud User Breakout"
    }

    #check to see if we actually have a number
    If (($user.Lineuri -eq "") -and ($user.PrivateLine -eq ""))
    {
      #User doesnt have a number, check to see if they have EV
      If ($User.EnterpriseVoiceEnabled -eq $true)
      {
        $global:NumberObjects += [NumberObject]@{ SipAddress = $User.SipAddress; Identity = $User.Identity; DisplayName = $User.DisplayName; PstnNumber= "$null" ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "EV User with no number"; Source = "Get-CsUser" }
        Write-UcmLog -Message "User $($User.Sipaddress) is licenced for EV with no number, this is unsupported in Teams" -Severity 1 -Component $function
        $global:EVwithNoNumber ++
      }
      Continue UserFilterLoop #No number, break out
    }

    #We have a number, Covert to a human readable format

    #Remove the prefix and suffix
    $HumanNumber = $User.Lineuri.replace('tel:+','')
    $HumanNumber = ($HumanNumber -Split (';'))[0]
    
    #todo, deal with Private line!
    
    #We have a number, check to see if the user is Disabled, or Not Ev Licenced.
    If ($User.EnterpriseVoiceEnabled -ne $true)
    {
      $global:NumberObjects += [NumberObject]@{ SipAddress = $User.SipAddress; Identity = $User.Identity; DisplayName = $User.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "User with Number but no EV"; Source = "Get-CsUser" }
      Write-UcmLog -Message "User $($User.Sipaddress) has an assigned number, but no EV in S4B. This number can be reclaimed" -Severity 1 -Component $function
      $global:NumberAndNoEV ++
      Continue UserFilterLoop #No EV, break out
    }
      
   
    If ($User.Enabled -ne $true)
    {
      $global:NumberObjects += [NumberObject]@{ SipAddress = $User.SipAddress; Identity = $User.Identity; DisplayName = $User.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "Disabled User with Number"; Source = "Get-CsUser" }
      Write-UcmLog -Message "User $($User.Sipaddress) has an assigned number, but is disabled in S4B. This number can be reclaimed" -Severity 1 -Component $function
      $global:NumberAndDisabled ++
      Continue UserFilterLoop #Not enabled, break out
    }
    
    #Check Length
    If ($NormalLength -ne 0)
    {
      #check the length of the human readable number
      if ($HumanNumber.Length -ne $NormalLength)
      {
        $global:NumberObjects += [NumberObject]@{ SipAddress = $User.SipAddress; Identity = $User.Identity; DisplayName = $User.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "Number Length Inconsistent"; Source = "Get-CsUser" }
        Write-UcmLog -Message "User $($User.Sipaddress)'s number does not match the specified NormalLength" -Severity 1 -Component $function
        $global:IncorrectLength ++
        Continue UserFilterLoop #Not enabled, break out
      }
    }
    
    #Number seems okay, mark it as okay and move on
    $global:NumberObjects += [NumberObject]@{ SipAddress = $User.SipAddress; Identity = $User.Identity; DisplayName = $User.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $False ; WhyWeird = ""; Source = "Get-CsUser" }
    $global:ValidNumbers++

  } #End of User Filter Loop
  
  $TotalUserCount = $users.count


  #endregion users
}

Function Merge-CsRoomNumbers
{

  Write-UcmLog -Message "Categorizing Meeting Room data..." -Severity 2 -Component $function
  #Create a Progress Report for the filtering loop
  #Setup progress variables
  
  $currentroom = 0
  $maxI = 250 
  $startTime = get-date 
    
  :MeetingRoomFilterLoop Foreach ($MeetingRoom in $MeetingRooms) #Filter Loop
  {
    $HumanNumber = $null
        
    #Capture data for time estimate, we have to do this now as we might exit early.
    if ($currentroom -ge 1)
    {
      $elapsedTime = $(get-date) - $startTime 

      #do the ratios and "the math" to compute the Estimated Time Of Completion 
      $estimatedTotalSeconds = $Roomcount / $currentroom * $elapsedTime.TotalSeconds 
      $estimatedTotalSecondsTS = New-TimeSpan -seconds $estimatedTotalSeconds
      $estimatedCompletionTime = $startTime + $estimatedTotalSecondsTS
      #Give us a human readable time
      $eta = ($estimatedTotalSecondsTS.ToString("hh\:mm\:ss"))
    }
    
    $currentroom ++
    Write-Progress -Activity "Filtering Meeting Rooms" -Status "Room $currentroom of $roomcount., ETA: $eta / @ $estimatedCompletionTime" -CurrentOperation Step1 -PercentComplete ((($currentroom) / $roomcount) * 100)
    #First things first, ignore any cloud users
    if ($meetingroom.HostingProvider -ne "SRV:")
    { 
      $global:CloudRooms ++
      Continue MeetingRoomFilterLoop #Breaks out of Filter Loop
    }

    #check to see if we actually have a number
    If ($meetingroom.Lineuri -eq "")
    {
      #Room doesnt have a number, check to see if it has EV
      If ($meetingroom.EnterpriseVoiceEnabled -eq $true)
      {
        $global:NumberObjects += [NumberObject]@{ SipAddress = $meetingroom.SipAddress; Identity = $meetingroom.Identity; DisplayName = $meetingroom.DisplayName; PstnNumber= "$null" ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "EV Meeting Room with no number"; Source = "Get-CsMeetingRoom" }
        Write-UcmLog -Message "Meeting Room $($meetingroom.Sipaddress) is licenced for EV with no number, this is unsupported in Teams" -Severity 1 -Component $function
        $global:EVwithNoNumber ++
      }
      Continue MeetingRoomFilterLoop #No number, break out
    }

    #We have a number, Covert to a human readable format

    #Remove the prefix and suffix
    $HumanNumber = $meetingroom.Lineuri.replace('tel:+','')
    $HumanNumber = ($HumanNumber -Split (';'))[0]
       
    #We have a number, check to see if the room is Disabled, or Not Ev Licenced.
    If ($meetingroom.EnterpriseVoiceEnabled -ne $true)
    {
      $global:NumberObjects += [NumberObject]@{ SipAddress = $meetingroom.SipAddress; Identity = $meetingroom.Identity; DisplayName = $meetingroom.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "Meeting Room with Number but no EV"; Source = "Get-CsMeetingRoom" }
      Write-UcmLog -Message "Meeting Room $($meetingroom.Sipaddress) has an assigned number, but no EV in S4B. This number can be reclaimed" -Severity 1 -Component $function
      $global:NumberAndNoEV ++
      Continue MeetingRoomFilterLoop #No EV, break out
    }
      
   
    If ($meetingroom.Enabled -ne $true)
    {
      $global:NumberObjects += [NumberObject]@{ SipAddress = $meetingroom.SipAddress; Identity = $meetingroom.Identity; DisplayName = $meetingroom.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "Disabled Meeting Room with Number"; Source = "Get-CsMeetingRoom" }
      Write-UcmLog -Message "Meeting Room $($meetingroom.Sipaddress) has an assigned number, but is disabled in S4B. This number can be reclaimed" -Severity 1 -Component $function
      $global:NumberAndDisabled ++
      Continue MeetingRoomFilterLoop #Not enabled, break out
    }
    
    #Check Length
    If ($NormalLength -ne 0)
    {
      #check the length of the human readable number
      if ($HumanNumber.Length -ne $NormalLength)
      {
        $global:NumberObjects += [NumberObject]@{ SipAddress = $meetingroom.SipAddress; Identity = $meetingroom.Identity; DisplayName = $meetingroom.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "Number Length Inconsistent"; Source = "Get-CsMeetingRoom" }
        Write-UcmLog -Message "Meeting Room $($meetingroom.Sipaddress)'s number does not match the specified NormalLength" -Severity 1 -Component $function
        $global:IncorrectLength ++
        Continue MeetingRoomFilterLoop #Not enabled, break out
      }
    }
    
    #Number seems okay, mark it as okay and move on
    $global:NumberObjects += [NumberObject]@{ SipAddress = $meetingroom.SipAddress; Identity = $meetingroom.Identity; DisplayName = $meetingroom.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $False ; WhyWeird = ""; Source = "Get-CsMeetingRoom" }
    $global:ValidNumbers++

  } #End of Meeting room Filter Loop
}

Function Merge-CsAnalogNumbers
{
Write-UcmLog -Message "Categorizing Analog Device data..." -Severity 2 -Component $function
    #Create a Progress Report for the filtering loop
    $currentanalog = 0
    $maxI = 250 
    $startTime = get-date 
    
    :AnalogFilterLoop Foreach ($AnalogDevice in $AnalogDevices) #Filter Loop
    {
      $HumanNumber = $null
        
      #Capture data for time estimate, we have to do this now as we might exit early.
      if ($currentanalog -ge 1)
      {
        $elapsedTime = $(get-date) - $startTime 

        #do the ratios and "the math" to compute the Estimated Time Of Completion 
        $estimatedTotalSeconds = $Analogcount / $currentanalog * $elapsedTime.TotalSeconds 
        $estimatedTotalSecondsTS = New-TimeSpan -seconds $estimatedTotalSeconds
        $estimatedCompletionTime = $startTime + $estimatedTotalSecondsTS
        #Give us a human readable time
        $eta = ($estimatedTotalSecondsTS.ToString("hh\:mm\:ss"))
      }
    
      $currentanalog ++
      Write-Progress -Activity "Filtering Analog Devices" -Status "Analog Device $currentanalog of $Analogcount., ETA: $eta / @ $estimatedCompletionTime" -CurrentOperation Step1 -PercentComplete ((($currentanalog) / $Analogcount) * 100)
      #First things first, ignore any cloud users
      if ($AnalogDevice.HostingProvider -ne "SRV:")
      { 
        Write-UcmLog -Message "Analog Device deployment locator doesnt match SRV: - Unsupported device! Skipping!" -Severity 4 -Component $function
        Continue AnalogFilterLoop #Breaks out of Filter Loop
      }

      #check to see if we actually have a number
      If ($AnalogDevice.Lineuri -eq "")
      {
        #Analog Device doesnt have a number, check to see if it has EV
        If ($AnalogDevice.EnterpriseVoiceEnabled -eq $true)
        {
          $global:NumberObjects += [NumberObject]@{ SipAddress = $AnalogDevice.SipAddress; Identity = $AnalogDevice.Identity; DisplayName = $AnalogDevice.DisplayName; PstnNumber= "$null" ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "Analog Device with no number"; Source = "Get-CsAnalogDevice" }
          Write-UcmLog -Message "Analog Device $($AnalogDevice.Sipaddress) is licenced for EV with no number, this shouldnt even be possible" -Severity 4 -Component $function
          $global:EVwithNoNumber ++
        }
        Continue AnalogFilterLoop #No number, break out
      }

      #We have a number, Covert to a human readable format

      #Remove the prefix and suffix
      $HumanNumber = $AnalogDevice.Lineuri.replace('tel:+','')
      $HumanNumber = ($HumanNumber -Split (';'))[0]
       
      #We have a number, check to see if the Analog Device is Disabled, or Not Ev Licenced.  #todo, is this even possible?
      If ($AnalogDevice.EnterpriseVoiceEnabled -ne $true)
      {
        $global:NumberObjects += [NumberObject]@{ SipAddress = $AnalogDevice.SipAddress; Identity = $AnalogDevice.Identity; DisplayName = $AnalogDevice.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "Analog Device with Number but no EV"; Source = "Get-CsAnalogDevice" }
        Write-UcmLog -Message "Analog Device $($AnalogDevice.Sipaddress) has an assigned number, but no EV in S4B. This number can be reclaimed" -Severity 1 -Component $function
        $global:NumberAndNoEV ++
        Continue AnalogFilterLoop #No EV, break out
      }
      
   
      If ($AnalogDevice.Enabled -ne $true)
      {
        $global:NumberObjects += [NumberObject]@{ SipAddress = $AnalogDevice.SipAddress; Identity = $AnalogDevice.Identity; DisplayName = $AnalogDevice.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "Disabled Analog Device with Number"; Source = "Get-CsAnalogDevice" }
        Write-UcmLog -Message "Analog Device $($AnalogDevice.Sipaddress) has an assigned number, but is disabled in S4B. This number can be reclaimed" -Severity 1 -Component $function
        $global:NumberAndDisabled ++
        Continue AnalogFilterLoop #Not enabled, break out
      }
    
      #Check Length
      If ($NormalLength -ne 0)
      {
        #check the length of the human readable number
        if ($HumanNumber.Length -ne $NormalLength)
        {
          $global:NumberObjects += [NumberObject]@{ SipAddress = $AnalogDevice.SipAddress; Identity = $AnalogDevice.Identity; DisplayName = $AnalogDevice.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "Number Length Inconsistent"; Source = "Get-CsAnalogDevice" }
          Write-UcmLog -Message "Analog Device $($AnalogDevice.Sipaddress)'s number does not match the specified NormalLength" -Severity 1 -Component $function
          $global:IncorrectLength ++
          Continue AnalogFilterLoop #Not enabled, break out
        }
      }
    
      #Number seems okay, mark it as okay and move on
      $global:NumberObjects += [NumberObject]@{ SipAddress = $AnalogDevice.SipAddress; Identity = $AnalogDevice.Identity; DisplayName = $AnalogDevice.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $False ; WhyWeird = ""; Source = "Get-CsAnalogDevice" }
      $global:ValidNumbers++

    } #End of Meeting room Filter Loop
}

Function Merge-CsCommonAreaNumbers
{
Write-UcmLog -Message "Categorizing Common Area Phone data..." -Severity 2 -Component $function
    #Create a Progress Report for the filtering loop
    $currentcap = 0
    $maxI = 250 
    $startTime = get-date 
    
    :CAPFilterLoop Foreach ($CommonAreaPhone in $CommonAreaPhones) #Filter Loop
    {
      $HumanNumber = $null
        
      #Capture data for time estimate, we have to do this now as we might exit early.
      if ($currentcap -ge 1)
      {
        $elapsedTime = $(get-date) - $startTime 

        #do the ratios and "the math" to compute the Estimated Time Of Completion 
        $estimatedTotalSeconds = $capcount / $currentcap * $elapsedTime.TotalSeconds 
        $estimatedTotalSecondsTS = New-TimeSpan -seconds $estimatedTotalSeconds
        $estimatedCompletionTime = $startTime + $estimatedTotalSecondsTS
        #Give us a human readable time
        $eta = ($estimatedTotalSecondsTS.ToString("hh\:mm\:ss"))
      }
    
      $currentcap ++
      Write-Progress -Activity "Filtering Analog Devices" -Status "Common Area Phone $currentcap of $capcount., ETA: $eta / @ $estimatedCompletionTime" -CurrentOperation Step1 -PercentComplete ((($currentcap) / $capcount) * 100)
      #First things first, ignore any cloud users
      if ($CommonAreaPhone.HostingProvider -ne "SRV:")
      { 
        Write-UcmLog -Message "Common Area Phone deployment locator doesnt match SRV: - Unsupported device! Skipping!" -Severity 4 -Component $function
        Continue CAPFilterLoop #Breaks out of Filter Loop
      }

      #check to see if we actually have a number
      If ($CommonAreaPhone.Lineuri -eq "")
      {
        #Common Area Phone doesnt have a number, check to see if it has EV
        If ($CommonAreaPhone.EnterpriseVoiceEnabled -eq $true)
        {
          $global:NumberObjects += [NumberObject]@{ SipAddress = $CommonAreaPhone.SipAddress; Identity = $CommonAreaPhone.Identity; DisplayName = $CommonAreaPhone.DisplayName; PstnNumber= "$null" ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "Commona Area Phone with no number"; Source = "Get-CsCommonAreaPhone" }
          Write-UcmLog -Message "Common Area Phone $($CommonAreaPhone.Sipaddress) is licenced for EV with no number, this shouldnt even be possible" -Severity 4 -Component $function
          $global:EVwithNoNumber ++
        }
        Continue CAPFilterLoop #No number, break out
      }

      #We have a number, Covert to a human readable format

      #Remove the prefix and suffix
      $HumanNumber = $CommonAreaPhone.Lineuri.replace('tel:+','')
      $HumanNumber = ($HumanNumber -Split (';'))[0]
       
      #We have a number, check to see if the CAP is Disabled, or Not Ev Licenced.  #todo, is this even possible?
      If ($CommonAreaPhone.EnterpriseVoiceEnabled -ne $true)
      {
        $global:NumberObjects += [NumberObject]@{ SipAddress = $CommonAreaPhone.SipAddress; Identity = $CommonAreaPhone.Identity; DisplayName = $CommonAreaPhone.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "Common Area Phone with Number but no EV"; Source = "Get-CsCommonAreaPhone" }
        Write-UcmLog -Message "Common Area Phone $($CommonAreaPhone.Sipaddress) has an assigned number, but no EV in S4B. This number can be reclaimed" -Severity 1 -Component $function
        $global:NumberAndNoEV ++
        Continue CAPFilterLoop #No EV, break out
      }
      
   
      If ($AnalogDevice.Enabled -ne $true)
      {
        $global:NumberObjects += [NumberObject]@{ SipAddress = $CommonAreaPhone.SipAddress; Identity = $CommonAreaPhone.Identity; DisplayName = $CommonAreaPhone.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "Disabled CAP with Number"; Source = "Get-CsCommonAreaPhone" }
        Write-UcmLog -Message "Common Area Phone $($CommonAreaPhone.Sipaddress) has an assigned number, but is disabled in S4B. This number can be reclaimed" -Severity 1 -Component $function
        $global:NumberAndDisabled ++
        Continue CAPFilterLoop #Not enabled, break out
      }
    
      #Check Length
      If ($NormalLength -ne 0)
      {
        #check the length of the human readable number
        if ($HumanNumber.Length -ne $NormalLength)
        {
          $global:NumberObjects += [NumberObject]@{ SipAddress = $CommonAreaPhone.SipAddress; Identity = $CommonAreaPhone.Identity; DisplayName = $CommonAreaPhone.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $true ; WhyWeird = "Number Length Inconsistent"; Source = "Get-CsCommonAreaPhone" }
          Write-UcmLog -Message "Common Area Phone $($CommonAreaPhone.Sipaddress)'s number does not match the specified NormalLength" -Severity 1 -Component $function
          $global:IncorrectLength ++
          Continue CAPFilterLoop #Not enabled, break out
        }
      }
    
      #Number seems okay, mark it as okay and move on
      $global:NumberObjects += [NumberObject]@{ SipAddress = $CommonAreaPhone.SipAddress; Identity = $CommonAreaPhone.Identity; DisplayName = $CommonAreaPhone.DisplayName; PstnNumber= $humannumber ; NumberRange = "$null"; IsWeird = $False ; WhyWeird = ""; Source = "Get-CsCommonAreaPhone" }
      $global:ValidNumbers++

    } #End of Meeting room Filter Loop
}

Function Merge-CsExUmNumbers
{

}

Function Merge-CsDialinConfNumbers
{

}


Function Merge-CsTrustedAppNumbers
{

}


Function Merge-CsRGSNumbers
{

}



<#


    $match = "*618829960*"
    Write-host "Users"
    (get-CsUser -Filter {LineURI -like $match} | Measure).count

    get-CsUser -Filter {LineURI -like $match}

    Write-host "Meeting Rooms"
    (Get-CsMeetingRoom -Filter {LineURI -like $match} | Measure).count


    Write-host "Private Lines"
    (Get-CsUser -Filter {PrivateLine -like $match} | Measure).count

    Write-host "Analog Devices"
    (Get-CsAnalogDevice -Filter {LineURI -like $match} | Measure).count

    Write-host "Checking Common Area Phones"
    (Get-CsCommonAreaPhone -Filter {LineURI -like $match} | Measure).count

    Write-host "Exchange UM"
    (Get-CsExUmContact -Filter {LineURI -like $match} | Measure).count

    Write-host "Checking Dialin Conference Numbers"
    (Get-CsDialInConferencingAccessNumber -Filter {LineURI -like $match} | Measure).count

    Write-host "Checking Trusted Application Endpoints"
    (Get-CsTrustedApplicationEndpoint -Filter {LineURI -like $match}| Measure).count

    Write-host "Checking Response Groups"
    (Get-CsRgsWorkflow | Where-Object {$_.LineURI -like $match} | Measure).count

    ## RGS agent groups.

#>