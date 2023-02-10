Function Initialize-UcmReport
{
  <#
      .SYNOPSIS
      Checks for clears and creates a new object to store status for reporting later.

      .DESCRIPTION
      Checks for clears and creates a new object to store status for reporting later.

      .EXAMPLE
      Initialize-UcmHTMLReport

      .INPUTS
      This function accepts no inputs

      .OUTPUTS
      This function does not create pipelined output
      This Cmdet returns a PSCustomObject with multiple keys to indicate status
      $Return.Status
      $Return.Message

      Return.Status can return one of four values
      "OK"      : Imported All Modules successfully
      "Warning" : Modules are already loaded
      "Error"   : Something happend when attempting to import the modules, check $return.message for more information
      "Unknown" : Cmdlet reached the end of the function without returning anything, this shouldnt happen, if it does please log an issue on Github

      Return.Message returns descriptive text for error messages.

      .LINK
      https://www.UcMadScientist.com
      https://github.com/Atreidae/UcmPSTools

      .NOTES
      Version:		1.2
      Date:			19/06/2022

      .VERSION HISTORY

      1.2: Bug fixes for date reporting
      Added per line item numbers
      Added per line timestamps
      Updated Date format to respect system locale
      Added Subtitle support to HTML report

      1.1: Reordered functions into logical order

      1.0: Initial Public Release

      .ACKNOWLEDGEMENTS
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '', Scope='Function')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function')] #Required due to how this report works. Report must persist outside of its own scope
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUSeDeclaredVarsMoreThanAssignments', '', Scope='Function')] #Required due to how this report works. Variables must persist outside of their own scope
  Param
  (
    [Parameter(ValueFromPipelineByPropertyName=$true, Position=1)] [String]$Title="HTML Report",
    [Parameter(ValueFromPipelineByPropertyName=$true, Position=2)] [String]$SubTitle="The results were as follows",
    [Parameter(ValueFromPipelineByPropertyName=$true, Position=3)] [string]$StartDate=(Get-Date -format dd.MM.yy.hh.mm),
    [Parameter(ValueFromPipelineByPropertyName=$true, Position=4)] [string]$NiceDate=(Get-Date -displayhint datetime)
  )


  #region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
  $function = 'Initialize-UcmReport'
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

  #endregion FunctionSetup

  #region FunctionWork

  #Declare our reports
  $Global:ProgressReport = @()
  $Global:ThisReport = @()

  #Declare our filenames
  $Global:HTMLReportFilename=".\$Title - $StartDate.html"
  $Global:CSVReportFilename=".\$Title - $StartDate.csv"

  #Import the attributes into the report object
  $Global:ProgressReport | add-member -MemberType NoteProperty -Name "Title"-Value "$title" -Force
  $Global:ProgressReportTitle = $Title
  $Global:ProgressReportSubtitle = $Subtitle
  $Global:ProgressReportStartTime = $NiceDate
  $Global:ProgressReportItemCount = 0

  New-UCMReportStep -StepName "Item" -StepResult "$($Global:ProgressReportItemCount)"
}

Function New-UCMReportItem
{
  <#
      .SYNOPSIS
      Adds a new Line Object to the Report

      .DESCRIPTION
      Adds a new Line Object to the Report

      .EXAMPLE
      New-UCMReportStep -LineTitle "Username" -LineMessage "bob@contoso.com"

      .INPUTS
      This function accepts no inputs

      .LINK
      http://www.UcMadScientist.com
      https://github.com/Atreidae/UcmPSTools

      .ACKNOWLEDGEMENTS

      .NOTES
      Version:		1.1
      Date:			19/06/2022

      .VERSION HISTORY

      1.1: Added per item numbering and timestamping

      1.0: Initial Public Release
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '', Scope='Function')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingfunctions', '', Scope='Function')] #process does not change state, ShouldProcess is not required.
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function')] #Required due to how this report works. Report must persist outside of its own scope
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUSeDeclaredVarsMoreThanAssignments', '', Scope='Function')] #Required due to how this report works. Variables must persist outside of their own scope
  Param
  (
    [Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1)] $LineTitle,
    [Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2)] $LineMessage
  )

  #region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
  $function = 'New-UcmReportLine'
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

  #endregion FunctionSetup

  #region FunctionWork

  #Add the current time to the end of the old line
  New-UCMReportStep -Stepname "Time" -StepResult (Get-Date -displayhint time)

  #Merge the current line item into the report
  $Global:ProgressReport+= $Global:ThisReport

  #Init a new line item
  $Global:ThisReport = @()
  $Global:ThisReport =  New-Object -TypeName PSobject
  $Global:ThisReport | add-member -MemberType NoteProperty -Name "$LineTitle" -Value $LineMessage

  #Increment the line counter and add to the new line
  $Global:ProgressReportItemCount ++
  New-UCMReportStep -Stepname "ItemNumber" -StepResult "$Global:ProgressReportItemCount"
}

