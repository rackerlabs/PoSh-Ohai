#requires -Version 1
$provides = 'services'

function Collect-Data 
{
    $output = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $services = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $list_services = Get-WmiObject -Class Win32_Service | Select-Object -Property Name, ProcessId, State, StartMode, Status

    $output.Add('services' , $list_services)
    $output
}
