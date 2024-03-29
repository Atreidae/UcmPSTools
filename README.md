# UcmPSTools

## Installation notes

This module isnt on the PSGallery yet as I havent quite got the automation going.
To use the cmdlets, download this repo and dot source Test-ImportFunctions.PS1
It will load everything into your current PS session for use!

```PowerShell
. C:\UcMadScientist\PowerShell-Functions\Test-ImportFunctions.ps1 -Private
```

## Build Status

[![Build Status](https://dev.azure.com/UcMadScientist/UcmPSTools/_apis/build/status/Atreidae.UcmPSTools?branchName=main)](https://dev.azure.com/UcMadScientist/UcmPSTools/_build/latest?definitionId=1&branchName=main)

Note this failure is a known issue, it's caused by cryptominers abusing Azure Pipelines.
My "im not a bad repo" approval keeps popping off Azure. I've emailed the relevant team.

## Tests

## About UcmPSTools

 UcmPSTools is a collection of PowerShell functions to ease the administration of Microsoft Teams Unified Communications features and its related services.
 If you're a Teams Voice engineer or are transitioning from Skype for Business to Teams, you should find alot of these functions useful.

 This initially started out as a scratch pad for my commonly used UC related functions. I took it as an oppertunity to centralize alot of the code I use in my day to day work.
 Instead of just building things bespoke for me, I decided to clean all the functions up, heavily document them and release them on the PowerShell Gallery

 **Detailed posts for each function will come soon, but for now you can find inline PowerShell help and documentation to get you started.**

## Reporting Output

 Most of the functions in this module will return a PSCustomObject indicating the success or failure of each function and some descriptive text along with it.
 Detailed descriptions of each functions output can be found in the comment based help in each function.

 $Return.Status usually returns one of four values
 "OK"      : The operation was sucsessful, nothing of concern
 "Warn"    : The operation was sucsessful, but there is something you should be mindful of (We are trying to create a user that already exists, or we are running low on licences to assign). More information will be found in $Return.Message
 "Error"   : The operation was unsucsessful, Something happend when attempting to perform the operation that we couldnt handle, check $Return.Message for more information
 "Unknown" : Cmdlet reached the end of the fucntion without returning anything, this shouldnt happen, if it does please log an issue on Github with your relevant log files.

 $Return.Message returns descriptive text showing the connected tenant, mainly for logging, reporting or diagnosis.

 If the function you are calling is working with multiple objects, then an array will be returned with multiple objects idenified by their unique attribute, such as SIP Address.
 (presently, no function does this, but I am planning on multiple object support for many cmdlets. See the private for more.)

## Security Information

As this module frequently runs automated automations, it has been designed to hold on to creds and tokens as long as it can. 
As such great care should be taken to ensure that the scripts are unmodified before using them. Either download this directly from my GitHub Repo <https://github.com/atreidae/ucmpstools> or from the PowerShell Gallery ##todo## License

### A Note on Creds.xml

The creds.xml file may be generated by any of the New-*Connection cmdlets and allows for autoreconnection should a session drop mid user migration
This file is encrypted with a per user encryption key provided by Windows.
These files are not portable and cannot be moved from one machine to another, or one user profile to another.

Whilst a Creds.xml is encrypted. It should be looked after like a certificate, should your user profile be compromised it is possible for someone to write a script and execute it in your profile to retrieve the stored credentials.

## List of Functions (Public)

### Office365 Connection Related

Functions for checking and connecting to relevant Office365 services

Note for all these functions, any of the "New-*" cmdlets will check for the Global variable $Config then look in the local folder for creds.xml before prompting the user for credentials.
If the account used doesnt use MFA, then the credentials will be stored to facilitate batch operations.
The specific variables used are
$Global:Config.SignInAddress
$Global:Config.Password
$Global:Config.Override (Override URL for nonstandard usernames)

#### New-MSOLConnection

Clears any existing MSOL Connections and connects to MSOL, if user credentials arent presently stored in memory, the function checks for a creds.xml file in the local folder and loads it into memory.
Should the Creds.xml not be found, it will prompt the user to provide credentials and write a new creds.xml in the current folder.

#### New-SFBOConnection

Clears any existing MSOL Connections and connects to MSOL, if user creds arent in memory, the function checks for a creds.xml file in the local folder and loads it into memory.
Should the Creds.xml not be found, it will prompt the user to provide credentials and write a new creds.xml in the current folder.

#### New-EXHOConnection

Note: this function presently uses the old community Exchange module. I am in the process of re-writing it to support the Exchange Online 2.0 module

Grabs stored creds and creates a new Exchange Online session

This function is designed to auto reconnect to Exchange Online during batch migrations and the like.
At present, it does not support modern auth. (I havent intergrated it yet)

#### Test-MSOLConnection

This function will test if the current PowerShell Session is connected to Office 365 Azure AD (Using Azure AD v1) and that the PSSession isnt broken
If its not connected for any reason, it will return an error unless the `-reconnect` flag is specified, causing it to call New-MSOLConnection to attempt to reconnect instead

#### Test-SFBOConnection

This function will test if the current PowerShell Session is connected to Skype for Business Online via either the Skype4B module or the MicrosoftTeams module and that the PSSession isnt broken
If its not connected for any reason, it will return an error unless the `-reconnect` flag is specified, causing it to call New-SFBOConnection to attempt to reconnect instead

#### Test-EXHOConnection

This function will test if the current PowerShell Session is connected to Exchange Online and that the PSSession isnt broken
If its not connected for any reason, it will return an error unless the `-reconnect` flag is specified, causing it to call New-EXHOConnection to attempt to reconnect instead

### Office365 User Management Related

Functions for creating, licencing and enabling users

#### Grant-UcmOffice365UserLicence

Function to check for and apply approproate licences to users
Specify the UPN, Licence Code and Country Code and it will set all accordingly.
It will also check for licences before applying them and return a warning when less than 5% or 5 licences are available.

```PowerShell
PS> Grant-UcmOffice365UserLicence -upn 'button.mash@contoso.com' -LicenceType 'MCOEV' -Country 'AU'
```

Grants the Microsoft Phone System Licence to the user Button Mash

```PowerShell
PS> Grant-UcmOffice365UserLicence -upn 'button.mash@contoso.com' -LicenceType 'MCOPSTNEAU2' -Country 'AU'
```

Grants the Telstra Calling for Office 365 Licence (Australia only)

#### Enable-UcmO365Service

Function for checking and enabling Office 365 Service Plans (Apps in the O365 GUI)
This is great for those enviroments where the admins have turned off Skype/Teams

```PowerShell
PS> Enable-UcmO365Service -User 'button.mash@Contoso.com' -ServiceName 'MCOSTANDARD'
```

Enables Skype for Business Online for the user Button Mash (Required to move the user to Teams)
Users must already have the appropriate licence for the service plan to be enabled.

```PowerShell
PS> Enable-UcmO365Service -User 'button.mash@Contoso.com' -ServiceName 'MCOPSTNEAU'
```

Enables the Telstra Calling for Office365 Service Plan

#### New-UcmOffice365User

Checks for and creates a new blank Office 365 user
Handy for some situations where you need to create a user account for things that cant be sorted by a resource account.

```PowerShell
PS> New-Office365User -UPN button.mash@contoso.com -Password "Passw0rd1!" -FirstName Caleb -LastName Sills -Country AU -DisplayName "Button Mash"
```

### On-Prem Management related

#### Find-UcmSuppliedUserDetails

This function is great for converting lists of users supplied by customers into AD objects to pass to Cmdlets like Move-CsUser
First it will search UserPrincipalNames that match the supplied username, if no match is found, it will then move on to checking using SamAccountName
Failing that, we will prompt the user to provide an updated username, or return an error to the calling function

#### Import-UcmCsOnPremTools

Function to check for and import both Skype4B and AD Management tools

```PowerShell
PS> Import-UcmCsOnPremTools
```

Checks for and loads the approprate modules for Skype4B and Active Directory
Will throw an error and abort script if they arent found

### Call Management Related

Functions related to the creation and management of Call Queues, Auto Attendants, Holidays etc.

#### New-UcmCsFixedNumberDiversion

Diverts a number associated with Microsoft Teams Via Microsoft Calling plans or Telstra Calling to an external PSTN number by performing the following actions

* Creates a Resource Account with named "PSTN_FWD_<inboundNumber>@domain.onmicrosoft.com" by default (Configurable using -AccountPrefix)
* Licences the account with a Virtual Phone System Licence
* Licences the account with an appropriate calling licence (Will attempt to locate a calling licence using Locate-CsCallingLicence)
* Creates an AutoAttendant with a 24 hour schedule
* Configures a forward rule in the AutoAttendant

Note: All accounts will be "Cloud born" and use your tenants onmicrosoft domain as syncing accounts is a PITA
Warning: The script presently only supports Cloud Numbers, attempting to use Direct Routing numbers will fail.

```PowerShell
PS> New-CsFixedNumberDiversion -OriginalNumber +61370105550 -TargetNumber +61755501234
```

Enables Microsoft Teams for the user Button Mash

```PowerShell
PS> New-CsFixedNumberDiversion -UPN 'button.mash@contoso.com' -ServiceName 'MCOPSTNEAU'
```

This cmdlet also supports pipline input so you can pass a whole bunch of numbers using multiple objects on the pipeline

```PowerShell
$data | New-UcmCsFixedNumberDiversion  -Domain contoso.onmicrosoft.com -LicenceType MCOPSTNEAU2 -Country AU -Verbose
```

Will create a forward for each of the numbers in the $data object using their OriginalNumber and TargetNumber properties

Known Issue: There is currently a delay with Office365 replication where the object may not be licenced in time before attempting to assign a line uri. I'm working on a fix for this
Rerunning the cmdlet should fix this, it will check for any existing objects before creating new ones.

### PSTN Number Management Related

Functions relating to the assignment, management and checking of PSTN Numbers.

#### Todo 3

### Reporting related

Functions for logging and creation of reports to automated proceedures.

UcmPsTools includes a set of functions specifically designed to process the return results of each of the cmdlets to create a report of multiple objects.
To create a report, first call Initialize-UcmReport with the title and start time of the report. This will load 2 Global Variables and automatically start the first report line item

`$Global:ProgressReport = @()` This stores the entire report.
`$Global:ThisReport = @()` This stores the object we are currently processing.

Now that we have a blank report loaded, we can start adding steps.

Call `New-UCMReportItem` to start a new line item and perform your first action on the user/object. Then using the results call `New-UcmReportStep` with the name of the action and the result. This will be added to the report as part of the current line item. Continue calling `New-UcmReportStep` for each action on that particular user/object.
Once you have completed all the actions on that user/object, call `New-UCMReportItem` to move to a new line item. Continue this process until you have completed all users. Then call `Complete-UcmReport` to insert the last object into the report and clean up the progress variables.

Once the report has been completed, you can export it to either HTML or CSV file (or both!) with 'Export-UcmHTMLReport' and 'Export-UcmCSVReport' respectivley
Exporting to HTML will by default open the HTML report once complete.

Here is a quick example.
In this example, we will assign a Microsoft Phone System Licence, Enable the Teams Service plan and move on to the next user

```PowerShell
#Start a new Report
Initialize-UcmReport -Title "User Preperation"
Foreach ($username in $users) 
{ 
    #Define a new line item because we are starting a new user
    New-UCMReportItem -LineTitle "Username" -LineMessage "$username"

    #Assign Enterprise Voice Licence
    $step = (Grant-UcmOffice365UserLicence -upn $user.upn -LicenceType 'MCOEV' -Country 'AU')

    #Add results of action to report
    New-UcmReportStep -Stepname "EV Licence" -StepResult "$($Step.status) $($step.message)"

    #Assign Telstra Calling Licence
    $step = (Grant-UcmOffice365UserLicence -upn $user.upn -LicenceType 'MCOPSTNEAU2' -Country 'AU')

    #Add results of action to report
    New-UcmReportStep -Stepname "TCO Licence" -StepResult "$($Step.status) $($step.message)"

    #Enable Teams Service Plan
    $step = (Enable-UcmO365Service -upn $user.upn -ServiceName TEAMS1)

    #Add results of action to report
    New-UcmReportStep -Stepname "Teams Service Plan" -StepResult "$($Step.status) $($step.message)"
}

#All uses completed, Close the report
Complete-UcmReport

#Export the report as a HTML file and a CSV to the current folder
Export-UcmHTMLReport
Export-UcmCSVReport

```

#### Initialize-UcmReport

Creates a new Report Global varable for logging status

#### New-UCMReportItem

Creates a new Report line item (for example a user)

#### New-UcmReportStep

Creates a new Step for the current line item (for example, assigning a licence to a user)

#### Complete-UcmReport

Adds the last line item to the report and cleans up the step variables

#### Export-UcmHTMLReport

By default, exports the current open report as a HTML in the current folder with the filename "$Title - $StartDate.html"
You can change the path by editing $Global:HTMLReportFilename just before calling this function

#### Export-UcmCSVReport

Exports the current open report as a HTML in the current folder with the filename "$Title - $StartDate.csv"
You can change the path by editing $Global:CSVReportFilename just before calling this function

#### Write-UcmLog

This function is used by almost every single function in UcmPsTools, it creates logfiles based on the attributes its passed at runtime.
By default, it looks for the varable $Script:LogFileLocation each time its executed and appends the log message to the file in that path.
if the file doesnt exist, it will be created and if the fix is larger than 10MB. it will be rotated.

(Note, the LogFileLocation variable is a script scope, so scripts can override globals!)

When calling Write-Log the severity level will also determine what if any on screen output there is. You can use the `-LogOnly` flag to prevent any screen output, however I'd encourage you to use a severity level of 1 instead.

Severity 1: Write log message to "Write-Verbose"
Severity 2: Prepend log message with "Info:" and send to "Write-host" with a ForegroundColor of Green
Severity 3: Write log message to "Write-Warning"
Severity 4: Write log message to "Write-Error"
Severity 5: Write log message to "Write-Error", this may in future also "Throw" but is currently disabled.

## List of Functions (Private)

This section covers functions that havent made it to the public folder yet, the documentation may be incorrect, incomplete or just may not exist.
Use at your own risk

### Beta Functions

#### New-UcmTeamsCommonAreaPhone

This function is for creating batches of Teams Common Area Phones. It presently creates a cloud account, licences them, assigns a phone number, voice policy, voice routing policy and dial plan
it's presently only tested with Direct Routing and I plan to re-write it to support better pipelining.

#### Create-OnPremAdAccount

Quickly bashed together function to create on prem accounts, used for creating objects for direct routing AutoAttendants

### Development functions

#### Initialize-CsAutoAttendants and Invoke-CsAutoAttendant (Broken)

Development code for initialising auto-attendants

#### New-CsFixedNumberDiversion-pipelinework (Broken)

Multi input variant of New-CsFixedNumberDiversion, presently broken

### Find-UcmCsLineUri (broken)

Copy of an old line URI finder I wrote based of some of Tom ARbuthnots code.
Needs to be updated for Teams

### Invoke-UcmBatchSfb2TeamsMove (Broken)

Development for moving users from Onprem Skype for Business to Microsoft Teams

## Developing for this module

Everything from this point down is just for those looking to get into the nitty gritty of the code, and isnt required to use the module.

If you intend to use the functions in this GitRepo seperate from the PowerShell functions I should explain a few of the caveats
A handy tip for anyone working on this, or trying to use it seperate from the published module is the "Test-ImportFunctions.ps1" script.
This script will attempt to load all the functions found in the public folder into your current PowerShell session. Simply "Dot Source" it to make all the functions available outside of the script scope.

```PowerShell
. C:\UcMadScientist\PowerShell-Functions\Test-ImportFunctions.ps1
```

You can also add the "private" flag to the script to import any functions in the private folder.

```PowerShell
. C:\UcMadScientist\PowerShell-Functions\Test-ImportFunctions.ps1 -Private
```

## Folder structure

### public

This is where most of the functions reside, each function or closely related functions (the reporting ones for example) reside in their own PS1 file to simplify change management as well as reducing testing effort during changes.

Any PS1 files in this folder require associated pester tests and will be signed with my certificate. before being packaged up into the module and shipped to the PowerShell Gallery. Understandably, I take commits to this folder quite seriously before they make it into the main branch.

### build_scripts

This folder contains code that will be executed by my Azure Pipeline instance.
It's responsible for running Pester Tests, Signing the functions, and packaging the module.

Thanks to Adam the Automater for these wicked pipeline tools
Check out <https://adamtheautomator.com/powershell-devops/> for more info!
Plus Nicola Suter's guide to signing PowerShell scripts using Aure Pipelines <https://tech.nicolonsky.ch/sign-powershell-az-devops/>
and COLIN DEMBOVSKY's guide to Azure Pipeline Variables <https://colinsalmcorner.com/azure-pipeline-variables/>

### private

Functions, scripts or modules included in the private folder will not be signed or tested by Pester.
This is where I usually put functions I'm working on or testing, so may not work at all.
These functions will **not** be included in the automatically generated PowerShell module for publishing to the PowerShell Gallery.
