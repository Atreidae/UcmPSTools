Function Invoke-UcmOnPremRgsReport
{
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
		[Parameter(Mandatory, Position = 1)] [string]$Config,
		[Parameter(Mandatory, Position = 2)] [array]$EvUsers
	)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Invoke-UcmOnPremRgsReport'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = 'Unknown'
	$return.Message = 'Function did not return a status message'

	# Log why we were called
	Write-UcmLog -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-UcmLog -Message 'Parameters' -Severity 3 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message 'Parameters Values' -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message 'Optional Arguments' -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$Args" -Severity 1 -Component $function -LogOnly

	#endregion FunctionSetup

	#region FunctionWork
	$RGSConfig = (Import-UcmOnPremRgsConfig -Config $Config).RGSConfig
	$EvUsers = (Import-Csv $EvUsers)

	#expand-UcmRgsAgentGroup -RGSConfig $rgsconfig -groupguid 08b3ffec-e487-45ec-a1c9-04410055f799 -evusers $EvUsers


	#Find every workflow in workflows.xml and pass it to expand-ucmrgsworkflow
	$Workflows = @()
	$namespaces = @{ ns = 'http://schemas.microsoft.com/powershell/2004/04' }
	$WorkflowsXml = Select-Xml -Content $rgsconfig.Workflows.outerxml -XPath "//ns:Obj/ns:Props/ns:Obj/ns:Props/ns:G[@N='InstanceId']" -Namespace $namespaces

	Foreach ($WorkflowXml in $WorkflowsXML)
	{
		$WorkFlowGUID = $WorkflowXml.Node.'#text'
		$WorkFlow = (Expand-UcmRgsWorkFlow -RGSConfig $RGSConfig -WorkflowGUID $WorkFlowGUID)
		$WorkFlows += $WorkFlow
	}

	#temp code, export all groups to a csv
	$AgentGroups = @()
	$namespaces = @{ ns = 'http://schemas.microsoft.com/powershell/2004/04' }
	$AgentGroupsXml = Select-Xml -Content $rgsconfig.AgentGroups.outerxml -XPath "//ns:Obj/ns:Props/ns:Obj/ns:Props/ns:S[@N='NonNormalized']" -Namespace $namespaces

	Foreach ($AgentGroupXML in $AgentGroupsXML)
	{
		$AgentGroupGUID = $AgentGroupXML.Node.'#text'
		$AgentGroup = (Expand-UcmRgsAgentGroup -RGSConfig $RGSConfig -groupGUID $AgentGroupGUID -evusers $EvUsers)
		$AgentGroups += $AgentGroup
	}



	#endregion FunctionReturn
}



