#PerformScriptSigning
Function Initialize-UcmRequirements
{
	<#
			.SYNOPSIS
			Cmdlet to check the requirements for UcmPsTools are available. Displays a warning if any modules are missing

			.EXAMPLE
			PS> New-UcmEXHOConnection

			.INPUTS
			This function does not accept any input
			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple Keys to indicate status
			$Return.Status
			$Return.Message

			Return.Status can return one of three values
			"OK"      : All requirements present
			"Warn"    : Some requirements missing, see $return.message for more info
            "Unknown" : Cmdlet reached the end of the function without returning anything, this shouldnt happen, if it does please log an issue on Github

			Return.Message returns descriptive text showing the connected tenant, mainly for logging or reporting

			.NOTES
			Version:		1.0
			Date:			04/05/2024

			.VERSION HISTORY
			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Modules
			UcmPSTools 							(Install-Module UcmPSTools) Includes Cmdlets below

			Cmdlets
			Write-UcmLog:						https://github.com/Atreidae/UcmPSTools/blob/main/public/Write-UcmLog.ps1


			.REQUIRED PERMISSIONS
            None

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPsTools
	#>
	Param #No parameters
	(

	)


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Initialize-UcmRequirements'
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
    Write-UcmLog -Message "Loading UcmPsTools and checking requirements..." -Severity 2 -Component $function

    #Supported PowerShell Modules
    $Modules = @{}
    $Modules["MicrosoftTeams"] = @{NotBefore =[version]5.7.0; NotAfter=[version]6.0.0; Blacklist="None"}
    $Modules["Microsoft.Graph"] = @{NotBefore =[version]2.0.0; NotAfter=[version]2.18.0; Blacklist="None" }

    $return.Message = ""
    #actually do the checking

    Foreach ($module in $modules) {

        #first, check to see if the module is installed
        if ($null -eq (get-module $module.key))
        {
            Write-UcmLog -Message "Module $($module.key) was not found. Cmdlets requiring this module will not function" -Severity 4 -Component $function
            Write-UcmLog -Message "Please install this module by running 'Install-Module $($module.key)' from a PowerShell Window" -Severity 2 -Component $function
            Write-UcmLog -Message "Continuing without these modules may cause unexpected behaviour. You have been warned" -Severity 2 -Component $function

            $return.Status = "Warn"
            $return.Message += "Module $($module.key) Not found. "
        }

        #Check if the modules are too old.

        #todo, was here


    }