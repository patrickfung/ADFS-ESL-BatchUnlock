##Function 1 - Export AD Users from your Domain Controller##

#AD Users

#Import AD Module for Powershell
import-module ActiveDirectory

#Go to the Work Directory
cd C:\Temp

$users = Get-ADUser -SearchBase "OU=Tree,OU=Forest,DC=Earth" -filter {userAccountControl -eq "512"} | Select-Object -Property userprincipalname

$users | export-csv -NoTypeInformation C:\Temp\users.csv

(gc users.csv) | ? {$_.Trim() -ne ""} | Set-Content AD-ESL-usercheck.csv


##Function 2 - Perform Batch Unlock and Reproting on ADFS for Extranet Smart Lockout (ESL)##

$Sourcefile = "C:\Temp\AD-ESL-usercheck.csv"
$Exportfile = "C:\Temp\report.html"

$users = import-csv $Sourcefile
$export_users = @()


#######Get Activity Report#######
foreach ($user in $users)
{
    try {
        # Get ADFS activity
        $activity = Get-AdfsAccountActivity -Identity $user.userprincipalname
        if ($activity.UnknownLockout -eq $true -or $activity.FamiliarLockout -eq $true) {

            $export_user = New-Object PSObject -Property @{
                Username         = $activity.identifier
                UnknownLockout   = $activity.UnknownLockout
                FamiliarLockout  = $activity.FamiliarLockout
            }

            $export_users += $export_user
        
        # Reset Action for Familiar
           Reset-AdfsAccountLockout -Identity $user.userprincipalname -Location Familiar
           sleep 1
        # Reset Action for Unknown
           Reset-AdfsAccountLockout -Identity $user.userprincipalname -Location Unknown
           sleep 1
        }
    } catch {
        # Catch condition when user is not in ADFS database.
    }
}

# Export users to HTML file
$export_users | ConvertTo-Html | out-file $Exportfile