Function Import-UcmOnPremRgsConfig
{
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
		[Parameter(Mandatory, Position = 1)] [string]$Config
	)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Import-UcmOnPremRgsConfig'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = 'Unknown'
	$return.Message = 'Function did not return a status message'

	# Log why we were called
	Write-UcmLog -Message "$($MyInvocation.InvocationName) called with $($MyInvocation.Line)" -Severity 1 -Component $function
	Write-UcmLog -Message 'Parameters' -Severity 3 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Keys)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message 'Parameters Values' -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$($PsBoundParameters.Values)" -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message 'Optional Arguments' -Severity 1 -Component $function -LogOnly
	Write-UcmLog -Message "$Args" -Severity 1 -Component $function -LogOnly

	#endregion FunctionSetup

	#region FunctionWork

	If (Test-Path -Path $Config) #File Exists, Check it
	#unzip the config file into a temp folder
	{
		Write-UcmLog -Message 'Decompressing Config File and Importing XML Data' -Severity 2 -Component $function
		Remove-Item -Path $env:temp\RgsConfig -Recurse -Force -ErrorAction SilentlyContinue
		$TempFolder = New-Item -ItemType Directory -Path $env:temp -Name 'RgsConfig'
		Expand-Archive -Path $Config -DestinationPath $TempFolder.FullName
		$ConfigFiles = Get-ChildItem -Path $TempFolder.FullName -Recurse -Include *.xml
	}
	Else
	{
		Write-UcmLog -Message 'Config file not found' -Severity 3 -Component $function
		$return.Status = 'Error'
		$return.Message = 'Config file not found'
		Return $return
	}
	$RGSConfig = @{}
	Foreach ($ConfigFile in $ConfigFiles)
	{
		switch ($ConfigFile.Name)
		{
			'AgentGroups.xml'
			{
				#[xml]$AgentGroupsXML = Get-Content -Path $ConfigFile.PSPath
				$RGSConfig.AgentGroups = New-Object xml
				$RGSConfig.AgentGroups.Load((Convert-Path $ConfigFile.PSPath))
			}
			'Agents.xml'
			{

				$RGSConfig.Agents = New-Object xml
				$RGSConfig.Agents.Load((Convert-Path $ConfigFile.PSPath))
			}
			'Configuration.xml'
			{
				$RGSConfig.Configuration = New-Object xml
				$RGSConfig.Configuration.Load((Convert-Path $ConfigFile.PSPath))
			}
			'Holidaysets.xml'
			{
				$RGSConfig.HolidaySets = New-Object xml
				$RGSConfig.HolidaySets.Load((Convert-Path $ConfigFile.PSPath))
			}
			'HoursOfBusiness.xml'
			{
				$RGSConfig.HoursOfBusiness = New-Object xml
				$RGSConfig.HoursOfBusiness.Load((Convert-Path $ConfigFile.PSPath))
			}
			'Managers.xml'
			{
				$RGSConfig.Managers = New-Object xml
				$RGSConfig.Managers.Load((Convert-Path $ConfigFile.PSPath))
			}
			'Queues.xml'
			{
				$RGSConfig.Queues = New-Object xml
				$RGSConfig.Queues.Load((Convert-Path $ConfigFile.PSPath))
			}
			'Workflows.xml'
			{
				$RGSConfig.Workflows = New-Object xml
				$RGSConfig.Workflows.Load((Convert-Path $ConfigFile.PSPath))
			}
			Default
			{
				Write-UcmLog -Message 'Unknown XML File found in Config' -Severity 3 -Component $function
				$return.Status = 'Error'
				$return.Message = 'Unknown XML File found in Config'
				Return $return
			}
		}

	}
	#endregion FunctionWork
	$Return.RGSConfig = $RGSConfig
	$Return.Status = 'Success'
	Return $Return
	#endregion FunctionReturn
}

Function Expand-UcmRgsWorkflowAction
{
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
		[Parameter(Mandatory, Position = 1)] $RgsActionNode,
		[Parameter(Mandatory, Position = 1)] $RGSConfig
	)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Expand-UcmRgsWorkFlowAction'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = 'OK'
	$return.Message = 'Function did not return a status message'

	#skipping my function setup as it's expensive and this operation runs alot

	#endregion FunctionSetup
	$node = $RgsActionNode
	$RgsAction = ($node.props.s.'#text'[0])

	switch ($RgsAction)
	{
		'TransferToPSTN'
		{
			#old $Target = ($RgsAction -match "(sip:\+\d*)@")
			$target = ($node.props.s.'#text'[1])
			$Return.Action = 'TransferToPSTN'
			$Return.Target = $Target
			$Return.Text = "Transfer to PSTN $($Target)"
			Return $Return
		}
		'TransferToVoicemailUri'
		{
			$Return.Action = 'TransferToVoicemailUri'
			#$Target = ($RgsAction -match "(sip:.*)")
			$target = ($node.props.s.'#text'[1])
			$Return.Target = $Target
			$Return.Text = "Transfer to $($Target) Voicemail"
			Return $Return
		}
		'TransferToQueue'
		{
			$Return.Action = 'TransferToQueue'
			#$Target = ($RgsAction -match "QueueId=(.*)")
			$target = ($node.props.obj.props.g.'#text')
			$Return.Target = $Target
			# get the plaintext name of the queue
			$Queue = (Select-Xml -Content $rgsconfig.Queues.outerxml -XPath "//ns:Obj[ns:Props/ns:Obj/ns:Props/ns:G[@N='InstanceId'] = '$Target']" -Namespace $namespace)
			$Return.Text = "$($Return.Action) $($Queue.node.props.s[1].'#text') $target"

			#$Return.Text = "Transfer to Queue $($Queue.node.props.s[1]."#text")"
			Return $Return
		}
		'TransferToAgent'
		{
			$return.Status = 'Error'
			$return.Message = 'Action not implemented, Please raise an issue on GitHub'
			$Return.Action = $RgsAction
			Return $Return
		}
		'Terminate'
		{
			$Return.Action = 'Terminate'
			$Return.Target = 'Terminate'
			$Return.Text = 'Hangup Call'
			Return $Return
		}
		'Prompt'
		{
			#todo. Look for "CallAction and decode it"
			$Return.Action = 'MenuPrompt'
			$return.Message = 'Action not implemented, Please raise an issue on GitHub'
			$Return.Target = 'Unknown'
			$Return.Text = 'Prompt - Action not implemented. Please raise an issue on GitHub'
			Return $Return
		}
		'TransferToQuestion'
		{
			$Return.Action = 'TransferToQuestion'
			$Return.Target = 'Unknown'
			$Return.Text = 'Transfer to Question - Action not implemented. Please raise an issue on GitHub'
			Return $Return
		}
		'TransferToUri'
		{
			$Target = ($node.props.s.'#text'[1])
			$Return.Action = 'TransferToUri'
			$Return.Target = $Target
			$Return.Text = "Transfer to URI $($Target)"
			Return $Return
		}
		Default
		{
			$return.Status = 'Error'
			$return.Message = 'Action not implemented, Please raise an issue on GitHub'
			$Return.Action = $RgsAction
			Return $Return
		}
	}
}

