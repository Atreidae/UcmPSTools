Function Show-UcmMenu
{
  <#
      .SYNOPSIS
      A function to display an easy to read list of options for the user to select from 

      .DESCRIPTION
      Provided a hashtable of options for the user the user to select from, this function will display a list of to the user using write-host and ask them to pick one using get-host then return the selected object in the Return hashtable object
      Code based VERY heavily off Greig Sheridan's code
 
      .EXAMPLE
      Show-UcmMenu -Options 

      .PARAMETER Options
      (Required) An array of options to choose from
      
      .PARAMETER Header
      (Optional) The title above the column of options, defaults to "Option"

      .INPUTS
      This function does not accept any inputs
      
      .OUTPUTS
      Like many of my functions, Show-UcmMenu will return a hashtable with status codes as well as 2 properties.
      $return.choice - The array index of the selected object, starting at 0
      $return.name - the display name of the selected object.

      .REQUIRED FUNCTIONS/MODULES
      Modules
      UcmPSTools											(Install-Module UcmPsTools) Includes Cmdlets below.

      Cmdlets
      Write-UcmLog: 									https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-UcmLog.ps1
  
      .REQUIRED PERMISSIONS
      None

      .LINK
      https://www.UcMadScientist.com
      https://github.com/Atreidae/UcmPSTools


      .NOTES
      Version:		1.0
      Date:			31/03/2022

      .VERSION HISTORY
      1.0: Initial Public Release

  #>

  Param
  (
    [Parameter(Position=1)] [Array]$Options,
    [Parameter(Position=1)] [String]$Header="Option"
    
  )

  #region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
  $function = 'Show-UcmMenu'
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
			
    #Menu code thanks to Greig.

 
    #First figure out the maximum width of the item's name (for the tabular menu):
    $width = 0
    foreach ($Option in ($Options)) 
    {
      if ($Option.Length -gt $width) 
      {
        $width = $Option.Length
      }
    }

    #Provide an on-screen menu of options for the user to choose from:
    $index = 1
    Write-Host -Object ''
    Write-Host -Object ('ID    '), ($header.Padright($width + 1), ' ')
    foreach ($Option in ($Options)) 
    {
      Write-Host -Object ($index.ToString()).PadRight(2, ' '), ' | ', ($Option.Padright($width + 1), ' ')
      $index++
    }
    $index--	#Undo that last increment
    Write-Host
    Write-Host -Object "Choose the $option you wish to use"
    $chosen = Read-Host -Prompt 'Or any other value to quit'
    Write-Log -Message "User input $chosen" -severity 1
    if ($chosen -notmatch '^\d$') 
    {
      Exit
    }
    if ([int]$chosen -lt 0) 
    {
      Exit
    }
    if ([int]$chosen -gt $index) 
    {
      Exit
    }
    $Tenant = $chosen
  }
