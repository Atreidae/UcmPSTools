Function Search-CsLineUri {
	<#
			.SYNOPSIS
			Checks to see if a DID has already been assigned to an object in an on-prem Skype4B deployment and if so returns the result

			.DESCRIPTION
			Checks to see if a DID has already been assigned to an object in the Skype4B deployment and if so returns the result

			.EXAMPLE
			Search-CsLineUri "61386408640"

			.INPUTS
			UriCheck the number to check against

			.REQUIRED FUNCTIONS
			Write-Log: https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-Log.ps1
			Write-HTMLReport: https://github.com/Atreidae/PowerShell-Fuctions/blob/main/Write-HTMLReport.ps1
			Lync or Skype Management tools

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Fuctions

			.ACKNOWLEDGEMENTS
			This function is based heavily off Tom Arbuthnot's Get-LyncNumberAssignment (Which I think might use code from Pat Richard)
			https://github.com/tomarbuthnot/Get-LyncNumberAssignment/blob/master/Get-LyncNumberAssignment-0.5.ps1

			.NOTES
			Version:		1.0
			Date:			25/11/2020

			.VERSION HISTORY
			1.0: Initial Public Release

	#>

	Param  (
		[Parameter(Mandatory, Position=1)] $UriCheck 
	)

	#Set Default Variables for HTML Reporting and Write Log

	$function = 'Search-CsLineUri'
	[hashtable]$return = @{}
	$return.Status = "Unknown"
	$return.Message = "Function did not return a status message"

	#Copy URI Check into Match
	$match = "*$UriCheck*"

	Write-Log -Message "Checking if $match is a unique number in Skype4B" -Severity 2 -Component $function

	# Define a new object to gather output
	$OutputCollection = @()

	# For Each one we want to output
	# LineURI, Name, supuri, Type (USER/RGS etc)

	Write-Log -Message "Checking Users" -Severity 1 -Component $function
	Get-CsUser -Filter {LineURI -like $match} | ForEach-Object {
		$output           =  New-Object -TypeName PSobject 
		$output | add-member -MemberType NoteProperty -Name 'LineUri' -Value $_.LineURI
		$output | add-member -MemberType NoteProperty -Name 'DisplayName' -Value $_.DisplayName
		$output | add-member -MemberType NoteProperty -Name 'SipUri' -Value $_.SipAddress
		$output | add-member -MemberType NoteProperty -Name 'Type' -Value 'User'
		$output | add-member -MemberType NoteProperty -Name 'RegistrarPool' -Value "$($_.RegistrarPool)"
		$OutputCollection += $output
	}

	Write-Log -Message "Checking User Private Lines" -Severity 1 -Component $function
	Get-CsUser -Filter {PrivateLine -like $match} | ForEach-Object {
		$output           =  New-Object -TypeName PSobject 
		$output | add-member -MemberType NoteProperty -Name 'LineUri' -Value $_.LineURI
		$output | add-member -MemberType NoteProperty -Name 'DisplayName' -Value $_.DisplayName
		$output | add-member -MemberType NoteProperty -Name 'SipUri' -Value $_.SipAddress
		$output | add-member -MemberType NoteProperty -Name 'Type' -Value 'PrivateLineUser'
		$output | add-member -MemberType NoteProperty -Name 'RegistrarPool' -Value "$($_.RegistrarPool)"
		$OutputCollection += $output
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

	$OutputCollection #Put the output to the pipeline

#Report on Findings
if ($OutputCollection.count -eq 0)
{Trho dfskmsdfsd
}


#Return Variable for my HTML Reporting Fucntion
$Return.Object = $OutputCollection #Return the results to the calling function
$return.Function = $function
$return.Status = $ReturnStatus
$return.Message = $ReturnMessage

}