Function New-UcmReportStep
{
  <#
      .SYNOPSIS
      Adds a new Step to the Report

      .DESCRIPTION
      Creates a new Step for the current line item (for example, creating a user)

      .EXAMPLE
      New-UcmReportStep -Stepname "Enable User" -StepResult "OK: Created User"

      .INPUTS
      This function accepts no inputs

      .REQUIRED FUNCTIONS
      Write-UcmLog: https://github.com/Atreidae/PowerShell-Functions/blob/main/New-Office365User.ps1

      .LINK
      http://www.UcMadScientist.com
      https://github.com/Atreidae/UcmPSTools

      .ACKNOWLEDGEMENTS

      .NOTES
      Version:		1.0
      Date:			18/11/2021

      .VERSION HISTORY


      1.0: Initial Public Release

  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '', Scope='Function')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingfunctions', '', Scope='Function')] #process does not change state, ShouldProcess is not required.
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function')] #Required due to how this report works. Report must persist outside of its own scope
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUSeDeclaredVarsMoreThanAssignments', '', Scope='Function')] #Required due to how this report works. Variables must persist outside of their own scope
  Param
  (
    [Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1)] $StepName,
    [Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2)] $StepResult
  )

  #region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
  $function = 'New-UcmReportStep'
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

  #endregion FunctionSetup

  #region FunctionWork

  $Global:ThisReport | add-member -MemberType NoteProperty -Name "$StepName"-Value "$StepResult" -Force

  # endregion FunctionWork

}

Function Complete-UcmReport
{
  <#
      .SYNOPSIS
      Adds the last Line Object to the Report

      .DESCRIPTION
      Adds the last Line Object to the Report

      .EXAMPLE
      Complete-UcmReport

      .INPUTS
      This function accepts no inputs

      .LINK
      http://www.UcMadScientist.com
      https://github.com/Atreidae/UcmPSTools

      .ACKNOWLEDGEMENTS

      .NOTES
      Version:		1.1
      Date:			18/11/2021

      .VERSION HISTORY
      1.0: Initial Public Release
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '', Scope='Function')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function')] #Required due to how this report works. Report must persist outside of its own scope
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUSeDeclaredVarsMoreThanAssignments', '', Scope='Function')] #Required due to how this report works. Variables must persist outside of their own scope
  Param
  (
    #none
  )

  #region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
  $function = 'Complete-UcmReport'
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

  #endregion FunctionSetup

  #region FunctionWork

  #Merge the current item and cleanup
  $Global:ProgressReport+= $Global:ThisReport
  Remove-variable -Name ProgressReport -scope global

  $Global:ThisReport = @()
  $Global:ThisReport = New-Object -TypeName PSobject
  $Global:ThisReport | add-member -MemberType NoteProperty -Name "End of Report" -Value "End of report"

}

