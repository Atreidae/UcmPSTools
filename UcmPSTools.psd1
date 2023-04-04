@{
	RootModule        = 'UcmPSTools.psm1'
	ModuleVersion     = '<ModuleVersion>'
	GUID              = '2c5dafca-888a-44ff-b04e-938e0912d69a'
	Author            = 'James Arber'
	CompanyName       = 'UCMadScientist'
	Copyright		  = '(c) 2023 James Arber. All rights reserved.'
	Description 	  = 'A collection of PowerShell cmdlets for Microsoft Teams Voice Admins. If you work with Teams Voice, there will be something handy for you in here. Full documentation for every cmdlet is available using PowerShell help or https://docs.ucmadscientist.com See https://UcMadScientist.com or see https://github.com/Atreidae/UcmPSTools for development information'
	PowerShellVersion = '5.1'
	FunctionsToExport = @('<FunctionsToExport>')
	PrivateData = @{
        PSData = @{
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = @("Office365","Microsoft365","MicrosoftTeams","MicrosoftCalling","TeamsCalling")

			# A URL to the license for this module.
			LicenseUri = 'http://opensource.org/licenses/MIT'

			# A URL to the main website for this project.
			ProjectUri = 'https://github.com/Atreidae/UcmPSTools'

			#ReleaseNotes of this module
			ReleaseNotes = 'Automated build, see https://github.com/Atreidae/UcmPSTools for upto date notes'

			# A URL to an icon representing this module.
        	IconUri = 'https://www.ucmadscientist.com/UcmPsTools.png'

			#This gets replaced during the build with the relevant flag
            Prerelease = '<PreReleaseToken>'
        }
    }
}