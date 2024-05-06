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

    #Set a default logging location of the users profile folder
    $Script:LogFileLocation = "$ENV:UserProfile\UcmPsTools.log"

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
    $Modules["MicrosoftTeams"] = @{NotBefore =[version]"5.3.0"; NotAfter=[version]"7.0.0"; Blacklist="1.2.3"}
    $Modules["Microsoft.Graph"] = @{NotBefore =[version]"2.0.0"; NotAfter=[version]"2.18.0"; Blacklist="None" }
    $Modules["AzureAD"] = @{NotBefore =[version]"2.0.2.180"; NotAfter=[version]"2.0.2.182"; Blacklist="None" }
    $Modules["MsOnline"] = @{NotBefore =[version]"1.1.183.80"; NotAfter=[version]"1.1.183.81"; Blacklist="None" }



    #azureAD
    #Msonline

    #Put something in return so we can += it if needed
    $return.Message = ""
    #actually do the checking

    Foreach ($key in $modules.keys) {
        $Module = (get-module $key -ListAvailable)

        #first, check to see if the module is installed
        if ($null -eq $Module)
        {
            Write-UcmLog -Message "Module $key was not found. Cmdlets requiring this module will not function" -Severity 3 -Component $function
            Write-UcmLog -Message "Please install this module by running 'Install-Module $key' from a PowerShell Window" -Severity 2 -Component $function
            Write-UcmLog -Message "Continuing without these modules may cause unexpected behaviour. You have been warned" -Severity 2 -Component $function

            $return.Status = "Warn"
            $return.Message += "Module $key Not found."
        }

        #Check if the modules are too old.
        if ($Module.Version -lt $Modules[$key].NotBefore)
        {
            Write-UcmLog -Message "Module $key is too old. Cmdlets requiring this module may not function correctly!" -Severity 3 -Component $function
            Write-UcmLog -Message "Please update this module by running 'Update-Module $key' from a PowerShell Window" -Severity 2 -Component $function
            Write-UcmLog -Message "Continuing without these modules may cause unexpected behaviour. You have been warned" -Severity 2 -Component $function

            $return.Status = "Warn"
            $return.Message += "Module $key is too old."
        }
       #check if the modules are too new.
        if ($Module.Version -gt $Modules[$key].NotAfter)
        {
            Write-UcmLog -Message "Module $key is too new! UcmPsTools has not been tested with this version. Cmdlets requiring this module may not function correctly!" -Severity 3 -Component $function
            Write-UcmLog -Message "Please update this module by running 'Update-Module $key' from a PowerShell Window" -Severity 2 -Component $function
            Write-UcmLog -Message "Continuing without these modules may cause unexpected behaviour. You have been warned" -Severity 2 -Component $function

            $return.Status = "Warn"
            $return.Message += "Module $key is too new."
        }

        #check to see if the module has been blacklisted
        if ($Modules[$key].Blacklist -like "*$($module.Version)*")
        {
            Write-UcmLog -Message "Module $key version $($module.version) is blacklisted. There is a known issue with this version!" -Severity 3 -Component $function
            Write-UcmLog -Message "Please update this module by running 'Update-Module $key' from a PowerShell Window" -Severity 2 -Component $function
            Write-UcmLog -Message "User attempted to load UcmPsTools with a blacklisted module installed. UcmPsTools will not be loaded" -Severity 4 -Component $function

            $return.Status = "Error"
            $return.Message += "Module $key version $($module.version) is blacklisted."
            Throw "Module $key version $($module.version) is blacklisted. There is a known issue with this version!"
        }

    }
    Write-UcmLog -Message "Requirement checks completed" -Severity 2 -Component $function
    return
    
    #region FunctionCleanup
    if ($return.Status -eq "Unknown")
    {
        Write-UcmLog -Message "Function did not return a status message, this should not happen. Please log an issue on Github" -Severity 4 -Component $function
        $return.Status = "Unknown"
    }

    Write-UcmLog -Message "Function completed with status $($return.Status)" -Severity 2 -Component $function
    return $return
    #endregion FunctionCleanup

}
