#requires -Version 1
$provides = 'users'

function Collect-Data 
{
    $output = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $users = New-Object -TypeName System.Collections.Specialized.OrderedDictionary

    $list_users = (Get-WmiObject -Class Win32_UserAccount) | Select-Object -Property Status, Caption, PasswordExpires, AccountType, Description, Disabled, Domain, FullName, InstallDate, LocalAccount, Lockout, Name, PasswordChangeable, PasswordRequired, SID, SIDType, Site, Container

    $output.Add('users',$list_users)
    $output
}
