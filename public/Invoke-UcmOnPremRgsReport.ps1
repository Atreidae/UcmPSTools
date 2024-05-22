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
		Date:			20/05/2024

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
			[Parameter(Mandatory, Position=1)] [string]$Config,
			[Parameter(Mandatory, Position=2)] [array]$EvUsers
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
	$RGSConfig = (Import-UcmOnPremRgsConfig -Config $Config).RGSConfig
	$EvUsers = (import-csv $EvUsers)

	#expand-UcmRgsAgentGroup -RGSConfig $rgsconfig -groupguid 08b3ffec-e487-45ec-a1c9-04410055f799 -evusers $EvUsers


	#Find every workflow in workflows.xml and pass it to expand-ucmrgsworkflow
	$Workflows = @()
	$namespaces = @{ ns = 'http://schemas.microsoft.com/powershell/2004/04' }
	$Workflows = Select-Xml -Content $rgsconfig.Workflows.outerxml -XPath "//ns:Obj/ns:Props/ns:Obj/ns:Props/ns:G[@N='InstanceId']" -Namespace $namespaces

	Foreach ($Workflow in $Workflows)
	{
		$WorkFlowGUID = $Workflow.Node.'#text'
		$WorkFlow = (Expand-UcmRgsWorkFlow -RGSConfig $RGSConfig -WorkflowGUID $WorkFlowGUID)
		$WorkFlow
	}




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
		Version:		0.2
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

		.VERSION HISTORY

		0.2: Added Better XML Parsing instead of casting to [XML]
		https://stackoverflow.com/questions/65263942/how-to-load-or-read-an-xml-file-using-convertto-xml-and-select-xml#comment115380600_65263942

		0.1: Initial Release


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
				#[xml]$AgentGroupsXML = Get-Content -Path $ConfigFile.PSPath
				$RGSConfig.AgentGroups = New-Object xml
				$RGSConfig.AgentGroups.Load((Convert-path $ConfigFile.PSPath))
			}
			"Agents.xml"
			{

				$RGSConfig.Agents = New-Object xml
				$RGSConfig.Agents.Load((Convert-path $ConfigFile.PSPath))
			}
			"Configuration.xml"
			{
				$RGSConfig.Configuration = New-Object xml
				$RGSConfig.Configuration.Load((Convert-path $ConfigFile.PSPath))
			}
			"Holidaysets.xml"
			{
				$RGSConfig.HolidaySets = New-Object xml
				$RGSConfig.HolidaySets.Load((Convert-path $ConfigFile.PSPath))
			}
			"HoursOfBusiness.xml"
			{
				$RGSConfig.HoursOfBusiness = New-Object xml
				$RGSConfig.HoursOfBusiness.Load((Convert-path $ConfigFile.PSPath))
			}
			"Managers.xml"
			{
				$RGSConfig.Managers = New-Object xml
				$RGSConfig.Managers.Load((Convert-path $ConfigFile.PSPath))
			}
			"Queues.xml"
			{
				$RGSConfig.Queues = New-Object xml
				$RGSConfig.Queues.Load((Convert-path $ConfigFile.PSPath))
			}
			"Workflows.xml"
			{
				$RGSConfig.Workflows = New-Object xml
				$RGSConfig.Workflows.Load((Convert-path $ConfigFile.PSPath))
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

Function Expand-UcmRgsWorkflowAction {
<#
		.SYNOPSIS
		Provides a cleartext version of the RGS Workflow Action or a GUID of transfer target

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


	#>

	Param
		(
			[Parameter(Mandatory, Position=1)] $RgsActionNode,
			[Parameter(Mandatory, Position=1)] $RGSConfig
		)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Expand-UcmRgsWorkFlowAction'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = "OK"
	$return.Message = "Function did not return a status message"

	#skipping my function setup as it's expensive and this operation runs alot

	#endregion FunctionSetup
	$node = $RgsActionNode
	$RgsAction = ($node.props.s."#text"[0])

	switch ($RgsAction)
	{
		"TransferToPSTN"
		{
			#old $Target = ($RgsAction -match "(sip:\+\d*)@")
			$target = ($node.props.s."#text"[1])
			$Return.Action = "TransferToPSTN"
			$Return.Target = $Target
			$Return.Text = "Transfer to PSTN $($Target)"
			Return $Return
		}
		"TransferToVoicemailUri"
		{
			$Return.Action = "TransferToVoicemailUri"
			#$Target = ($RgsAction -match "(sip:.*)")
			$target = ($node.props.s."#text"[1])
			$Return.Target = $Target
			$Return.Text = "Transfer to $($Target) Voicemail"
			Return $Return
		}
		"TransferToQueue"
		{
			$Return.Action = "TransferToQueue"
			#$Target = ($RgsAction -match "QueueId=(.*)")
			$target = ($node.props.obj.props.g."#text")
			$Return.Target = $Target
			# get the plaintext name of the queue
				$Queue = (Select-Xml -Content $rgsconfig.Queues.outerxml -XPath "//ns:Obj[ns:Props/ns:Obj/ns:Props/ns:G[@N='InstanceId'] = '$Target']" -Namespace $namespace)
				$Return.Text = "$($Return.Action) $($Queue.node.props.s[1]."#text") $target"

			#$Return.Text = "Transfer to Queue $($Queue.node.props.s[1]."#text")"
			Return $Return
		}
		"TransferToAgent"
		{
			$return.Status = "Error"
			$return.Message = "Action not implemented, Please raise an issue on GitHub"
			$Return.Action = $RgsAction
			Return $Return
		}
		"Terminate"
		{
			$Return.Action = "Terminate"
			$Return.Target = "Terminate"
			$Return.Text = "Hangup Call"
			Return $Return
		}
		"Prompt"
		{
				#todo. Look for "CallAction and decode it"
			$Return.Action = "MenuPrompt"
			$return.Message = "Action not implemented, Please raise an issue on GitHub"
			$Return.Target = "Unknown"
			$Return.Text = "Prompt - Action not implemented. Please raise an issue on GitHub"
			Return $Return
		}
		"TransferToQuestion"
		{
			$Return.Action = "TransferToQuestion"
			$Return.Target = "Unknown"
			$Return.Text = "Transfer to Question - Action not implemented. Please raise an issue on GitHub"
			Return $Return
		}
		"TransferToUri"
		{
			$Target = ($node.props.s."#text"[1])
			$Return.Action = "TransferToUri"
			$Return.Target = $Target
			$Return.Text = "Transfer to URI $($Target)"
			Return $Return
		}
		Default
		{
			$return.Status = "Error"
			$return.Message = "Action not implemented, Please raise an issue on GitHub"
			$Return.Action = $RgsAction
			Return $Return
		}
	}
}

Function Expand-UcmRgsWorkFlow {
	<#
		.SYNOPSIS
		Finds the details of the requested RGS workflow.

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


	#>

	Param
		(
			[Parameter(Mandatory, Position=1)] [hashtable]$RGSConfig,
			[Parameter(Mandatory, Position=2)] [string]$WorkflowGUID
		)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Expand-UcmRgsWorkFlow'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = "Unknown"
	$return.Message = "Function did not return a status message"

	#skipping my function setup as it's expensive and this operation runs alot

	#endregion FunctionSetup

	#define the namespace for the XML and find the node we want
	$namespace = @{ ns = 'http://schemas.microsoft.com/powershell/2004/04' }
	$Workflow = (Select-Xml -Content $rgsconfig.Workflows.outerxml -XPath "//ns:Obj[ns:Props/ns:Obj/ns:Props/ns:G[@N='InstanceId'] = '$WorkflowGUID']" -Namespace $namespace)

	#Check we actually have the group and start filling the object
	if ($null -eq $Workflow.node)
	{
		Write-UcmLog -Message "Workflow $WorkflowGUID not found" -Severity 3 -Component $function
		$return.Status = "Error"
		$return.Message = "Workflow $WorkflowGUID not found"
		Return $return
	}
		$WorkFlowObj = @{}
		#Find the workflow and details

		Foreach ($Prop in $Workflow.node.props.s)
		{
			Switch ($Prop.N)
			{
				"Name"
				{
					$WorkFlowObj.Name = $Prop."#text"
				}
				"Description"
				{
					$WorkFlowObj.Description = $Prop."#text"
				}
				"LineUri"
				{
					$WorkFlowObj.LineUri = $Prop."#text"
				}
			}
		}

		#Check all the actions in the workflow
		Foreach ($Node in $workflow.node.Props.obj)
		{
			$ExpandedAction = @{}

			switch ($Node.N)
			{
				"HolidayAction"
				{
					$ExpandedAction = (Expand-UcmRgsWorkflowAction -RgsActionNode $node -RGSConfig $RGSConfig)
					$WorkFlowObj.HolidayText = "$($ExpandedAction.Text)"
					$WorkFlowObj.HolidayAction = "$($ExpandedAction.Action)"
					$WorkFlowObj.HolidayTarget = "$($ExpandedAction.Target)"
				}
				"NonBusinessHoursAction"
				{
					$ExpandedAction = (Expand-UcmRgsWorkflowAction -RgsActionNode $node -RGSConfig $RGSConfig)
					$WorkFlowObj.OOOText = "$($ExpandedAction.Text)"
					$WorkFlowObj.OOOAction = "$($ExpandedAction.Action)"
					$WorkFlowObj.OOOTarget = "$($ExpandedAction.Target)"
				}
				"DefaultAction"
				{
					$ExpandedAction = (Expand-UcmRgsWorkflowAction -RgsActionNode $node -RGSConfig $RGSConfig)
					$WorkFlowObj.DefaultText = "$($ExpandedAction.Text)"
					$WorkFlowObj.DefaultAction = "$($ExpandedAction.Action)"
					$WorkFlowObj.DefaultTarget = "$($ExpandedAction.Target)"
				}
			}

			if ($ExpandedAction.Status -eq "Error")
					{
						Write-UcmLog -Message "Error expanding HolidayAction $($Node.props.s."#text")" -Severity 3 -Component $function
						$WorkFlowObj.HolidayAction = "Error expanding HolidayAction $($Node.props.s."#text")"
					}

		}


		Return $WorkFlowObj | sort-object Name
	}

Function Expand-UcmRgsAgentGroup {
	<#
		.SYNOPSIS
		Grab the imported RGS XML Config and finds all the agent groups in it

		.DESCRIPTION
		#todo

		.PARAMETER
		GroupGuid

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

		XML XPATH for agent groups /a:Objs/a:Obj[2]/a:ToString/text()
		Namespace $rgsconfig.agentgroups.objs.xmlns

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
			[Parameter(Mandatory, Position=1)] [hashtable]$RGSConfig,
			[Parameter(Mandatory, Position=2)] [string]$groupGUID,
			[Parameter(Mandatory, Position=3)] [array]$evusers

		)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Expand-UcmRgsAgentGroup'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = "Unknown"
	$return.Message = "Function did not return a status message"

	#skipping my function setup as it's expensive and this operation runs alot

	#endregion FunctionSetup

	#define the namespace for the XML and find the node we want
	$namespace = @{ ns = 'http://schemas.microsoft.com/powershell/2004/04' }
	$Agentgroup = (Select-Xml -Content $rgsconfig.agentgroups.outerxml -XPath "//ns:Obj[ns:Props/ns:Obj/ns:Props/ns:S[@N='NonNormalized'] = '$groupGUID']" -Namespace $namespace)

	#Check we actually have the group and start filling the object
	if ($null -eq $Agentgroup.node)
	{
		Write-UcmLog -Message "Agent Group $groupGUID not found" -Severity 3 -Component $function
		$return.Status = "Error"
		$return.Message = "Agent Group $groupGUID not found"
		Return $return
	}


		$AgentGroupObj = @{}
		#Find the group name and description

		Foreach ($Prop in $AgentGroup.node.props.s)
		{
			Switch ($Prop.N)
			{
				"Name"
				{
					$AgentGroupObj.Name = $Prop."#text"
				}
				"Description"
				{
					$AgentGroupObj.Description = $Prop."#text"
				}
			}
		}

		#Get the users in the group
		$AgentGroupObj.Users = $AgentGroup.node.props.obj.lst.uri

		#Check to see if the group actually contains users
		if ($null -eq $AgentGroupObj.Users)
		{
			Write-UcmLog -Message "Agent Group $($AgentGroupObj.Name) has no users" -Severity 2 -Component $function
			$UserObj = [PSCustomObject]@{
				Name    	= "This Group Contains No Users"
				SipAddress	= "None"
				Number    	= "None"
				NumberRange = "None"
			}
			$AgentGroupObj.Users = $UserObj
		}
		else
		{
			#Add the users numbers to the object
			$AgentGroupObj.Users = (Expand-UcmRgsAgentNumber -Agentusers $AgentGroupObj.Users -evusers $evusers)
		}

		$AgentGroupObj

}


