Function Search-UcmCsOnPremNumberRange {
	<#
		.SYNOPSIS
		Checks to see how many numbers are assigned in a number range to each service

		.DESCRIPTION
		Checks to see how many numbers are assigned in a number range to each service, returns a summary of the results or a full listing depending on the presence of the -summary parameter
		Presently only supports number blocks aligned to full number ranges (00-99 for example.)

		Note, the function currently performs a search based on a match filter, thus only whole ranges are supported.
		IE: Start +613864086400 End +613864086499, Start +613864086000 End +61386408699 or Start +613864080000 End +61386409999

		Attempting to search for subranges will return all items in the whole range.
		For example searching for +61386408640 to +61386408650 will actually return everything between +61386408600 and +61386408699 as the last 2 digits cant be aligned.

		.PARAMETER Start (Required)
		The first number in the number range to be searched, can be in the following formats
		tel:+61386408600
		+61386408600
		386408600

		.PARAMETER End (Required)
		The last number in the number range to be searched, can be in the following formats
		tel:+61386408699
		+61386408699
		386408699

		.PARAMETER Summary
		Only returns the count of each object found in the number range, otherwise a PSCustom Object containing a list of the objects is returned for each object type (see Output)


			.EXAMPLE
			Search-UcmCsOnPremNumberRange -start "61386408600" -end "61386408699" -summary

			.INPUTS
			This function does not accept any input

			.OUTPUT
			This Cmdet returns a PSCustomObject with multiple keys to indicate results
			$Return.Status
			$Return.Message
			$Return.Users
			$Return.PrivateLines
			$Return.AnalogDevices
			$Return.CommonAreaPhones
			$Return.ExchangeUM
			$Return.DialInConf
			$Return.ResponseGroups
			$Return.All

			Return.Status can return one of four values
			"OK"      : Connected to Skype for Business Online
			"Warning" : Reconnected to Skype for Business Online
			"Error"   : Not connected to Skype for Business Online
			"Unknown" : Cmdlet reached the end of the function without returning anything, this shouldnt happen, if it does please log an issue on Github

			Return.Message returns descriptive text showing the connected tenant, mainly for logging or reporting

			$Return.Users
			$Return.PrivateLines
			$Return.AnalogDevices
			$Return.CommonAreaPhones
			$Return.ExchangeUM
			$Return.DialInConf
			$Return.ResponseGroups

			Each of the above return either a object count (when using -summary) or a list of the associated objects

			$Return.All returns either a total count, or a full list of the located objects.

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPsTools

			.ACKNOWLEDGEMENTS
			This function is based heavily off Tom Arbuthnot's Get-LyncNumberAssignment (Which I think might use code from Pat Richard)
			https://github.com/tomarbuthnot/Get-LyncNumberAssignment/blob/master/Get-LyncNumberAssignment-0.5.ps1

			.NOTES
			Version:		1.0
			Date:			03/08/2021

			.VERSION HISTORY
			1.0: Initial Public Release

			.REQUIRED FUNCTIONS/MODULES
			Modules
			Lync/SkypeforBusiness				(From your Lync/Skype installation media)
			UcmPSTools							(Install-Module UcmPsTools) Includes Cmdlets below.

			Cmdlets
			Write-UcmLog: 						https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-UcmLog.ps1

			.REQUIRED PERMISIONS
			'CS Read Only Administrator' or better

	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleCommands', '', Scope='Function')] #PSScriptAnalyzer isnt aware of the whole workspace when it runs on each item, thus assumes many crossreferenced cmdlets are incorrect

	Param
		(
			[Parameter(Mandatory, Position=1)] [string]$Start,
			[Parameter(Mandatory, Position=2)] [string]$End,
			[Parameter(Position=3)] [Switch]$summary
		)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Search-UcmCsOnPremNumberRange'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = "Unknown"
	$return.Message = "Function did not return a status message"

	# Log why we were called
	Write-Log -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-Log -Message "Parameters" -Severity 3 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$Args" -Severity 1 -Component $function -LogOnly

	#endregion FunctionSetup

	#region FunctionWork

	#Calculate the match string based on start and end by trying to match strings until an error is encountered
		$MatchError = $false
		$i = 1
		Do
		{
			If ($start -notmatch ($End.substring(0,$i)))
				{
					#We dont match, decrement $i and set the flag to exit the loop
					$i = ($i - 1)
					$MatchError = $true
				}

			Else
				{
					#keep trying to increment the match number
					$i = ($i + 1)
				}
		}
		Until ($MatchError-eq $true)

	#Copy URI Check into Match
	$match = "*$($End.substring(0,$i))*"

	Write-Log -Message "Checking for objects containing $match in Skype4B" -Severity 2 -Component $function

	Write-Log -Message "Checking Users" -Severity 1 -Component $function
	Get-CsUser -Filter {LineURI -like $match} | ForEach-Object {
		$output           =  New-Object -TypeName PSobject
		$output | add-member -MemberType NoteProperty -Name 'LineUri' -Value $_.LineURI
		$output | add-member -MemberType NoteProperty -Name 'DisplayName' -Value $_.DisplayName
		$output | add-member -MemberType NoteProperty -Name 'SipUri' -Value $_.SipAddress
		$output | add-member -MemberType NoteProperty -Name 'Type' -Value 'User'
		$output | add-member -MemberType NoteProperty -Name 'RegistrarPool' -Value "$($_.RegistrarPool)"
		$Return.Users = $output
	}

	Write-Log -Message "Checking User Private Lines" -Severity 1 -Component $function
	Get-CsUser -Filter {PrivateLine -like $match} | ForEach-Object {
		$output           =  New-Object -TypeName PSobject
		$output | add-member -MemberType NoteProperty -Name 'LineUri' -Value $_.LineURI
		$output | add-member -MemberType NoteProperty -Name 'DisplayName' -Value $_.DisplayName
		$output | add-member -MemberType NoteProperty -Name 'SipUri' -Value $_.SipAddress
		$output | add-member -MemberType NoteProperty -Name 'Type' -Value 'PrivateLineUser'
		$output | add-member -MemberType NoteProperty -Name 'RegistrarPool' -Value "$($_.RegistrarPool)"
		$Return.PrivateLine = $output
	}

	Write-Log -Message "Checking Analog Devices" -Severity 1 -Component $function
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

	Write-Log -Message "Checking Analog Devices" -Severity 1 -Component $function
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

	Write-Log -Message "Checking Dialin Conference Numbers" -Severity 1 -Component $function
	Get-CsDialInConferencingAccessNumber -Filter {LineURI -like $match} | ForEach-Object {
		$output           =  New-Object -TypeName PSobject
		$output | add-member -MemberType NoteProperty -Name 'LineUri' -Value $_.LineURI
		$output | add-member -MemberType NoteProperty -Name 'DisplayName' -Value $_.DisplayName
		$output | add-member -MemberType NoteProperty -Name 'SipUri' -Value $_.PrimaryUri
		$output | add-member -MemberType NoteProperty -Name 'Type' -Value 'DialInConf'
		$output | add-member -MemberType NoteProperty -Name 'RegistrarPool' -Value "$($_.Pool)"
		$OutputCollection += $output
	}

	Write-Log -Message "Checking Trusted Application Endpoints" -Severity 1 -Component $function
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
	Write-Log -Message "Checking Response Groups" -Severity 1 -Component $function
	Get-CsRgsWorkflow | Where-Object {$_.LineURI -like $match} | ForEach-Object {
		$output           =  New-Object -TypeName PSobject
		$output | add-member -MemberType NoteProperty -Name 'LineUri' -Value $_.LineURI
		$output | add-member -MemberType NoteProperty -Name 'DisplayName' -Value $_.Name
		$output | add-member -MemberType NoteProperty -Name 'SipUri' -Value $_.PrimaryUri
		$output | add-member -MemberType NoteProperty -Name 'Type' -Value 'ResponseGroup'
		$output | add-member -MemberType NoteProperty -Name 'RegistrarPool' -Value "$($_.OwnerPool)"
		$OutputCollection += $output
	}

	$OutputCollection #Put the output to the pipeline #TODO https://github.com/Atreidae/UcmPSTools/issues/28

	#Report on Findings
	if ($OutputCollection.count -eq 0)
	{
		Write-Log -Message "Number $UriCheck does not appear to be used in the Skype4B deployment" -Severity 2 -Component $function
		$Return.Status = "OK"
		$Return.Message  = "Number Not Used"
		Return
	}
	Else
	{
		Write-Log -Message "Number $UriCheck is already in use!" -Severity 3 -Component $function
		$Return.Status = "Error"
		$Return.Message  = "Number in use: $OutputCollection"
		Return
	}

	#region FunctionReturn

	#Default Return Variable for my HTML Reporting Fucntion
	Write-Log -Message "Reached end of $function without a Return Statement" -Severity 3 -Component $function
	$return.Status = "Unknown"
	$return.Message = "Function did not encounter return statement"
	Return
	#endregion FunctionReturn
}