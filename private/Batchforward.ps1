﻿
. C:\UcMadScientist\PowerShell-Functions\private\New-CsFixedNumberDiversion.ps1
. C:\UcMadScientist\PowerShell-Functions\Test-ImportFunctions.ps1

cd "C:\Users\Atrei\OneDrive - Telstra Purple\Customers\AGL\Scripts"

$Data = Import-CSV ./forwards5.csv -ErrorAction Stop

$usercount = ($data.count)
$currentuser = 0

$data | New-UcmCsFixedNumberDiversion  -Domain aglenergy.onmicrosoft.com -LicenceType MCOPSTNEAU2 -Country AU -Verbose

<#
Foreach ($Forward in $data) { 

  $Usernametxt = $forward.originalNumber
  $currentuser ++
  Write-Progress -Activity "Step 1" -Status "User $currentuser of $usercount. $Usernametxt" -CurrentOperation start -PercentComplete ((($currentuser) / $usercount) * 100)
  New-UcmCsFixedNumberDiversion -OriginalNumber $forward.originalNumber -TargetNumber $forward.TargetNumber -Domain aglenergy.onmicrosoft.com -LicenceType MCOPSTNEAU2 -Country AU -Verbose
}
#>