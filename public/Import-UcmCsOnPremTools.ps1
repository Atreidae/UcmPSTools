#PerformScriptSigning
Function Import-CsOnPremTools {
	<#
        .SYNOPSIS
        Function to check for and import both Skype4B and AD Management tools
      
        .DESCRIPTION
        Checks for and loads the approprate modules for Skype4B and Active Directory
        Will throw an error and abort script if they arent found

        .INPUTS
        This function does not accept pipelined input

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
		Version:		1.0
		Date:			20/07/2021

		.VERSION HISTORY
		1.0: Initial Public Release

		.ACKNOWLEDGEMENTS
	#>
	[CmdletBinding()]
	PARAM
	(
		#No Parameters
	)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Import-CsOnPremTools'
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
	
	#Check to see if the modules are already loaded
	Write-UcmLog -Message 'Checking for Lync/Skype management tools' -Severity 1 -Component $function 
	$CsManagementTools = $false
	$ADManagementTools = $false
	if(Get-Module -Name 'SkypeForBusiness') {$CSManagementTools = $true}
    if(Get-Module -Name 'Lync') {$CSManagementTools = $true}
	if(Get-Module -Name 'ActiveDirectory') {$ADManagementTools = $true}

	#If both modules are loaded, return a warning and exit
	If (($CSManagementTools -eq $true) -and ($ADManagementTools -eq $true))
	{
		Write-UcmLog -Message "Management moduled already loaded" -Severity 1 -Component $function
		$Return.Status = "Warning"
		$Return.Message = "Management moduled already loaded"
		Return $Return
	}

	#Now, check the modules are installed.
	$CsManagementTools = $false
	$ADManagementTools = $false
	if(Get-Module -Name 'SkypeForBusiness' -ListAvailable) {$CSManagementTools = $true}
    if(Get-Module -Name 'Lync'-ListAvailable) {$CSManagementTools = $true}
	if(Get-Module -Name 'ActiveDirectory' -ListAvailable) {$ADManagementTools = $true}
	
	#Return an error if we cant find Lync/Skype
	If ($CSManagementTools -ne $true)
	{
		Write-UcmLog -Message "Unable to locate Lync or Skype PowerShell modules" -Severity 3 -Component $function
		Write-UcmLog -Message "Have you installed the Management tools on this host?" -Severity 3 -Component $function
		$Return.Status = "Error"
		$Return.Message = "Lync/Skype PS Module Missing"
		Return $Return
	}

	#Return an error if we cant find Active Directory
	If ($ADManagementTools -ne $true)
	{
		Write-UcmLog -Message "Unable to locate Active Directory PowerShell modules" -Severity 3 -Component $function
		Write-UcmLog -Message "Have you installed the AD RSAT Management tools on this host?" -Severity 3 -Component $function
		$Return.Status = "Error"
		$Return.Message = "ActiveDirectory PS Module Missing"
		Return $Return
	}


    #Okay, we got this far, import everything
	Try 
	{
		if(!(Get-Module -Name 'SkypeForBusiness')) {Import-Module -Name SkypeForBusiness -Verbose:$false}
		if(!(Get-Module -Name 'Lync')) {Import-Module -Name Lync -Verbose:$false}
		if(Get-Module -Name 'SkypeForBusiness') {$ManagementTools = $true}
		if(Get-Module -Name 'Lync') {$ManagementTools = $true}
	}
	Catch
	{
		Write-UcmLog -Message "Something went wrong attempting to import modules" -Severity 3 -Component $function
		Write-UcmLog -Message "$Error[0]" -Severity 3 -Component $function
		$Return.Status = "Error"
		$Return.Message = "Import Failure, Try/Catch block : $error[0]"
		Return $Return
	}

	#Cmdlets ran, but did the modules import?
    If (($CSManagementTools -eq $true) -and ($ADManagementTools -eq $true))
	{
      Write-UcmLog -Message 'Import-Module sucseeded' -Severity 1 -Component $Function
	  $Return.Status = "OK"
	  $Return.Message = "Modules Loaded"
	  Return $Return
    }
	Else 
	{
	  Write-UcmLog -Message 'Import-Module sucseeded, but modules not resident' -Severity 5 -Component $Function
	  Write-UcmLog -Message "$Error[0]" -Severity 3 -Component $function
	  $Return.Status = "Error"
	  $Return.Message = "Import Failure, Checking Import : $error[0]"
	  Return $Return
	}

	
	#Default Return Variable for my HTML Reporting Fucntion, this should never run!
	Write-UcmLog -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
	$return.Status = "Unknown"
	$return.Message = "Function did not encounter return statement"
	Return $Return
	#endregion FunctionReturn
    

  }
