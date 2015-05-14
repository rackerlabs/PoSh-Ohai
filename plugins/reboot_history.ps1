#requires -Version 2
$provides = 'reboot_history'

function Collect-Data 
{
    $output = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $reboot_history = New-Object -TypeName System.Collections.Specialized.OrderedDictionary

    $event_1074 = Get-WinEvent -FilterHashtable @{
        logname = 'System'
        id      = 1074
    }  |
    ForEach-Object -Process {
        $rv = New-Object -TypeName PSObject |
        Select-Object -Property Date, User, Action, Process, Reason, ReasonCode, Comment
        $rv.Date = $_.TimeCreated
        $rv.User = $_.Properties[6].Value
        $rv.Process = $_.Properties[0].Value
        $rv.Action = $_.Properties[4].Value
        $rv.Reason = $_.Properties[2].Value
        $rv.ReasonCode = $_.Properties[3].Value
        $rv.Comment = $_.Properties[5].Value
        $rv
    } |
    Select-Object -Property Date, Action, Reason, User
    
    $output.Add('reboot_history' , $event_1074)
    $output
}
