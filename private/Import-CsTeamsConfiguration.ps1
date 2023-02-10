#PerformScriptSigning
Function Import-CsTeamsConfiguration
{
  <#
      .SYNOPSIS
      Function to scrape relevant Unified Communications Teams settings and dump them into a zip file

      .DESCRIPTION
      An Auditing tool, The tool will run through all the relevant Teams settings for Calling and output them into a zip file in the local folder
      Useful with my Get-CsTeamsConfigToWord script

      .EXAMPLE
      Import-CsTeamsConfiguration

      .PARAMETER ZipFileName
      (Optional) Defaults to TeamsConfigReport.zip

      .INPUTS
      This function does not accept any inputs

      .REQUIRED FUNCTIONS/MODULES
      Modules
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
      Version:		0.1
      Date:			21/10/2022

      .VERSION HISTORY
      0.1: Initial Beta Release

      .THANKS
      Special thanks go out to "GreigInSydney" (Greig Sheriden - https://greiginsydney.com/ ) and "EmptyMessage" ( Chris Cook - https://emptymessage.com/ ) for their tools that inspired this one
  #>

  Param
  (
    [Parameter(Position=1)] $ZipFileName="TeamsConfigReport.zip"
  )

  #region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
  $function = 'Import-CsTeamsConfiguration'
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

  Write-UcmLog -Message "Checking for relevant connections" -Severity 2 -Component $function
  
  #todo Check Connections
  

  #Global Variables

  #Now create an empty "Report Variable"

  $global:CsTeamConfig=@()
  #Todo init report



  #AppPolicies
  
  Get-CsApplicationAccessPolicy 





  #Teams Apps and special config
  
  #look for non standard apps
  
  get-teamsapp | Where {$_.DistributionMethod -ne "Store"}




  #Team Info
  Get-Team
  
  #foreach team
  Get-TeamChannel
  
  ## Get Team user details
  Get-TeamUser a6601176-d6fc-4295-b6fa-6c3c0304c799
  
  ##Check for installed apps
  Get-TeamsAppInstallation a6601176-d6fc-4295-b6fa-6c3c0304c799
  
  #foreach channel
  Get-TeamChannelUser
  
    
    
    
    
  
  #Voice Apps
  
  
  
  
  #For each Object
  Export-CsAutoAttendantHolidays
    
  
  
  }#End of main function

