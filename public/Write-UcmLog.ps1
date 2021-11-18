#PerformScriptSigning
Function Write-UcmLog {
	<#
			.SYNOPSIS
			Function to output messages to the console based on their severity and create log files

			.DESCRIPTION
			It's a logger.

			.PARAMETER Message
			The message to write

			.PARAMETER Path
			The location of the logfile.

			.PARAMETER Severity
			Sets the severity of the log message, Higher severities will call Write-Warning or Write-Error

			.PARAMETER Component
			Used to track the module or function that called "Write-Log" 

			.PARAMETER LogOnly
			Forces Write-Log to not display anything to the user

			.EXAMPLE
			Write-Log -Message 'This is a log message' -Severity 3 -component 'Example Component'
			Writes a log file message and displays a warning to the user

			.REQUIRED FUNCTIONS
			None

			.LINK
			http://www.UcMadScientist.com
			https://github.com/Atreidae/UcmPsTools

			.INPUTS
			This function does not accept pipelined input

			.OUTPUTS
			This function does not create pipelined output

			.NOTES
			Version:		1.2
			Date:			18/11/2021

			.VERSION HISTORY
			1.1: Updated to "Ucm" naming convention
			Better inline documentation

			1.1: Bug Fix
			Resolved an issue where large logfiles would attempt to rename themselves to the same name causing errors when logs grew above 10MB

			1.0: Initial Public Release
	#>
	[CmdletBinding()]
	PARAM
	(
		[String]$Message,
		[String]$Path = $Script:LogFileLocation,
		[int]$Severity = 1,
		[string]$Component = 'Default',
		[switch]$LogOnly
	)
	$function = 'Write-UcmLog'
	$Date = Get-Date -Format 'HH:mm:ss'
	$Date2 = Get-Date -Format 'MM-dd-yyyy'
	$MaxLogFileSizeMB = 10

	#Check to see if the file exists
	If(Test-Path -Path $Path)
	{
		if(((Get-ChildItem -Path $Path).length/1MB) -gt $MaxLogFileSizeMB) # Check the size of the log file and archive if over the limit.
		{
			$ArchLogfile = $Path.replace('.log', "_$(Get-Date -Format dd-MM-yyy_hh-mm-ss).lo_")
			Rename-Item -Path $Path -NewName $ArchLogfile
		}
	}

	#Write to the log file
	"$env:ComputerName date=$([char]34)$Date2$([char]34) time=$([char]34)$Date$([char]34) component=$([char]34)$component$([char]34) type=$([char]34)$severity$([char]34) Message=$([char]34)$Message$([char]34)"| Out-File -FilePath $Path -Append -NoClobber -Encoding default

	#If LogOnly is not set, output the log entry to the screen
	If (!$LogOnly) 
	{
		#If the log entry is just Verbose (1), output it to write-verbose
		if ($severity -eq 1) 
		{
			"$Message"| Write-verbose
		}
		#If the log entry is just informational (2), output it to write-host
		if ($severity -eq 2) 
		{
			"INFO: $Message"| Write-Host -ForegroundColor Green
		}
		#If the log entry has a severity of 3 assume its a warning and write it to write-warning
		if ($severity -eq 3) 
		{
			"$Date $Message"| Write-Warning
		}
		#If the log entry has a severity of 4 or higher, assume its an error and display an error message (Note, critical errors are caught by throw statements so may not appear here)
		if ($severity -ge 4) 
		{
			"$Date $Message"| Write-Error
		}
	}
}