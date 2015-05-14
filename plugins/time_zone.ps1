#requires -Version 1
$provides = 'time_zone'

function Collect-Data 
{
    $output = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    
    $timezone = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $timezone = Get-WmiObject -Class Win32_TimeZone
    $output.Add('time_zone',$timezone.caption)
    $output
}
