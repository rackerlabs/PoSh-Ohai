#requires -Version 1
$provides = 'loggedon_users'

function Collect-Data 
{
    $output = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $loggedon_users = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $session_user = @{}

    $regex_antecedent = '.+Domain="(.+)",Name="(.+)"$'
    $regex_dependent = '.+LogonId="(\d+)"$'

    $logontype = @{
        '0' = 'Local System'
        '2' = 'Interactive'
        '3' = 'Network'
        '4' = 'Batch'
        '5' = 'Service'
        '7' = 'Unlock'
        '8' = 'NetworkCleartext'
        '9' = 'NewCredentials'
        '10' = 'RemoteInteractive'
        '11' = 'CachedInteractive'
    }

    $logon_sessions = Get-WmiObject -Class win32_logonsession -ComputerName $env:COMPUTERNAME | Select-Object -Property AuthenticationPackage, LogonId, LogonType, StartTime
    $logon_users = Get-WmiObject -Class win32_loggedonuser -ComputerName $env:COMPUTERNAME | Select-Object -Property Antecedent, Dependent

    $logon_users |ForEach-Object -Process {
        $_.antecedent -match $regex_antecedent > $null
        $username = $matches[1] + '\' + $matches[2]
        $_.dependent -match $regex_dependent > $null
        $session = $matches[1]
        $session_user[$session] += $username
    }

    $user = $logon_sessions | ForEach-Object -Process {
        $starttime = [management.managementdatetimeconverter]::todatetime($_.starttime)
        $loggedonuser = New-Object -TypeName psobject
        $loggedonuser | Add-Member -MemberType NoteProperty -Name 'Session' -Value $_.logonid
        $loggedonuser | Add-Member -MemberType NoteProperty -Name 'User' -Value $session_user[$_.logonid]
        $loggedonuser | Add-Member -MemberType NoteProperty -Name 'Type' -Value $logontype[$_.logontype.tostring()]
        $loggedonuser | Add-Member -MemberType NoteProperty -Name 'Auth' -Value $_.authenticationpackage
        $loggedonuser | Add-Member -MemberType NoteProperty -Name 'StartTime' -Value $starttime
        $loggedonuser
    }
    $output.Add('loggedon_users' ,$user)
    $output
}
