﻿Function Search-UcmCsLineUri {


  <### Replace with this
  #Find the guid of the match
            $ErrorUserGUID = (Get-CsPhoneNumberAssignment -TelephoneNumber $username.lineuri).AssignedPstnTargetId
            #Now find the user
            $ErrorUser = Get-CsOnlineUser -Identity $ErrorUserGUID

            Write-UcmLog -message "$($ErrorUser.userprincipalname) is already using $($username.lineuri)" -Severity 3
            
            #>

  <#
      .SYNOPSIS
      Checks to see if a DID has already been assigned to an object in a Microsoft Teams deployment and if so returns the result

      .DESCRIPTION
      Checks to see if a DID has already been assigned to an object in a Microsoft Teams deployment and if so returns the result

      .EXAMPLE
      Search-UcmCsLineUri "61386408640"

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
      This function is based heavily off Tom Arbuthnot's Get-LyncNumberAssignment (Which I think might use code from Pat Richard)
      https://github.com/tomarbuthnot/Get-LyncNumberAssignment/blob/master/Get-LyncNumberAssignment-0.5.ps1

      .NOTES
      Version:		1.0
      Date:			15/05/2021

      .VERSION HISTORY
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

  Param  (
    [Parameter(Mandatory, Position=1)] $UriCheck 
  )

  #region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
  $function = 'Search-UcmCsLineUri'
  [hashtable]$Return = @{}
  $return.Function = $function
  $return.Status = "Unknown"
  $return.Message = "Function did not return a status message"

  # Log why we were called
  Write-UcmLog -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
  Write-UcmLog -Message "Parameters" -Severity 3 -Component $function -LogOnly
  Write-UcmLog -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
  Write-UcmLog -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
  Write-UcmLog -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
  Write-UcmLog -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
  Write-UcmLog -Message "$Args" -Severity 1 -Component $function -LogOnly
	
  #endregion FunctionSetup

  #region FunctionWork

  #Copy URI Check into Match
  $match = "*$UriCheck*"

  Write-UcmLog -Message "Checking if $match is a unique number in Skype4B" -Severity 2 -Component $function

  # Define a new object to gather output
  $OutputCollection = @()

  # For Each one we want to output
  # LineURI, Name, supuri, Type (USER/RGS etc)

  Write-UcmLog -Message "Checking Users" -Severity 1 -Component $function
  Get-CsUser -Filter {LineURI -like $match} | ForEach-Object {
    $output           =  New-Object -TypeName PSobject 
    $output | add-member -MemberType NoteProperty -Name 'LineUri' -Value $_.LineURI
    $output | add-member -MemberType NoteProperty -Name 'DisplayName' -Value $_.DisplayName
    $output | add-member -MemberType NoteProperty -Name 'SipUri' -Value $_.SipAddress
    $output | add-member -MemberType NoteProperty -Name 'Type' -Value 'User'
    $output | add-member -MemberType NoteProperty -Name 'RegistrarPool' -Value "$($_.RegistrarPool)"
    $OutputCollection += $output
  }

  Write-UcmLog -Message "Checking User Private Lines" -Severity 1 -Component $function
  Get-CsUser -Filter {PrivateLine -like $match} | ForEach-Object {
    $output           =  New-Object -TypeName PSobject 
    $output | add-member -MemberType NoteProperty -Name 'LineUri' -Value $_.LineURI
    $output | add-member -MemberType NoteProperty -Name 'DisplayName' -Value $_.DisplayName
    $output | add-member -MemberType NoteProperty -Name 'SipUri' -Value $_.SipAddress
    $output | add-member -MemberType NoteProperty -Name 'Type' -Value 'PrivateLineUser'
    $output | add-member -MemberType NoteProperty -Name 'RegistrarPool' -Value "$($_.RegistrarPool)"
    $OutputCollection += $output
  }

  Write-UcmLog -Message "Checking Analog Devices" -Severity 1 -Component $function
  Get-CsAnalogDevice -Filter {LineURI -like $match} | ForEach-Object {
    $output           =  New-Object -TypeName PSobject 
    $output | add-member -MemberType NoteProperty -Name 'LineUri' -Value $_.LineURI
    $output | add-member -MemberType NoteProperty -Name 'DisplayName' -Value $_.DisplayName
    $output | add-member -MemberType NoteProperty -Name 'SipUri' -Value $_.SipAddress
    $output | add-member -MemberType NoteProperty -Name 'Type' -Value 'AnalogDevice'
    $output | add-member -MemberType NoteProperty -Name 'RegistrarPool' -Value "$($_.RegistrarPool)"
    $OutputCollection += $output
  }

  Write-Verbose -Message 'Checking Common Area Phones'
  Get-CsCommonAreaPhone -Filter {LineURI -like $match} | ForEach-Object {
    $output           =  New-Object -TypeName PSobject 
    $output | add-member -MemberType NoteProperty -Name 'LineUri' -Value $_.LineURI
    $output | add-member -MemberType NoteProperty -Name 'DisplayName' -Value $_.DisplayName
    $output | add-member -MemberType NoteProperty -Name 'SipUri' -Value $_.SipAddress
    $output | add-member -MemberType NoteProperty -Name 'Type' -Value 'CommonAreaPhone'
    $output | add-member -MemberType NoteProperty -Name 'RegistrarPool' -Value "$($_.RegistrarPool)"
    $OutputCollection += $output
  }

  Write-UcmLog -Message "Checking Analog Devices" -Severity 1 -Component $function
  Write-Verbose -Message 'Checking Exchange UM Contact Objects'
  Get-CsExUmContact -Filter {LineURI -like $match} | ForEach-Object {
    $output           =  New-Object -TypeName PSobject 
    $output | add-member -MemberType NoteProperty -Name 'LineUri' -Value $_.LineURI
    $output | add-member -MemberType NoteProperty -Name 'DisplayName' -Value $_.DisplayName
    $output | add-member -MemberType NoteProperty -Name 'SipUri' -Value $_.SipAddress
    $output | add-member -MemberType NoteProperty -Name 'Type' -Value 'ExUMContact'
    $output | add-member -MemberType NoteProperty -Name 'RegistrarPool' -Value "$($_.RegistrarPool)"
    $OutputCollection += $output
  }

  Write-UcmLog -Message "Checking Dialin Conference Numbers" -Severity 1 -Component $function
  Get-CsDialInConferencingAccessNumber -Filter {LineURI -like $match} | ForEach-Object {
    $output           =  New-Object -TypeName PSobject 
    $output | add-member -MemberType NoteProperty -Name 'LineUri' -Value $_.LineURI
    $output | add-member -MemberType NoteProperty -Name 'DisplayName' -Value $_.DisplayName
    $output | add-member -MemberType NoteProperty -Name 'SipUri' -Value $_.PrimaryUri
    $output | add-member -MemberType NoteProperty -Name 'Type' -Value 'DialInConf'
    $output | add-member -MemberType NoteProperty -Name 'RegistrarPool' -Value "$($_.Pool)"
    $OutputCollection += $output
  }

  Write-UcmLog -Message "Checking Trusted Application Endpoints" -Severity 1 -Component $function
  Get-CsTrustedApplicationEndpoint -Filter {LineURI -like $match} | ForEach-Object {
    $output           =  New-Object -TypeName PSobject 
    $output | add-member -MemberType NoteProperty -Name 'LineUri' -Value $_.LineURI
    $output | add-member -MemberType NoteProperty -Name 'DisplayName' -Value $_.DisplayName
    $output | add-member -MemberType NoteProperty -Name 'SipUri' -Value $_.SipAddress
    $output | add-member -MemberType NoteProperty -Name 'Type' -Value 'TrustedAppEndPoint'
    $output | add-member -MemberType NoteProperty -Name 'RegistrarPool' -Value "$($_.RegistrarPool)"
    $OutputCollection += $output
  }

  # No filter on Get-CSRGSworkflow
  Write-UcmLog -Message "Checking Response Groups" -Severity 1 -Component $function
  Get-CsRgsWorkflow | Where-Object {$_.LineURI -like $match} | ForEach-Object {
    $output           =  New-Object -TypeName PSobject 
    $output | add-member -MemberType NoteProperty -Name 'LineUri' -Value $_.LineURI
    $output | add-member -MemberType NoteProperty -Name 'DisplayName' -Value $_.Name
    $output | add-member -MemberType NoteProperty -Name 'SipUri' -Value $_.PrimaryUri
    $output | add-member -MemberType NoteProperty -Name 'Type' -Value 'ResponseGroup'
    $output | add-member -MemberType NoteProperty -Name 'RegistrarPool' -Value "$($_.OwnerPool)"
    $OutputCollection += $output
  }

  $OutputCollection #Put the output to the pipeline

  #Report on Findings
  if ($OutputCollection.count -eq 0)
  {
    Write-UcmLog -Message "Number $UriCheck does not appear to be used in the Skype4B deployment" -Severity 2 -Component $function
    $Return.Status = "OK"
    $Return.Message  = "Number Not Used"
    Return
  }
  Else
  {
    Write-UcmLog -Message "Number $UriCheck is already in use!" -Severity 3 -Component $function
    $Return.Status = "Error"
    $Return.Message  = "Number in use: $OutputCollection"
    Return
  }

  #region FunctionReturn
 
  #Default Return Variable for my HTML Reporting Fucntion
  Write-UcmLog -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
  $return.Status = "Unknown"
  $return.Message = "Function did not encounter return statement"
  Return
  #endregion FunctionReturn

}