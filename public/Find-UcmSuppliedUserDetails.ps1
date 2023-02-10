#PerformScriptSigning
Function Find-UcmSuppliedUserDetail {

		<#
        .SYNOPSIS
        Function to locate a Lync/Skype user account

        .DESCRIPTION
        Checks the supplied user account against AD, returns the AD object if required
        If the object cant be found prompts the user to correct the username, should this fail it throws an error

        .OUTPUTS
        This function does not create pipelined output
		This Cmdet returns a PSCustomObject with multiple keys to indicate status
		$Return.Status
		$Return.Message
		$Return.User

		Return.Status can return one of four values
		"OK"      : Imported All Modules successfully
		"Warning" : Modules are already loaded
		"Error"   : Something happend when attempting to import the modules, check $return.message for more information
		"Unknown" : Cmdlet reached the end of the function without returning anything, this shouldnt happen, if it does please log an issue on Github

		Return.Message returns descriptive text for error messages.

		Return.User returns the AD user object

		.EXAMPLE
		Find-UcmSuppliedUserDetail -CsUsername button.mash -SkipPrompt

		.PARAMETER CsUsername
		The Username to find and return

		.PARAMETER SkipPrompt
		When set, skip prompting the user for the username if not found in AD
		Will return and error instead.

		.LINK
		https://www.UcMadScientist.com
		https://github.com/Atreidae/UcmPSTools

		.NOTES
		Version:		1.0
		Date:			18/11/2021

		.VERSION HISTORY
		1.0: Initial Public Release

		.ACKNOWLEDGEMENTS
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '', Scope='Function')] #todo, https://github.com/Atreidae/UcmPSTools/issues/23

    param(
    [Parameter(Mandatory, Position=1,HelpMessage='The Username to find and return')] [String]$CsUsername,
	[Parameter(HelpMessage='Skip prompting the user for the username if not found')] [Switch]$SkipPrompt
		)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Find-UcmSuppliedUserDetail'
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


	$aduser                      =  $null
    $CsUsernameSearch            =  $CsUsername + '@*'
	#endregion FunctionSetup

	#region FunctionWork


	#Try and find the user using the UPN
    $Aduser                      =  (get-aduser -filter {UserPrincipalName -like $CsUsernameSearch} -erroraction stop)
    if ($null -eq $aduser)
	{
		#Failover to SamAcountName
     	Write-UcmLog -component $function -message "Couldnt locate user $csusername in AD using UPN, Trying SamAcountName" -severity 3
      	$Aduser = (get-aduser -filter {SamAccountName -like $CsUsername} -erroraction stop)

    }

	#We still couldnt find the user account, deal with it.
    if ($null -eq $aduser)
	{
		Write-UcmLog -component $function -message 'Still couldnt locate user in AD, Please check and provide username, or type "Quit" to exit' -severity 3
		IF (!$skipPrompt)
		{
			Do
			{
				$CSUsername         = (Read-Host -Prompt 'enter username')
				if ($CSUsername -eq "Quit")
				{
					Write-UcmLog -Message "User opted to Exit when prompted for a username" -Severity 3 -Component $function
					$Return.Status = "Error"
					$Return.Message = "Username failed"
					Return $Return
				}
				Write-UcmLog -component $function -message "User provided $csusername, checking"
				$CsUsernameSearch = $CsUsername + '@*'
				$Aduser           = (get-aduser -filter {UserPrincipalName -like $CsUsernameSearch}-ErrorAction Stop)
				if ($null -eq $aduser)
				{
					Write-UcmLog -component $function -message "Couldnt locate user $csusername in AD using UPN, Trying SamAcountName"
					$Aduser = (get-aduser -filter {SamAccountName -like $CsUsername} -erroraction stop)
				}
			} #end of Do block
			Until ($null -eq $aduser)
			Write-UcmLog -component $Function -message "Found User $($aduser.name)"
		}
		Else #We couldnt find the user account, and we cant prompt the user. So throw an error.
		{
			Write-UcmLog -Message "Cant find a usernamme and -SkipPrompt is set" -Severity 3 -Component $function
			$Return.Status = "Error"
			$Return.Message = "Cant Find User"
			Return $Return
		}
    }
    #All good, put the AD Object on the pipeline
	$Return.Status = "OK"
	$Return.Message = $aduser.name
	$Return.User = $aduser
	Return $Return
  }
