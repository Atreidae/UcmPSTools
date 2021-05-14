<#
		.SYNOPSIS
		This powershell script attempts to dot source all the modules in this repository.

		.DESCRIPTION
		Returns $True if no error was found

		.EXAMPLE
		Test-Importfunctions

		.INPUTS
		None

		.REQUIRED FUNCTIONS
		None

		.LINK
		http://www.UcMadScientist.com
		https://github.com/Atreidae/UcmPSTools

		.ACKNOWLEDGEMENTS
		Thanks to Adam the Automater for getting me started on Pipeline automation.
		Check out https://adamtheautomator.com/powershell-devops/ for more info!

		.NOTES
		Version:		1.0
		Date:			14/05/2021

		.VERSION HISTORY
		1.0: Initial Public Release

#>

	Param #No parameters
	(
		[Parameter(ValueFromPipelineByPropertyName=$true, Position=1)] [switch]$Private
	)

## Find all of the public functions
$publicFuncFolderPath = Join-Path -Path $PSScriptRoot -ChildPath 'public'

#Check there is actually files here
if ((Test-Path -Path $publicFuncFolderPath) -and ($publicFunctionNames = Get-ChildItem -Path $publicFuncFolderPath -Filter '*.ps1' | Select-Object PsPath))
{
	#Run through each file to import
	ForEach ($FunctionName in $publicFunctionNames)
	{
		#Import the fucntion
		Try
		{ 
			Write-host "Importing $FunctionName"
			.$FunctionName.PsPath
		}

		#Error during import
		Catch
		{
		Write-Error "Error importing $FunctionName"
		Return $False
		}
	}

}
#No files to import
else
{
	Write-Warning "No Public Modules to import, try with the Private flag set"
}

#Include importing the private functions
If ($private)
{
## Find all of the private functions
$publicFuncFolderPath = Join-Path -Path $PSScriptRoot -ChildPath 'private'

#Check there is actually files here
if ((Test-Path -Path $publicFuncFolderPath) -and ($publicFunctionNames = Get-ChildItem -Path $publicFuncFolderPath -Filter '*.ps1' | Select-Object PsPath))
{
	#Run through each file to import
	ForEach ($FunctionName in $publicFunctionNames)
	{
		#Import the fucntion
		Try
		{ 
			Write-host "Importing $FunctionName"
			.$FunctionName.PsPath
		}

		#Error during import
		Catch
		{
		Write-Error "Error importing $FunctionName"
		Return $False
		}
	}

}
#No files to import
else
{
	Write-Warning "No Private Modules to import"
}
}

#Return true if we didnt catch anything
Return $True
