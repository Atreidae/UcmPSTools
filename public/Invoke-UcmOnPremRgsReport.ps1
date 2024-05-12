Function Invoke-UcmOnPremRgsReport {
	<#
		.SYNOPSIS
		Reads an exported RGS config file and returns a summary of the contents, specifically, number ranges.

		.DESCRIPTION
		#todo

		.PARAMETER Config (Required)
		Filename of the exported RGS config file to be read


		.EXAMPLE
		#todo

		.INPUTS
		This function does not accept any input

		.OUTPUTS
		This Cmdet does not output anything to the pipeline

		.LINK
		http://www.UcMadScientist.com
		https://github.com/Atreidae/UcmPsTools

		.ACKNOWLEDGEMENTS
		#todo

		.NOTES
		Version:		1.0
		Date:			10/05/2024

		.VERSION HISTORY
		1.0: Initial Public Release

		.REQUIRED FUNCTIONS/MODULES
		Modules
		Lync/SkypeforBusiness				(From your Lync/Skype installation media)
		UcmPSTools							(Install-Module UcmPsTools) Includes Cmdlets below.

		Cmdlets
		Write-UcmLog: 						https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-UcmLog.ps1

		.REQUIRED PERMISIONS
		#todo

#>

	Param
		(
			[Parameter(Mandatory, Position=1)] [string]$Config
		)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Invoke-UcmOnPremRgsReport'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = "Unknown"
	$return.Message = "Function did not return a status message"

	# Log why we were called
	Write-UcmLog -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-UcmLog -Message "Parameters" -Severity 3 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$Args" -Severity 1 -Component $function -LogOnly

	#endregion FunctionSetup

	#region FunctionWork

	#endregion FunctionReturn
}



Function Import-UcmOnPremRgsConfig {
	<#
		.SYNOPSIS
		Reads an exported RGS config file and returns a summary of the contents, specifically, number ranges.

		.DESCRIPTION
		#todo

		.PARAMETER Config (Required)
		Filename of the exported RGS config file to be read


		.EXAMPLE
		#todo

		.INPUTS
		This function does not accept any input

		.OUTPUTS
		This Cmdet does not output anything to the pipeline

		.LINK
		http://www.UcMadScientist.com
		https://github.com/Atreidae/UcmPsTools

		.ACKNOWLEDGEMENTS
		#todo

		.NOTES
		Version:		1.0
		Date:			10/05/2024

		.VERSION HISTORY
		1.0: Initial Public Release

		.REQUIRED FUNCTIONS/MODULES
		Modules
		Lync/SkypeforBusiness				(From your Lync/Skype installation media)
		UcmPSTools							(Install-Module UcmPsTools) Includes Cmdlets below.

		Cmdlets
		Write-UcmLog: 						https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-UcmLog.ps1

		.REQUIRED PERMISIONS
		#todo

#>

	Param
		(
			[Parameter(Mandatory, Position=1)] [string]$Config
		)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Import-UcmOnPremRgsConfig'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = "Unknown"
	$return.Message = "Function did not return a status message"

	# Log why we were called
	Write-UcmLog -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-UcmLog -Message "Parameters" -Severity 3 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$Args" -Severity 1 -Component $function -LogOnly

	#endregion FunctionSetup

	#region FunctionWork

	If (Test-Path -Path $Config) #File Exists, Check it
	#unzip the config file into a temp folder
	{
		Write-UcmLog -Message "Decompressing Config File and Importing XML Data" -Severity 2 -Component $function
		Remove-Item -Path $env:temp\RgsConfig -Recurse -Force -ErrorAction SilentlyContinue
		$TempFolder = New-Item -ItemType Directory -Path $env:temp -Name "RgsConfig"
		Expand-Archive -Path $Config -DestinationPath $TempFolder.FullName
		$ConfigFiles = Get-ChildItem -Path $TempFolder.FullName -Recurse -Include *.xml
	}
	Else
	{
		Write-UcmLog -Message "Config file not found" -Severity 3 -Component $function
		$return.Status = "Error"
		$return.Message = "Config file not found"
		Return $return
	}
	$RGSConfig = @{}
	Foreach ($ConfigFile in $ConfigFiles)
	{
		switch ($ConfigFile.Name)
		{
			"AgentGroups.xml"
			{
				[xml]$AgentGroupsXML = Get-Content -Path $ConfigFile.PSPath
				$RGSConfig.AgentGroups = $AgentGroupsXML
			}
			"Agents.xml"
			{
				 [xml]$AgentsXML = Get-Content -Path $ConfigFile.PSPath
				 $RGSConfig.Agents = $AgentsXML
			}
			"Configuration.xml"
			{
				[xml]$ConfigurationXML = Get-Content -Path $ConfigFile.PSPath
				$RGSConfig.Configuration = $ConfigurationXML
			}
			"Holidaysets.xml"
			{
				[xml]$HolidaysetsXML = Get-Content -Path $ConfigFile.PSPath
				$RGSConfig.Holidaysets = $HolidaysetsXML
			}
			"HoursOfBusiness.xml"
			{
				[xml]$HoursOfBusinessXML = Get-Content -Path $ConfigFile.PSPath
				$RGSConfig.HoursOfBusiness = $HoursOfBusinessXML
			}
			"Managers.xml"
			{
				[xml]$ManagersXML = Get-Content -Path $ConfigFile.PSPath
				$RGSConfig.Managers = $ManagersXML
			}
			"Queues.xml"
			{
				[xml]$QueuesXML = Get-Content -Path $ConfigFile.PSPath
				$RGSConfig.Queues = $QueuesXML
			}
			"Workflows.xml"
			{
				[xml]$WorkflowsXML = Get-Content -Path $ConfigFile.PSPath
				$RGSConfig.Workflows = $WorkflowsXML
			}
			Default
			{
				Write-UcmLog -Message "Unknown XML File found in Config" -Severity 3 -Component $function
				$return.Status = "Error"
				$return.Message = "Unknown XML File found in Config"
				Return $return
			}
		}

	}
	#endregion FunctionWork
	$Return.RGSConfig = $RGSConfig
	$Return.Status = "Success"
	Return $Return
	#endregion FunctionReturn
}


