#Migrate-SkypeUsersToTeamsPrep

##Set variables

$Folder = "C:\UcMadScientist\" #Folder containing migration batches?
$File = "C:\UcMadScientist\UserMigration.csv" #File we are working with?

##log file location (Used by UcmPsTools Cmdlets!)
$LogFileLocation =  $PSCommandPath -replace '.ps1','.log' #Where do we store the log files? (In the same folder by default)

##import files
cd $Folder
$users = Import-CSV $File -ErrorAction Stop 

## Use UcmPsTools to start a report for our actions
  Initialize-UcmReport -Title "Step 1" -Subtitle "Licence and Service Plan Validation/Assignment"

  
## Use UcmPsTools to check we are connected to MSOL and reconnect if possible. If not, throw an error
  $return = (Test-UcmMSOLConnection)
  if ($return.status -eq "Error")
  {
   Write-UcmLog -message "We arent connected to MSOL Service. Please run Connect-MsolService and try again" -Severity 3
   Return
  }

  #Process Each User
Foreach ($username in $users) 
  { 
  
    ## Use UcmPsTools to add a new user to the report.
    New-UCMReportItem -LineTitle "Username" -LineMessage "$username"

    ## Use UcmPsTools to check the user for Licences, and add them if required

        #Use UcmPsTools to check/add Enterprise Voice (MCOEV) Licence to the user
        $step = (Grant-UcmOffice365UserLicence -upn $user.upn -LicenceType 'MCOEV' -Country 'AU')

        #Use UcmPsTools to store the results of the above check against the user in the report
        New-UcmReportStep -Stepname "EV Licence" -StepResult "$($Step.status) $($step.message)" 

        #Use UcmPsTools to check/add Telstra Calling (MCOPSTNEAU2) Licence to the user
        $step = (Grant-UcmOffice365UserLicence -upn $user.upn -LicenceType 'MCOPSTNEAU2' -Country 'AU')

        #Use UcmPsTools to store the results of the above check against the user in the report
        New-UcmReportStep -Stepname "TCO Licence" -StepResult "$($Step.status) $($step.message)"
    
  
    ## Use UcmPsTools to check the users Service Plans and enable them if required

        #Use UcmPsTools to check the Teams Service Plan
        $step = (Enable-UcmO365Service -upn $user.upn -ServiceName TEAMS1)
        #Use UcmPsTools to store the results of the above check against the user in the report
        New-UcmReportStep -Stepname "Teams Service Plan" -StepResult "$($Step.status) $($step.message)"

        #Use UcmPsTools to check the Skype for Business Online Service Plan (Required to Migrate User from OnPrem to Online
        $step = (Enable-UcmO365Service -upn $user.upn -ServiceName MCOSTANDARD)
        #Use UcmPsTools to store the results of the above check against the user in the report
        New-UcmReportStep -Stepname "SFBO Service Plan" -StepResult "$($Step.status) $($step.message)"

        #Use UcmPsTools to check the Telstra Calling Service Plan
        $step = (Enable-UcmO365Service -upn $user.upn -ServiceName MCOPSTNEAU)
        #Use UcmPsTools to store the results of the above check against the user in the report
        New-UcmReportStep -Stepname "TCO Service Plan" -StepResult "$($Step.status) $($step.message)"
        
  } #Repeat for the next user


  #All users are complete, tell UcmPsTools the Report is finished
  New-UCMReportItem -LineTitle "Username" -LineMessage "Complete"

  #Export the Report into HTML and CSV format
  Export-UcmHTMLReport | out-null
  Export-UcmCSVReport | out-null