Function Expand-UcmRgsWorkFlow
{
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
		[Parameter(Mandatory, Position = 1)] [hashtable]$RGSConfig,
		[Parameter(Mandatory, Position = 2)] [string]$WorkflowGUID
	)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Expand-UcmRgsWorkFlow'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = 'Unknown'
	$return.Message = 'Function did not return a status message'

	#skipping my function setup as it's expensive and this operation runs alot

	#endregion FunctionSetup
	$WorkflowObj = [PSCustomObject]@{
		Name        = "Unknown"
		Description = "Unknown"
		IsInteractive = $false
		AllGroups	    = @()
		AllNumberRanges = @()
		OwnerPool	= "Unknown"
		LineURI  = "Unknown"
		DefaultPlainText    = "Unknown"
		DefaultAction = "Unknown"
		DefaultTarget = "Unknown"
		DefaultQueue = "Unknown"
		DefaultGroups = @()
		DefaultUsers = @()
		DefaultNumberRanges = @()
		DefaultNumbers = @()
		HolidayPlainText    = "Unknown"
		HolidayAction = "Unknown"
		HolidayTarget = "Unknown"
		HolidayQueue = "Unknown"
		HolidayGroups = @()
		HolidayUsers = @()
		HolidayNumberRanges = @()
		OooPlainText    = "Unknown"
		OooAction = "Unknown"
		OooTarget = "Unknown"
		OooQueue = "Unknown"
		OooGroups = @()
		OooUsers = @()
		OooNumberRanges = @()
	}

	#define the namespace for the XML and find the node we want
	$namespace = @{ ns = 'http://schemas.microsoft.com/powershell/2004/04' }
	$WorkflowXML = (Select-Xml -Content $rgsconfig.Workflows.outerxml -XPath "//ns:Obj[ns:Props/ns:Obj/ns:Props/ns:G[@N='InstanceId'] = '$WorkflowGUID']" -Namespace $namespace)

	#Check we actually have the group and start filling the object
	if ($null -eq $WorkflowXML.node)
	{
		Write-UcmLog -Message "Workflow $WorkflowGUID not found" -Severity 3 -Component $function
		$return.Status = 'Error'
		$return.Message = "Workflow $WorkflowGUID not found"
		Return $return
	}

	Foreach ($Prop in $WorkflowXML.node.props.s)
	{
		Switch ($Prop.N)
		{
			'Name'
			{
				$WorkFlowObj.Name = $Prop.'#text'
			}
			'Description'
			{
				$WorkFlowObj.Description = $Prop.'#text'
			}
			'LineUri'
			{
				$WorkFlowObj.LineUri = $Prop.'#text'
			}
		}
	}

	#Check all the actions in the workflow
	Foreach ($Node in $workflowXML.node.Props.obj)
	{
		$ExpandedAction = @{}

		switch ($Node.N)
		{
			'HolidayAction'
			{
				$ExpandedAction = (Expand-UcmRgsWorkflowAction -RgsActionNode $node -RGSConfig $RGSConfig)
				$WorkFlowObj.HolidayPlainText = "$($ExpandedAction.Text)"
				$WorkFlowObj.HolidayAction = "$($ExpandedAction.Action)"
				$WorkFlowObj.HolidayTarget = "$($ExpandedAction.Target)"
				#if the action is a queue, expand it
				if ($ExpandedAction.Action -eq 'TransferToQueue')
				{
					$WorkFlowObj.HolidayQueue = (Expand-UcmRgsQueue -RGSConfig $RGSConfig -QueueGUID $ExpandedAction.Target)
					$Workflowobj.HolidayGroups = $WorkFlowObj.HolidayQueue.Groups
					$Workflowobj.HolidayUsers = $WorkFlowObj.HolidayQueue.Users
					$Workflowobj.HolidayNumberRanges = $WorkflowObj.HolidayQueue.groups.users.numberrange
					$Workflowobj.HolidayNumbers = $WorkflowObj.HolidayQueue.groups.users.number
				}


			}
			'NonBusinessHoursAction'
			{
				$ExpandedAction = (Expand-UcmRgsWorkflowAction -RgsActionNode $node -RGSConfig $RGSConfig)
				$WorkFlowObj.OOOPlainText = "$($ExpandedAction.Text)"
				$WorkFlowObj.OOOAction = "$($ExpandedAction.Action)"
				$WorkFlowObj.OOOTarget = "$($ExpandedAction.Target)"
				#if the action is a queue, expand it
				if ($ExpandedAction.Action -eq 'TransferToQueue')
				{
					$WorkFlowObj.OOOQueue = (Expand-UcmRgsQueue -RGSConfig $RGSConfig -QueueGUID $ExpandedAction.Target)
					$Workflowobj.OOOGroups = $WorkFlowObj.OOOQueue.Groups
					$Workflowobj.OOOUsers = $WorkFlowObj.OOOQueue.Users
					$Workflowobj.OOONumberRanges = $WorkflowObj.OOOQueue.groups.users.numberrange
					$Workflowobj.OOONumbers = $WorkflowObj.OOOQueue.groups.users.number
				}
			}
			'DefaultAction'
			{
				$ExpandedAction = (Expand-UcmRgsWorkflowAction -RgsActionNode $node -RGSConfig $RGSConfig)
				$WorkFlowObj.DefaultPlainText = "$($ExpandedAction.Text)"
				$WorkFlowObj.DefaultAction = "$($ExpandedAction.Action)"
				$WorkFlowObj.DefaultTarget = "$($ExpandedAction.Target)"
				#if the action is a queue, expand it
				if ($ExpandedAction.Action -eq 'TransferToQueue')
				{
					$WorkFlowObj.DefaultQueue = (Expand-UcmRgsQueue -RGSConfig $RGSConfig -QueueGUID $ExpandedAction.Target)
					$Workflowobj.DefaultGroups = $WorkFlowObj.DefaultQueue.Groups
					$Workflowobj.DefaultUsers = $WorkFlowObj.DefaultQueue.Users
					$Workflowobj.DefaultNumberRanges = $WorkflowObj.DefaultQueue.groups.users.numberrange
					$Workflowobj.DefaultNumbers = $WorkflowObj.DefaultQueue.groups.users.number
				}
}
		}

		if ($ExpandedAction.Status -eq 'Error')
		{
			Write-UcmLog -Message "Error expanding HolidayAction $($Node.props.s.'#text')" -Severity 3 -Component $function
			$WorkFlowObj.HolidayAction = "Error expanding HolidayAction $($Node.props.s.'#text')"
		}

	}


	Return $WorkFlowObj
}