Function Expand-UcmRgsAgentGroups {
	<#
		.SYNOPSIS
		Grab the imported RGS XML Config and finds all the agent groups in it

		.DESCRIPTION
		#todo

		.PARAMETER
		#todo

		.EXAMPLE
		#todo

		.INPUTS
		This function does not accept any input

		.OUTPUTS
		This Cmdet does not output anything to the pipeline

		.LINK
		http://www.UcMadScientist.com
		https://github.com/Atreidae/UcmPsTools

		.ACKNOWLEDGEMENTS
		#todo

		.NOTES
		Version:		1.0
		Date:			10/05/2024

		.VERSION HISTORY
		1.0: Initial Public Release

		.REQUIRED FUNCTIONS/MODULES
		Modules
		Lync/SkypeforBusiness				(From your Lync/Skype installation media)
		UcmPSTools							(Install-Module UcmPsTools) Includes Cmdlets below.

		Cmdlets
		Write-UcmLog: 						https://github.com/Atreidae/UcmPsTools/blob/main/public/Write-UcmLog.ps1

		.REQUIRED PERMISIONS
		#todo

#>

	Param
		(
			[Parameter(Mandatory, Position=1)] [hashtable]$RGSConfig
		)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Expand-UcmRgsAgentGroups'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = "Unknown"
	$return.Message = "Function did not return a status message"

	# Log why we were called
	Write-UcmLog -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-UcmLog -Message "Parameters" -Severity 3 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "Parameters Values" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "Optional Arguments" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$Args" -Severity 1 -Component $function -LogOnly

	#endregion FunctionSetup

	#Get the Agent Groups
	$AgentGroupsXML = $RGSConfig.AgentGroups.Objs.obj

	foreach ($AgentGroupXML in $AgentGroupsXML)
	{
		$AgentGroupObj = @{}
		$AgentGroupObj.Name = $AgentGroupXML.props.s."#text"[1]
		$AgentGroupObj.Decription = $AgentGroupXML.props.s."#text"[2]
		$AgentGroupObj.Users = $AgentGroupXML.props.obj.lst.uri
		$AgentGroupObj
	}
}

