Function Initialize-HTMLReport
{
	<#
			.SYNOPSIS
			Checks for clears and creates a new object to store status for reporting later.

			.DESCRIPTION
			Checks for clears and creates a new object to store status for reporting later.

			.EXAMPLE
			Initialize-HTMLReport

			.INPUTS
			This function accepts no inputs

			.REQUIRED FUNCTIONS
			Write-Log: https://github.com/Atreidae/PowerShell-Functions/blob/main/New-Office365User.ps1
			AzureAD (Install-Module AzureAD) 
			Connect-MsolService

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Functions

			.ACKNOWLEDGEMENTS

			.NOTES
			Version:		1.0
			Date:			25/11/2020

			.VERSION HISTORY
			1.0: Initial Public Release

	#>

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Position=1)] [String]$Title="HTML Report", 
		[Parameter(ValueFromPipelineByPropertyName=$true, Position=2)] [string]$StartDate=(Get-Date -format dd.MM.yy.hh.mm)
	)


	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Initialize-HTMLReport'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = "Unknown"
	$return.Message = "Function did not return a status message"

	# Log why we were called
	Write-Log -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-Log -Message "Parameters" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$Args" -Severity 1 -Component $function -LogOnly
	Write-Host '' #Insert a blank line to make reading output easier on loops
	
	#endregion FunctionSetup

	#region FunctionWork

	#Declare our report
	$Global:ProgressReport = @()
	$Global:ThisReport = @()


	$Global:ReportFilename=".\$Title - $StartDate.html"
	#Import the attributes
	$Global:ProgressReport | add-member -MemberType NoteProperty -Name "Title"-Value "$title" -Force
	$Global:ProgressReport | add-member -MemberType NoteProperty -Name "StartDate"-Value "$StartDate" -Force
	#$Global:ProgressReport | add-member -MemberType NoteProperty -Name "Filename"-Value "$Filename" -Force

}


Function Export-HTMLReport
{
	<#
			.SYNOPSIS
			Grabs the data stored in the report object and converts it to HTML

			.DESCRIPTION
			Grabs the data stored in the report object and converts it to HTML

			.EXAMPLE
			Export-HTMLReport

			.INPUTS
			This function accepts no inputs

			.REQUIRED FUNCTIONS
			Write-Log: https://github.com/Atreidae/PowerShell-Functions/blob/main/New-Office365User.ps1
			AzureAD (Install-Module AzureAD) 
			Connect-MsolService

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Functions

			.ACKNOWLEDGEMENTS

			.NOTES
			Version:		1.0
			Date:			25/11/2020

			.VERSION HISTORY
			1.0: Initial Public Release

	#>

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Position=1)] [string]$EndDate=(Get-Date -format dd.MM.yy.hh.mm)
	)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Export-HTMLReport'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = "Unknown"
	$return.Message = "Function did not return a status message"

	# Log why we were called
	Write-Log -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-Log -Message "Parameters" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$Args" -Severity 1 -Component $function -LogOnly
	Write-Host '' #Insert a blank line to make reading output easier on loops
	
	#endregion FunctionSetup

	#region FunctionWork

	#Import the end time
	$Global:ProgressReport | add-member -MemberType NoteProperty -Name "EndDate"-Value "$EndDate" -Force

#$Report = ($PSCommandPath -replace '.ps1',"$ReportDate.html")

	#Define the HTML Style
	$Style = @"
<style>
BODY{background-color::#b0c4de;font-family:Tahoma;font-size:12pt;}
TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;color:white;background-color:#000099}
TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;text-align:center;}
</style>"
"@


	Try #Export the report
	{
		$Global:ProgressReport | ConvertTo-Html -head $Style -body "<h1> $($Global:ProgressReport.Title) </h1> The following report was started at $($Global:ProgressReport.StartDate) and finishes at $($Global:ProgressReport.EndDate)" | ForEach-Object {
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
		} | Out-File $Global:ReportFilename

		#Open Browser
		invoke-Item $Global:ReportFilename

		$Return.Status = "OK"
		$Return.Message = "HTML Report "
		Return $Return
	}
	Catch
	{
		#endregion FunctionWork
		Write-Log -Message "Unexpected error when generating HTML report" -Severity 3 -Component $function
		Write-Log -Message "$error[0]" -Severity 2 -Component $function
	}
}


Function New-HTMLReportStep
{
	<#
			.SYNOPSIS
			Adds a new Object to the HTML Report

			.DESCRIPTION
			Adds a new Object to the HTML Report

			.EXAMPLE
			New-HTMLReportStep -Stepname "Enable User" -StepResult "OK: Created User"

			.INPUTS
			This function accepts no inputs

			.REQUIRED FUNCTIONS
			Write-Log: https://github.com/Atreidae/PowerShell-Functions/blob/main/New-Office365User.ps1
			AzureAD (Install-Module AzureAD) 
			Connect-MsolService

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Functions

			.ACKNOWLEDGEMENTS

			.NOTES
			Version:		1.0
			Date:			25/11/2020

			.VERSION HISTORY
			1.0: Initial Public Release

	#>

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1)] $StepName, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2)] $StepResult
	)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'New-HTMLReportStep'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = "Unknown"
	$return.Message = "Function did not return a status message"

	# Log why we were called
	Write-Log -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-Log -Message "Parameters" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$Args" -Severity 1 -Component $function -LogOnly
	Write-Host '' #Insert a blank line to make reading output easier on loops
	
	#endregion FunctionSetup

	#region FunctionWork

	$Global:ThisReport | add-member -MemberType NoteProperty -Name "$StepName"-Value "$StepResult" -Force

	# endregion FunctionWork

}


Function New-HTMLReportItem
{
	<#
			.SYNOPSIS
			Adds a new Line Object to the HTML Report

			.DESCRIPTION
			Adds a new Line Object to the HTML Report

			.EXAMPLE
			New-HTMLReportStep -LineTitle "Username" -LineMessage "bob@contoso.com"

			.INPUTS
			This function accepts no inputs

			.REQUIRED FUNCTIONS
			Write-Log: https://github.com/Atreidae/PowerShell-Functions/blob/main/New-Office365User.ps1
			AzureAD (Install-Module AzureAD) 
			Connect-MsolService

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/PowerShell-Functions

			.ACKNOWLEDGEMENTS

			.NOTES
			Version:		1.0
			Date:			25/11/2020

			.VERSION HISTORY
			1.0: Initial Public Release

	#>

	Param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=1)] $LineTitle, 
		[Parameter(ValueFromPipelineByPropertyName=$true, Mandatory, Position=2)] $LineMessage
	)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'New-HTMLReportLine'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = "Unknown"
	$return.Message = "Function did not return a status message"

	# Log why we were called
	Write-Log -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-Log -Message "Parameters" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
	Write-Log -Message "$Args" -Severity 1 -Component $function -LogOnly
	Write-Host '' #Insert a blank line to make reading output easier on loops
	
	#endregion FunctionSetup


	#Merge the current Item
	$Global:ProgressReport+= $Global:ThisReport

	#region FunctionWork

	$Global:ThisReport = @()
	$Global:ThisReport =  New-Object -TypeName PSobject  
	$Global:ThisReport | add-member -MemberType NoteProperty -Name "$LineTitle" -Value $LineMessage
	
}

