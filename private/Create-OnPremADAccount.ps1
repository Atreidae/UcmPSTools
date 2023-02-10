
#Very yuck code

function Create-OnPremADAccount
{
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope='Function')] #Todo https://github.com/Atreidae/UcmPSTools/issues/24

#Import-Csv "C:\kloud\mel-ad-caps-miss.csv" | ForEach-Object{
$upn = $_.SamAccountName + "skype4badmin.local"
Write-host "Creating user $Upn"
Write-Host "$_"
New-ADUser -Name $_.Name `
 -GivenName $_.GivenName `
 -Surname $_.Surname `
 -SamAccountName  $_.samAccountName `
 -UserPrincipalName $upn `
 -Path $_.Path `
 -PasswordNeverExpires $True `
 -CannotChangePassword $true `
 -AccountPassword (ConvertTo-SecureString "boop" -AsPlainText -force) -Enabled $true
#}

}


