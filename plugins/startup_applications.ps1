#requires -Version 1
$provides = 'startup_applications'
function Collect-Data 
{
    $output = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $startup_applications = New-Object -TypeName System.Collections.Specialized.OrderedDictionary

    $list_startup_applications  = Get-WmiObject -Class Win32_StartupCommand |
    Select-Object -Property Name, command, Location, User
    
    $output.Add('startup_applications',$list_startup_applications)
    $output
}