Function Expand-UcmRgsAgentNumber {
	<#
		.SYNOPSIS
		Reads the provided user list and returns a modified object with the numbers attached to each user

		.DESCRIPTION
		#todo

		.PARAMETER
		#todo

		.EXAMPLE
		#todo

		.INPUTS
		This function does not accept any input

		.OUTPUTS
		This Cmdet does not output anything to the pipeline #todo

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
			[Parameter(Mandatory, Position=1)] $Agentusers,
			[Parameter(Mandatory, Position=2)] $EvUsers
		)

	#skipping my function setup as it's expensive and this operation runs alot

	foreach ($AgentUser in $AgentUsers)
	{
		#find the user and store it in a temp variable
		$Result 		= ($evusers | Where-Object SipAddress -eq $AgentUser)
		#Get the number from the LineURI
		if ($null -eq $Result.LineUri)
		{
			$Number 		= "No LineURI"
			$NumberRange 	= "None"
			Write-UcmLog -Message "User $($Result.Name) has no phone number!" -Severity 2 -Component $function
		}
		else
		{
			$Number 		= $Result.LineUri.substring(4,$result.lineuri.length-4)
			$NumberRange	= ($Number.substring(0,$Number.length-2)+"XX")
		}

		#Create a new object with the user details
		$UserObj = [PSCustomObject]@{
			Name    	= $Result.Name
			SipAddress	= $Result.SipAddress
			Number    	= $Number
			NumberRange = $NumberRange
		}
		#Return the object
		$UserObj
	}

}