Function Export-UcmHTMLReport
{
  <#
      .SYNOPSIS
      Grabs the data stored in the report object and converts it to HTML

      .DESCRIPTION
      Grabs the data stored in the report object and converts it to HTML
      By default, exports the current open report as a HTML in the current folder with the filename "$Title - $StartDate.html"
      You can change the path by editing $Global:HTMLReportFilename just before calling this function

      .EXAMPLE
      Export-UcmHTMLReport

      .INPUTS
      This function accepts no inputs

      .LINK
      http://www.UcMadScientist.com
      https://github.com/Atreidae/UcmPSTools

      .ACKNOWLEDGEMENTS

      .NOTES
      Version:		1.0
      Date:			18/11/2021

      .VERSION HISTORY
      1.1: Added per item numbering and timestamping
           Fixed formatting issues
           Fixed repetitive EndDate Bug
           Removed erronus "EndDate" field from each line item

      1.0: Initial Public Release

  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '', Scope='Function')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function')] #Required due to how this report works. Report must persist outside of its own scope
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUSeDeclaredVarsMoreThanAssignments', '', Scope='Function')] #Required due to how this report works. Variables must persist outside of their own scope
  Param
  (
    [Parameter(ValueFromPipelineByPropertyName=$true, Position=1)] [string]$EndDate=(Get-Date -DisplayHint datetime)
  )

  #region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
  $function = 'Export-UcmHTMLReport'
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

  #endregion FunctionSetup

  #region FunctionWork

  #Import the end time
  $Global:ProgressReportEndTime = $EndDate

  #$Report = ($PSCommandPath -replace '.ps1',"$ReportDate.html")

  #Define the HTML Style
  $Style = @"
<style>
BODY{background-color::#b0c4de;font-family:Tahoma;font-size:12pt;}
TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;color:white;background-color:#000099}
TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;text-align:center;}
</style>
"@

  Try #Export the report
  {
    $Global:ProgressReport | ConvertTo-Html -head $Style -body "<h1> $($Global:ProgressReportTitle) </h1> <h2> $Global:ProgressReportSubtitle </h2> The following report was started at $Global:ProgressReportStartTime and finishes at $Global:ProgressReportEndTime <br><br>" | ForEach-Object {
      #Add formatting for the different states
      if($_ -like "*<td>OK*")
      {$_ -replace "<td>OK", "<td bgcolor=#33FF66>OK"}
      Else {$_}
    } | ForEach-Object {
      if($_ -like "*<td>Warning*")
      {$_ -replace "<td>Warning", "<td bgcolor=#F9E79F>Warning"}
    Else {$_} } | ForEach-Object {
      If($_ -like "*<td>Error*")
      {$_ -replace "<td>Error", "<td bgcolor=#CD6155>Error"}
      Else {$_}
      #Write this out
    } | Out-File $Global:HTMLReportFilename

    #Open Browser
    invoke-Item $Global:HTMLReportFilename

    $Return.Status = "OK"
    $Return.Message = "HTML Report "
    Return $Return
  }
  Catch
  {

    Write-UcmLog -Message "Unexpected error when generating HTML report" -Severity 3 -Component $function
    Write-UcmLog -Message "$error[0]" -Severity 2 -Component $function
  }
}

Function Export-UcmCSVReport
{
  <#
      .SYNOPSIS
      Grabs the data stored in the report object and converts it to a CSV

      .DESCRIPTION
      Grabs the data stored in the report object and converts it to a CSV
      Exports the current open report as a HTML in the current folder with the filename "$Title - $StartDate.csv"
      You can change the path by editing $Global:CSVReportFilename just before calling this function

      .EXAMPLE
      Export-UcmCsvReport

      .INPUTS
      This function accepts no inputs

      .LINK
      http://www.UcMadScientist.com
      https://github.com/Atreidae/UcmPSTools

      .ACKNOWLEDGEMENTS

      .NOTES
      Version:		1.0
      Date:			18/11/2021

      .VERSION HISTORY
      1.0: Initial Public Release

  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '', Scope='Function')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function')] #Required due to how this report works. Report must persist outside of its own scope
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUSeDeclaredVarsMoreThanAssignments', '', Scope='Function')] #Required due to how this report works. Variables must persist outside of their own scope
  Param
  (
    [Parameter(ValueFromPipelineByPropertyName=$true, Position=1)] [string]$EndDate=(Get-Date -DisplayHint datetime)
  )

  #region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
  $function = 'Export-UcmCSVReport'
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

  #endregion FunctionSetup

  #region FunctionWork

  #Import the end time
  Try
  {
    $Global:ProgressReport | Export-CSV $Global:CSVReportFilename
    $Return.Status = "OK"
    $Return.Message = "CSV Report"
    Return $Return
  }
  Catch
  {

    Write-UcmLog -Message "Unexpected error when generating CSV report" -Severity 3 -Component $function
    Write-UcmLog -Message "$error[0]" -Severity 2 -Component $function
  }
}