Function Expand-UcmRgsQueue
{
	<#
		.SYNOPSIS
		Finds the details of the requested RGS Queue.

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
		[Parameter(Mandatory, Position = 1)] [hashtable]$RGSConfig,
		[Parameter(Mandatory, Position = 2)] [string]$QueueGUID
	)

	#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
	$function = 'Expand-UcmRgsQueue'
	[hashtable]$Return = @{}
	$return.Function = $function
	$return.Status = 'Unknown'
	$return.Message = 'Function did not return a status message'

	#skipping my function setup as it's expensive and this operation runs alot

	#endregion FunctionSetup

	#define the namespace for the XML and find the node we want
	$namespace = @{ ns = 'http://schemas.microsoft.com/powershell/2004/04' }
	$Queue = (Select-Xml -Content $rgsconfig.Queues.outerxml -XPath "//ns:Obj[ns:Props/ns:Obj/ns:Props/ns:G[@N='InstanceId'] = '$QueueGUID']" -Namespace $namespace)
	#Check we actually have the group and start filling the object
	if ($null -eq $Queue.node)
	{
		Write-UcmLog -Message "Queue $QueueGUID not found" -Severity 3 -Component $function
		$return.Status = 'Error'
		$return.Message = "Workflow $QueueGUID not found"
		Return $return
	}
	#Find the Queues details

	$QueueObj = [PSCustomObject]@{
		Name        = "Unknown"
		Description = "Unknown"
		Groups	    = @()
		OwnerPool	= "Unknown"
		TimeoutThreshold  = "Unknown"
		OverflowThreshold = "Unknown"
		OverflowCandidate = "Unknown"
		TimeoutAction    = "Unknown"
		TimeoutTarget   = "Unknown"
		OverflowAction  = "Unknown"
		OverflowTarget = "Unknown"
	}

	#Groups #$queue.node.props.obj[0].lst.obj.props.g."#text"

	Foreach ($node in $queue.node.props.s)
	{
		#Group Properties strings
		Switch ($node.n)
		{
			'Name'
			{
				$QueueObj.Name = $node.'#text'
			}
			'Description'
			{
				$QueueObj.Description = $node.'#text'
			}
			'OwnerPool'
			{
				$QueueObj.OwnerPool = $node.'#text'
			}
			'OverflowCandidate'
			{
				$QueueObj.OverflowCandidate = $node.'#text'
			}
			Default
			{
				Write-UcmLog -Message "Unknown Queue Property $($node.n)" -Severity 3 -Component $function
			}
		}
		#Group Properties numbers
		#Todo split this into a switch statement for timeout as well
		#$QueueObj.OverflowThreshold = $node.I16.'#text'
		#$QueueObj.TimeoutThreshold = $node.nil.'#text'
	}
	<# Foreach ($node in $queue.node.props.n)
	{
		#Group Properties Actions
		Switch ($node.obj.n)
		{
			'TimeoutAction'
			{
				#Not decoding at this point, not needed for deadline
				#$QueueObj.TimeoutAction = $node.props.s[0].'#text'
				#$QueueObj.TimeoutTarget = $node.props.s[1].'#text'
			}
			'OverflowAction'
			{
				#$QueueObj.OverflowAction = $node.props.s[0].'#text'
				#$QueueObj.OverflowTarget = $node.props.s[1].'#text'
			}
			'AgentGroupIDList'
			{
				#Do nothing, we will expand this later
			}
			'Identity'
			{
				#Do nothing, we already know this
			}
			Default
			{
				Write-UcmLog -Message "Unknown Queue Property $($node.obj)" -Severity 2 -Component $function
			}
		}

	}
	#>
		#now get the queue groups
		$Queues = $queue.node.props.obj.lst

		#Check to see if the Queue actually contains groups
		if ($null -eq $Queues)
		{
			Write-UcmLog -Message "Queue $($QueueObj.Name) has no Queues!" -Severity 2 -Component $function
			$GroupObj = [PSCustomObject]@{
				Name        = 'This Queue Contains No Groups'
				Description  = 'None'
				Users      = 'None'
			}
			$QueueObj.groups = $GroupObj
		}
		else
		{
			#Add the users numbers to the object
			#may need to pipeline this
			foreach ($queueguid in $queues.obj.props.g."#text")
			{
				$ExpandedGroup = (Expand-UcmRgsAgentGroup -groupGUID $queueguid -rgsconfig $RGSConfig -evusers $evusers)
				$QueueObj.Groups += $ExpandedGroup
			}
		}

		return $QueueObj

	
}

	Function Expand-UcmRgsAgentGroup
	{
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
			[Parameter(Mandatory, Position = 1)] [hashtable]$RGSConfig,
			[Parameter(Mandatory, Position = 2)] [string]$groupGUID,
			[Parameter(Mandatory, Position = 3)] [array]$evusers

		)

		#region FunctionSetup, Set Default Variables for HTML Reporting and Write Log
		$function = 'Expand-UcmRgsAgentGroup'
		[hashtable]$Return = @{}
		$return.Function = $function
		$return.Status = 'Unknown'
		$return.Message = 'Function did not return a status message'

		#skipping my function setup as it's expensive and this operation runs alot

		#endregion FunctionSetup

		#define the namespace for the XML and find the node we want
		$namespace = @{ ns = 'http://schemas.microsoft.com/powershell/2004/04' }
		$AgentgroupXml = (Select-Xml -Content $rgsconfig.agentgroups.outerxml -XPath "//ns:Obj[ns:Props/ns:Obj/ns:Props/ns:S[@N='NonNormalized'] = '$groupGUID']" -Namespace $namespace)

		#Check we actually have the group and start filling the object
		if ($null -eq $AgentgroupXml.node)
		{
			Write-UcmLog -Message "Agent Group $groupGUID not found" -Severity 3 -Component $function
			$return.Status = 'Error'
			$return.Message = "Agent Group $groupGUID not found"
			Return $return
		}


		$AgentGroupResults = @{}

		$AgentGroupObj = [PSCustomObject]@{
			Name        = "Unknown"
			Description = "Unknown"
			Users	    = $null
		}
		#Find the group name and description

		Foreach ($Prop in $AgentGroupXml.node.props.s)
		{
			Switch ($Prop.N)
			{
				'Name'
				{
					$AgentGroupObj.Name = $Prop.'#text'
				}
				'Description'
				{
					$AgentGroupObj.Description = $Prop.'#text'
				}
			}
		}

		#Get the users in the group
		$UsersXml = $AgentGroupXml.node.props.obj.lst.uri

		#Check to see if the group actually contains users
		if ($null -eq $UsersXml)
		{
			Write-UcmLog -Message "Agent Group $($AgentGroupObj.Name) has no users" -Severity 2 -Component $function
			$UserObj = [PSCustomObject]@{
				Name        = 'This Group Contains No Users'
				SipAddress  = 'None'
				Number      = 'None'
				NumberRange = 'None'
			}
			$AgentGroupObj.Users = $UserObj
		}
		else
		{
			#Add the users numbers to the object
			$AgentGroupObj.Users = (Expand-UcmRgsAgentNumber -Agentusers $UsersXml -evusers $evusers)
		}



		return $AgentGroupObj
	}


	Function Expand-UcmRgsAgentNumber
	{
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
			[Parameter(Mandatory, Position = 1)] $Agentusers,
			[Parameter(Mandatory, Position = 2)] $EvUsers
		)

		#skipping my function setup as it's expensive and this operation runs alot
		$GroupObj = @()
		foreach ($AgentUser in $AgentUsers)
		{
			#find the user and store it in a temp variable
			$Result = ($evusers | Where-Object SipAddress -EQ $AgentUser)
			#Get the number from the LineURI
			if ($null -eq $Result.LineUri)
			{
				$Number = 'No LineURI'
				$NumberRange = 'None'
				Write-UcmLog -Message "User $($Result.Name) has no phone number!" -Severity 2 -Component $function
			}
			else
			{
				$Number = $Result.LineUri.substring(4, $result.lineuri.length - 4)
				$NumberRange	= ($Number.substring(0, $Number.length - 2) + 'XX')
			}

			#Create a new object with the user details
			$UserObj = [PSCustomObject]@{
				Name        = $Result.Name
				SipAddress  = $Result.SipAddress
				Number      = $Number
				NumberRange = $NumberRange
			}
			#Return the object
			$GroupObj += $UserObj
		}
		Return $GroupObj
	}

